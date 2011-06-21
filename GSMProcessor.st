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

OsmoGSM.GSM48MSG extend [
    openTransactionOn: aCon sapi: aSapi [
        self logError: 'Can not open transaction for %1' % {self class} area: #bsc.
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

    sapi [
        <category: 'accessing'>
        ^ sapi
    ]

    ti [
        "TODO: This should somehow include the size of the allocation"
        <category: 'accessing'>
        ^ ti
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
    | transactions state |

    <comment: 'I am driving a SCCP Connection. This consists of being
hosting various transactions and dispatching to them.'>
    <import: OsmoGSM>

    GSMProcessor class >> stateInitial [<category: 'states'> ^ 0 ]
    GSMProcessor class >> stateAcked   [<category: 'states'> ^ 1 ]
    GSMProcessor class >> stateRelease [<category: 'states'> ^ 2 ]
    GSMProcessor class >> stateError   [<category: 'states'> ^ 3 ]

    initialize [
        <category: 'creation'>
        transactions := OrderedCollection new.
        state := self class stateInitial.
        ^ super initialize.
    ]

    data: aData [
        | msg bssmap data |
        <category: 'input'>

        "The first message should be a Complete Layer3 Information"
        [
            aData data dispatchTrans: self.
        ] on: Error do: [:e |
            e logException: 'Failed to dispatch: %1' % {e tag} area: #bsc.
            self forceClose.
        ]
    ]

    bssapUnknownData: aData [
        <category: 'BSSMAP'>
        "This is now the GSM data"
        self forceClose.
    ]

    mapLayer3: bssap [
        | layer3 |
        <category: 'BSSMAP'>

        "Check and move state"
        'Dispatching GSM' printNl.
        sem critical: [
            self verifyState: [state = self class stateInitial].
            state := self class stateAcked.
        ].

        "TODO: Add verifications"
        bssap data findIE: OsmoGSM.GSMCellIdentifier elementId ifAbsent: [
            ^ self logError: 'CellIdentifier not present on %1' % {self srcRef} area: #msc.
        ].

        layer3 := bssap data findIE: OsmoGSM.GSMLayer3Info elementId ifAbsent: [
            ^ self logError: 'Layer3Infor not present on %1' % {self srcRef} area: #msc.
        ].

        'Dispatching GSM' printNl.
        sem critical: [self dispatchGSM: layer3 data sapi: 0].
    ]

    mapClearReq: aData [
        <category: 'BSSMAP'>
        'CLEAR Request' printNl.

        sem critical: [
            self verifyState:
                [(state > self class stateInitial) and: [state < self class stateError]].
            self clearCommand: 0.
        ]
    ]

    mapClearCompl: aData [
        <category: 'BSSMAP'>
        sem critical: [
            self verifyState: [state = self class stateRelease].
            self release.
        ].
    ]

    mapCipherModeCompl: aData [
        <category: 'BSSMAP'>
        'CIPHER MODE COMPL' printNl.
        aData inspect.
    ]

    mapAssComplete: aData [
        <category: 'BSSMAP'>
        'ASSIGNMENT COMPL' printNl.
        aData inspect.
    ]

    terminate [
        <category: 'private'>
        "Cancel all transactions"
        sem critical: [
            transactions do: [:each |
                each cancel]
        ]
    ]

    verifyState: aBlock [
        <category: 'private'>
        "Must be locked."

        aBlock value ifFalse: [
            self logError: 'GSMProc(srcref:%1) wrong state: %2.' % {self srcRef. state} area: #bsc.
            ^ self error: 'Failed to verify the state.'.
        ].
    ]

    forceClose [
        <category: 'private'>
        sem critical: [
            state = self class stateError ifTrue: [
                "Already closing down"
                ^ false
            ].

            state := self class stateError.
            self release
        ].
    ]

    clearCommand: aCause [
        | msg |
        <category: 'private'>
        "Must be locked"

        "Already clearing it once"
        state >= self class stateRelease ifTrue: [
            ^ true.
        ].

        state := self class stateRelease.

        msg := OsmoGSM.IEMessage initWith: OsmoGSM.GSM0808Helper msgClear.
        msg addIe: (OsmoGSM.GSMCauseIE initWith: aCause).
        self nextPutData: (OsmoGSM.BSSAPManagement initWith: msg).
    ]

    checkRelease [
        "Check if things can be released now"
        <category: 'private'>
        "Must be locked"

        "No more transactions, clean things up"
        transactions isEmpty ifTrue: [
            self clearCommand: 9.
        ].
    ]

    addTransaction: aTran [
        <category: 'private'>
        "Must be locked"
        self logDebug: 'GSMProc(srcref:%1) adding transaction %2' % {self srcRef. aTran class} area: #bsc.
        transactions add: aTran.
    ]

    removeTransaction: aTran [
        <category: 'private'>
        "Must be locked"
        self logDebug: 'GSMProc(srcref:%1) removing transaction %2' % {self srcRef. aTran class} area: #bsc.
        transactions remove: aTran ifAbsent: [
            self logError: 'GSMProc(srcref:%1) trans not found %2' % {self srcRef. aTran class} area: #bsc.
        ].

        self checkRelease.
    ]

    dispatchGSM: aMsg sapi: aSapi [
        <category: 'private'>
        "Must be locked"
        aMsg inspect.

        "Find an active transaction for this"
        transactions do: [:each |
            (each sapi = aSapi and: [each ti = aMsg ti]) ifTrue: [
                each dispatch: aMsg.
                self checkRelease.
                ^ true.
            ].
        ].

        aMsg openTransactionOn: self sapi: 0.
        self checkRelease.
    ]
]
