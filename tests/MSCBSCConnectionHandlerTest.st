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

TestCase subclass: MSCBSCConnectionHandlerTest [
    <category: 'OsmoMSC-Tests'>
    <comment: 'I should test the feature that each config can only
    be connected once but that is not done yet. It requires some work
    on socket code. TODO!!!'>

    testOnlyOnce [
"
        | msc socket bsc |
        msc := MSCApplication new.
        msc bscConfig addBSC: '127.0.0.1' withName: 'foo' andLac: 4711.
        bsc := msc bscConfig bscList first.

        socket := DummySocket new.
        socket instVarNamed: #peer put: bsc peer.
        socket instVarNamed: #closed put: false.
"
    ]
]
