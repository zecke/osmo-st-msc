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

PackageLoader fileInPackage: 'Sockets'.

Object subclass: BSCListener [
    | ip port socket handler |

    <category: 'OsmoMSC-BSC'>
    <comment: 'I listen for incoming BSC connections and will
    authenticate them based on a definable criteria. Right now
    this is based on IP address'>

    BSCListener class >> initWith: bscIP port: bscPort handler: aHandler [
        ^ self new
            initSocket: bscIP port: bscPort;
            handler: aHandler;
            start;
            yourself
    ]

    handler: aHandler [
        handler := aHandler.
    ]

    initSocket: anIP port: aPort [
        ip := anIP.
        port := aPort.
    ]

    serve [
	[socket isOpen] whileTrue: [
            self handleOneConnection.
        ].

        ^ false
    ]

    handleOneConnection [
        [ | con |
            socket waitForConnection.
            con := socket accept.
            con ifNil: [
                self logNotice: 'BSC-Socket: Connection failed. Will return.' area: #bsc.
                ^ false
            ].

            handler isNil
                ifTrue: [
                    self logNotice: 'BSC-Socket: Closing connection due lack of handler.' area: #bsc.
                    con close]
                ifFalse:[handler newConnection: con].
        ] on: SystemExceptions.FileError do: [:each |
            self logNotice: 'BSC-Socket: FileError on connection handling.' area: #bsc.
            ^ false.
        ].
    ]

    start [
        [
            socket := Sockets.ServerSocket
                port: port bindTo: (Sockets.SocketAddress byName: ip).
        ] on: SystemExceptions.FileError do: [:e |
            e logException: 'BSC-Socket: Failed to bind.' area: #bsc.
        ]
    ]

    stop [
        "The serve function will now get a FileError"
        self logNotice: 'BSC-Socket: Asked to close the connection.' area: #bsc.
        socket close.
    ]
]
