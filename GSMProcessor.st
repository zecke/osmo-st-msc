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

OsmoGSM.BSSAPMessage extend [
    dispatchTrans: aCon [
        aCon bssapUnknownData: self
    ]
]

OsmoGSM.BSSAPManagement extend [
    dispatchTrans: aCon [
        self dispatchMAP: aCon.
    ]

    dispatchMAP: aCon [
        (Dictionary from: {
            OsmoGSM.GSM0808Helper msgComplL3   -> #mapLayer3:.
            OsmoGSM.GSM0808Helper msgClearReq  -> #mapClearReq:.
            OsmoGSM.GSM0808Helper msgClearComp -> #mapClearCompl:.
            OsmoGSM.GSM0808Helper msgCipherModeCmpl -> #mapCipherModeCompl:.
            OsmoGSM.GSM0808Helper msgAssComplete -> #mapAssComplete:.
            }) at: self data type ifPresent: [:sel |
            ^ aCon perform: sel with: self.
        ].

        ^ aCon mapUnknown: self.
    ]
]

OsmoGSM.BSSAPDTAP extend [
    dispatchTrans: aCon [
        aCon dispatchDTAP: self.
    ]
]

Object subclass: GSMTransaction [
    | sapi ti con |
    <comment: 'I am the base for everything that goes on in a
GSM transaction on a given SAPI'>

    GSMTransaction class >> on: sapi with: ti [
        <category: 'creation'>
        ^ self new
            instVarNamed: #sapi put: sapi;
            instVarNamed: #ti put: ti;
            initialize;
            yourself
    ]

    con: aCon [
        <category: 'creation'>
        con := aCon.
    ]

    cancel [
    ]

    dispatch: aMsg [
        self subclassResponsibility
    ]

    nextPutSapi: aMsg [
        <category: 'output'>
        ^ self nextPut: (OsmoGSM.BSSAPDTAP initWith: aMsg linkIdentifier: sapi)
    ]

    nextPut: aMsg [
        <category: 'output'>
        con nextPutData: aMsg
    ]

    logUnknown: aMsg [
        <category: 'logging'>
        self logError: 'Unknown message %1' % {aMsg class}.
    ]
]

GSMTransaction subclass: GSMLURequest [
    <comment: 'I handle a Location Updating Request'>
]

OsmoGSM.SCCPConnectionBase subclass: GSMProcessor [
    | transactions |

    <comment: 'I am driving a SCCP Connection. This consists of being
hosting various transactions and dispatching to them.'>
    <import: OsmoGSM>

    initialize [
        transactions := OrderedCollection new.
        ^ super initialize.
    ]

    data: aData [
        | msg bssmap data |

        "The first message should be a Complete Layer3 Information"
        aData data dispatchTrans: self.

        (GSMMOCall on: 0 with: 0)
            con: self;
            initial.
    ]

    bssapUnknownData: aData [
        <category: 'private'>
        "This is now the GSM data"
        self conManager critical: [self release].
    ]

    mapLayer3: aData [
        <category: 'BSSMAP'>
        'MAP Layer3' printNl.
    ]

    mapClearReq: aData [
        <category: 'BSSMAP'>
        'CLEAR Request' printNl.
    ]

    mapClearCompl: aData [
        <category: 'BSSMAP'>
        'CLEAR COMPL' printNl.
    ]

    mapCipherModeCompl: aData [
        <category: 'BSSMAP'>
        'CIPHER MODE COMPL' printNl.
    ]

    mapAssComplete: aData [
        <category: 'BSSMAP'>
        'ASSIGNMENT COMPL' printNl.
    ]

    terminate [
        <category: 'private'>
        "Cancel all transactions"
        transactions do: [:each |
            each cancel]
    ]
]
