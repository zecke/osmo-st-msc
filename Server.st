PackageLoader fileInPackage: 'OsmoNetwork'.
PackageLoader fileInPackage: 'OsmoLogging'.

Object subclass: IPAConnection [
    | socket bsc rx tx |
    <comment: 'I represent one Connection to a BSC. I have virtual
connections hanging off my tree and I will destroy them when my connection
is going away.'>

    IPAConnection class >> createOn: aSocket [
        
    ]
]


Object subclass: IPAServer [
    | socket addr port |

    IPAServer class >> listenOn: anAddr port: aPort [
        ^ (self new)
            addr: anAddr port: aPort.
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
	[true] whileTrue: [ | con |
            socket waitForConnection.

            con := socket accept.
            con logNotice: 'New BSC connection' area: #bsc.
            con close.

        ]
    ]
]
