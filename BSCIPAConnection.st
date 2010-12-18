"
 (C) 2010 by Holger Hans Peter Freyther
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
    | bsc handlers mutex |
    <comment: 'I handle SCCP for the MSC/BSC connection'>

    BSCSCCPHandler class >> initWith: aBSC [
        ^ self new
            instVarNamed: #bsc put: aBSC;
            instVarNamed: #mutex put: Semaphore forMutualExclusion;
            yourself
    ]

    handle: aConnection [
        | start proc removed |
        "Maybe I got this wrong but we have to be very careful to get
        this process started and registered."

        removed := false.
        start := Semaphore new.

        proc := [
            "Wait for the process to be registered"
            start wait.
            [[
                "Do the work here"
                self logNotice: 'Processing for new SCCP connection %1.' % {aConnection srcRef} area: #bsc.
                (Delay forSeconds: 3) wait.
            ] on: BSCTerminated do: [Processor activeProcess terminate.]
            ] ensure: [
                "Make sure to terminate"
                aConnection release.

                mutex critical: [
                    removed := true.
                    self handlers remove: Processor activeProcess ifAbsent: [].
                    self logNotice: 'Removed process for SCCP connection %1.'
                         % {aConnection srcRef} area: #bsc.
                ].
            ]
        ] fork.

        mutex critical: [
            removed ifFalse: [
                self handlers add: proc.
                start signal.
            ]
        ]
    ]

    newConnection: aConnection [
        self logNotice: 'New incoming SCCP connection %1 on the BSC %2'
             % {aConnection srcRef. bsc lac} area: #bsc.

        self handle: aConnection.
    ]

    handlers [ <category: 'handler'> ^ handlers ifNil: [handlers := OrderedCollection new]]

    terminate [
        | copy |
        <category: 'cleanup'>

        copy := mutex critical: [self handlers copy].
        copy do: [:each |
            self logNotice: 'Terminating process %1' % {each} area: #bsc.
            each queueInterrupt: [BSCTerminated new signal].
        ].

        "Now all connections should slowly terminate and the resources be freed"
    ]
]

Object subclass: BSCIPAConnection [
    | socket config demuxer writeQueue muxer dispatcher sccp tx terminated |
    <comment: 'I represent one Connection to a BSC and use the IPA
     protocol to exchange messages. I will be executed from within
     a thread and can do a blocking read from in here.'>

    BSCIPAConnection class >> createOn: aSocket withConfig: aConfig [
        ^ (self new)
            socket: aSocket;
            instVarNamed: #config put: aConfig;
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

        sccp := BSCSCCPHandler initWith: self.
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
        sccp terminate.
        self class terminate: tx.
    ]
]
