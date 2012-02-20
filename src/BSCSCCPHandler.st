"
 (C) 2010-2012 by Holger Hans Peter Freyther
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

PackageLoader
    fileInPackage: 'OsmoGSM'.

OsmoGSM.SCCPHandler subclass: BSCSCCPHandler [
    | bsc msc |

    <category: 'OsmoMSC-BSC'>
    <comment: 'I handle SCCP for the MSC/BSC connection'>

    BSCSCCPHandler class >> initWith: aBSC msc: aMSC [
        ^ self new
            instVarNamed: #bsc put: aBSC;
            instVarNamed: #msc put: aMSC;
            yourself
    ]

    connectionSpecies [
        ^ GSMProcessor
    ]

    bsc [
        <category: 'accessing'>
        ^ bsc
    ]

    msc [
        <category: 'accessing'>
        ^ msc
    ]

    handleMsg: aMsg [
        ^ super handleMsg: aMsg.
    ]

    handleUDT: aMsg [
        "I need to handle a reset and such"
        ^ super handleUDT: aMsg.
    ]

    newConnection: aConnection [
        self logNotice: 'New incoming SCCP connection %1 on the BSC %2'
             % {aConnection srcRef. bsc lac} area: #bsc.
        ^ super newConnection: aConnection.
    ]
]

