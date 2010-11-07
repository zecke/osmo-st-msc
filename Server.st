PackageLoader fileInPackage: 'OsmoNetwork'.
PackageLoader fileInPackage: 'OsmoLogging'.

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


Object subclass: IPAServer [
    | socket addr port |

    IPAServer class >> listenOn: anAddr port: aPort [
        ^ (self new)
            addr: anAddr port: aPort;
            listen;
            yourself
    ]

    addr: anAddr port: aPort [
        <category: 'configure'>
        addr := anAddr.
        port := aPort.
    ]

    listen [
        socket := Sockets.ServerSocket
                    port: port
                    bindTo: (Sockets.SocketAddress byName: addr).
    ]

    serve [
	[true] whileTrue: [ | ipa |
            socket waitForConnection.

            ipa := IPAConnection createOn: socket accept.
            ipa logNotice: 'New BSC connection' area: #bsc.
            [ipa process] fork.
        ]
    ]
]
