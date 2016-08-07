"
 (C) 2010-2013 by Holger Hans Peter Freyther
 All Rights Reserved

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
"

PackageLoader
    fileInPackage: 'OsmoCore';
    fileInPackage: 'OsmoMGCP';
    fileInPackage: 'OsmoNetwork'.

Osmo.IPAProtoHandler subclass: BSCIPAProtoHandler [
    | bsc |
    <category: 'OsmoMSC-BSC'>

    BSCIPAProtoHandler class >> initWith: aBSC [
        <category: 'creation'>
        ^ self new
            instVarNamed: #bsc put: aBSC;
            yourself
    ]

    handlePong: aMsg [
        <category: 'pong'>
        bsc receivedPong.
    ]
]

Object subclass: BSCConnection [
    | config msc trunk |

    <category: 'OsmoMSC-BSC'>

    BSCConnection class >> createOn: aConfig msc: aMsc [
        <category: 'creation'>
        ^ self basicNew
            instVarNamed: #config put: aConfig;
            instVarNamed: #msc put: aMsc;
            initialize;
            yourself
    ]

    initialize [
        <category: 'creation'>
        "I try to initialize the trunk to the remote BSC. Right now I force
        the usage of UDP."
        trunk := Osmo.MGCPDSTrunk createWithDest: config peer printString trunkNr: 1.
        (trunk endpointAt: 1) tryBlock.

        "Osmo Extension"
        config sendOsmoRSIP ifTrue: [self sendOsmoRSIP].
    ]

    config [
        <category: 'accessing'>
        ^ config
    ]

    msc [
        <category: 'accessing'>
        ^ msc
    ]

    trunk [
        <category: 'accessing'>
        ^ trunk
    ]

    sendOsmoRSIP [
        <category: 'osmo-extensions'>

        "Send the RSIP in a fire and forget style."
        (Osmo.MGCPTransaction on: (trunk endpointAt: 2) of: msc mgcpCallAgent)
          command: Osmo.MGCPOsmoRSIPCommand createRSIP;
          startSingleShot.
    ]

    sendUdt: aMsg [
        | udt addr |
        addr := Osmo.SCCPAddress createWith: 254.
        udt := Osmo.SCCPUDT initWith: addr calling: addr data: aMsg.
        ^ self send: udt toMessage with:Osmo.IPAConstants protocolSCCP.
    ]
]

BSCConnection subclass: BSCIPAConnection [
    | socket demuxer writeQueue muxer dispatcher sccp tx terminated
      ipa ping_timeout pong_timeout |

    <category: 'OsmoMSC-BSC'>
    <comment: 'I represent one Connection to a BSC and use the IPA
     protocol to exchange messages. I will be executed from within
     a thread and can do a blocking read from in here.'>

    BSCIPAConnection class >> createOn: aSocket withConfig: aConfig msc: aMsc [
        ^ (self createOn: aConfig msc: aMsc)
            socket: aSocket;
            yourself
    ]

    BSCIPAConnection class >> terminate: aProc [
        "Make sure it is dead!"
        aProc ifNil: [^true].

        [aProc isTerminated] whileFalse: [aProc terminate].
    ]

    lac [ ^ config lac ]

    socket: aSocket [
        socket := aSocket.
        writeQueue := SharedQueue new.

        demuxer := Osmo.IPADemuxer initOn: socket.
        muxer := Osmo.IPAMuxer initOn: writeQueue.

        dispatcher := Osmo.IPADispatcher new.

        ipa := BSCIPAProtoHandler initWith: self.
        ipa registerOn: dispatcher.
        ipa muxer: muxer.
        ipa token: 'abc'.

        sccp := BSCSCCPHandler initWith: self msc: msc.
        sccp registerOn: dispatcher.
        sccp connection: self.

        "Drain the send queue in a new process"
        tx := [
            Processor activeProcess name: 'BTS TX queue(%1)' % {self lac}.

            self sendPing.
            [
            [
                self runTxQueueOnce
            ] repeat.
            ] ensure: [
                self logNotice: 'BSC TX queue lac: %1 finished' % {self lac} area: #bsc]
        ] fork.

    ]

    runTxQueueOnce [
        | msg |
        <category: 'private'>

        msg := writeQueue next.
        socket nextPutAllFlush: msg.
    ]

    send: aMsg with: aType [
        terminated = true ifTrue: [^false].

        muxer nextPut: aMsg with: aType.
    ]

    process [
        "Drive the BSC process. This will send/queue messages"

        socket logNotice: 'Processing for lac %1' % {self lac} area: #bsc.

        self send: {Osmo.IPAConstants msgIdAck} asByteArray with: Osmo.IPAConstants protocolIPA.

        [
            self processOne.
        ] repeat.


        socket close.
    ]

    processOne [
        | msg |
        msg := demuxer next.
        OsmoDispatcher dispatchBlock: [dispatcher dispatch: msg first with: msg second.]
    ]

    terminateAll [
        "Bring down everything that happens for this BSC. This is a reset"
        terminated := true.
        self logNotice: 'BSC lac: %1 terminating.' % {self lac} area: #bsc.
        pong_timeout isNil ifFalse: [pong_timeout cancel].
        self class terminate: tx.
        OsmoDispatcher dispatchBlock: [sccp linkSetFailed].
    ]

    sendPing [
        <category: 'ping-pong'>
        "I send a ping and start a timer..."
        self
            send: (ByteArray with: Osmo.IPAConstants msgPing)
            with: Osmo.IPAConstants protocolIPA.
        self logDebug: 'BSC lac: %1 sent ping waiting now.' % {self lac} area: #bsc.

        pong_timeout := (Osmo.TimerScheduler instance)
            scheduleInSeconds: 5 block: [
                self logNotice: 'BSC lac: %1 ping timeout.' % {self lac} area: #bsc.
                socket close].
    ]

    receivedPong [
        <category: 'ping-pong'>
        terminated = true ifTrue: [^false].

        pong_timeout cancel.
        self logDebug: 'BSC lac: %1 ponged.' % {self lac} area: #bsc.
        ping_timeout := (Osmo.TimerScheduler instance)
            scheduleInSeconds: 30 block: [
                self sendPing].
    ]
]
