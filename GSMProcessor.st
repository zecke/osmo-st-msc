"
 (C) 2010-2011 by Holger Hans Peter Freyther
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

PackageLoader fileInPackage: 'OsmoGSM'.

Object subclass: GSMTransaction [
    | sapi ti |
    <comment: 'I am the base for everything that goes on in a
GSM transaction on a given SAPI'>

    GSMTransaction class >> on: sapi with: ti [
        <category: 'creation'>
        ^ self new
            instVarNamed: #sapi put: sapi;
            instVarNamed: #ti put: ti;
            yourself
    ]

    cancel [
    ]
]

GSMTransaction subclass: GSMLURequest [
    <comment: 'I handle a Location Updating Request'>
]

OsmoGSM.SCCPConnectionBase subclass: GSMProcessor [
    | transactions |

    <comment: 'I am driving one subscriber connection'>
    <import: OsmoGSM>

    data: aData [
        | msg bssmap data |

        "The first message should be a Complete Layer3 Information"
        msg := aData data.

        msg class msgType = BSSAPHelper msgManagemnt ifFalse: [
            ^ self logError: 'Wrong initial message on %1' % {self srcRef} area: #msc.
        ].

        bssmap := msg data.
        bssmap type = GSM0808Helper msgComplL3 ifFalse: [
            ^ self logError: 'Should be complete layer3 on %1' % {self srcRef} area: #msc.
        ].

        bssmap findIE: GSMCellIdentifier elementId ifAbsent: [
            ^ self logError: 'CellIdentifier not present on %1' % {self srcRef} area: #msc.
        ].
        data := bssmap findIE: GSMLayer3Info elementId ifAbsent: [
            ^ self logError: 'Layer3Infor not present on %1' % {self srcRef} area: #msc.
        ].

        "This is now the GSM data"
    ]

    terminate [
        "Cancel all transactions"
        transactions do: [:each |
            each cancel]
    ]
]
