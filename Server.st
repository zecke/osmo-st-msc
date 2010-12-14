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
