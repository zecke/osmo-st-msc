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

PackageLoader fileInPackage: 'OsmoNetwork'.

Exception subclass: BSCTerminated [
    <comment: 'I am a signal that the BSC Connection terminated and
    resources needs to be freed now.'>
]

OsmoGSM.SCCPHandler subclass: BSCSCCPHandler [
    | bsc msc |
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

    msc [
        ^ msc
    ]

    newConnection: aConnection [
        self logNotice: 'New incoming SCCP connection %1 on the BSC %2'
             % {aConnection srcRef. bsc lac} area: #bsc.
        ^ super newConnection: aConnection.
    ]
]

Object subclass: BSCIPAConnection [
    | socket config demuxer writeQueue muxer dispatcher sccp tx terminated msc ipa |
    <comment: 'I represent one Connection to a BSC and use the IPA
     protocol to exchange messages. I will be executed from within
     a thread and can do a blocking read from in here.'>

    BSCIPAConnection class >> createOn: aSocket withConfig: aConfig msc: aMsc [
        ^ (self new)
            socket: aSocket;
            instVarNamed: #config put: aConfig;
            instVarNamed: #msc put: aMsc;
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

        [
            | msg |
            msg := demuxer next.
            dispatcher dispatch: msg first with: msg second.
        ] repeat.


        socket close.
    ]

    terminateAll [
        "Bring down everything that happens for this BSC. This is a reset"
        terminated := true.
        self logNotice: 'BSC lac: %1 terminating.' % {self lac} area: #bsc.
        self class terminate: tx.
        sccp linkSetFailed.
    ]
]
