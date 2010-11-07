PackageLoader fileInPackage: 'OsmoNetwork'.


Object subclass: IPAConnection [
    | socket bsc rx tx |
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
    ]

    process [
        "Drive the BSC process. This will send/queue messages"
        socket logNotice: 'closing down' area: #bsc.
        socket close.
    ]
]
