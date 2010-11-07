PackageLoader fileInPackage: 'OsmoNetwork'.


Object subclass: IPAConnection [
    | socket demuxer writeQueue muxer dispatcher |
    <comment: 'I represent one Connection to a BSC. I have virtual
connections hanging off my tree and I will destroy them when my connection
is going away.'>

    IPAConnection class >> createOn: aSocket [
        ^ (self new)
            socket: aSocket;
            yourself
    ]

    socket: aSocket [
        socket := aSocket.
        writeQueue := SharedQueue new.

        demuxer := Osmo.IPADemuxer initOn: socket.
        muxer := Osmo.IPAMuxer initOn: writeQueue.

        dispatcher := Osmo.IPADispatcher new.
        dispatcher initialize.
    ]

    process [
        "Drive the BSC process. This will send/queue messages"
        socket logNotice: 'closing down' area: #bsc.
        socket close.
    ]
]
