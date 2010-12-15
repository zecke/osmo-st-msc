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

Object subclass: BSCIPAConnection [
    | socket config demuxer writeQueue muxer dispatcher |
    <comment: 'I represent one Connection to a BSC and use the IPA
     protocol to exchange messages. I will be executed from within
     a thread and can do a blocking read from in here.'>

    BSCIPAConnection class >> createOn: aSocket withConfig: aConfig [
        ^ (self new)
            socket: aSocket;
            instVarNamed: #config put: aConfig;
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

    terminateAll [
        "Bring down everything that happens for this BSC. This is a reset"
        self logNotice: 'BSC lac: %1 terminating.' % {config lac} area: #bsc.
    ]
]
