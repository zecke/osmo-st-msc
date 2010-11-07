PackageLoader fileInPackage: 'OsmoNetwork'.
PackageLoader fileInPackage: 'OsmoLogging'.

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
