"
 (C) 2010-2011 by Holger Hans Peter Freyther
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
    fileInPackage: 'OsmoMGCP';
    fileInPackage: 'OsmoNetwork'.

OsmoGSM.SCCPHandler subclass: BSCSCCPHandler [
    | bsc msc |

    <category: 'OsmoMSC-BSC'>
    <comment: 'I handle SCCP for the MSC/BSC connection'>

    BSCSCCPHandler class >> initWith: aBSC msc: aMSC [
        ^ self new
            instVarNamed: #bsc put: aBSC;
            instVarNamed: #msc put: aMSC;
            yourself
    ]

    connectionSpecies [
        ^ GSMProcessor
    ]

    bsc [
        <category: 'accessing'>
        ^ bsc
    ]

    msc [
        <category: 'accessing'>
        ^ msc
    ]

    handleMsg: aMsg [
        ^ super handleMsg: aMsg.
    ]

    newConnection: aConnection [
        self logNotice: 'New incoming SCCP connection %1 on the BSC %2'
             % {aConnection srcRef. bsc lac} area: #bsc.
        ^ super newConnection: aConnection.
    ]
]

Object subclass: BSCConnection [
    | config msc trunk |

    <category: 'OsmoMSC-BSC'>

    BSCConnection class >> createOn: aConfig msc: aMsc [
        <category: 'creation'>
        ^ self new
            instVarNamed: #config put: aConfig;
            instVarNamed: #msc put: aMsc;
            initialize;
            yourself
    ]

    initialize [
        <category: 'creation'>
        "I try to initialize the trunk. Right now I force the usage
        of UDP to the given port and do not support the nat traversal. I
        also hardcode the kind of audio."
        trunk := Osmo.MGCPDSTrunk createWithDest: config peer printString trunkNr: 1.
        (trunk endpointAt: 1) tryBlock.
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
]

BSCConnection subclass: BSCIPAConnection [
    | socket demuxer writeQueue muxer dispatcher sccp tx terminated ipa |

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
        dispatcher initialize.

        ipa := Osmo.IPAProtoHandler new.
        ipa registerOn: dispatcher.
        ipa muxer: muxer.
        ipa token: 'abc'.

        sccp := BSCSCCPHandler initWith: self msc: msc.
        sccp registerOn: dispatcher.
        sccp connection: self.

        "Drain the send queue in a new process"
        tx := [
            [[
                | msg |
                msg := writeQueue next.
                socket nextPutAllFlush: msg.
            ] repeat.
            ] ensure: [
                self logNotice: 'BSC TX queue lac: %1 finished' % {self lac} area: #bsc]
        ] fork.

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
        self class terminate: tx.
        OsmoDispatcher dispatchBlock: [sccp linkSetFailed].
    ]
]
