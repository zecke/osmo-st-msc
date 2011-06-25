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
            OsmoGSM.GSM0808Helper msgAssFailure -> #mapAssFailure:.
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

    assignmentFailure [
        "The audio assignment has failed."
    ]

    assignmentSuccess [
        "The assignment succeeded and there is now a specific channel"
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
    | transactions state endp connId |

    <comment: 'I am driving a SCCP Connection. This consists of being
hosting various transactions and dispatching to them.'>
    <import: OsmoGSM>

    GSMProcessor class >> stateInitial [<category: 'states'> ^ 0 ]
    GSMProcessor class >> stateAcked   [<category: 'states'> ^ 1 ]
    GSMProcessor class >> stateRelease [<category: 'states'> ^ 2 ]
    GSMProcessor class >> stateError   [<category: 'states'> ^ 3 ]

    GSMProcessor class >> createAssignment: aMul timeslot: aTs [
        | ass |
        <category: 'audio-connect'>
        ass := IEMessage initWith: GSM0808Helper msgAssRequest.
        ass
            addIe: ((GSM0808ChannelTypeIE
                    initWith: GSM0808ChannelTypeIE speechSpeech
                    audio: GSM0808ChannelTypeIE speechSpeech)
                        audioCodecs: {GSM0808ChannelTypeIE speechFullRateVersion3.
                                      GSM0808ChannelTypeIE speechHalfRateVersion3};
                        yourself);
            addIe: (GSM0808CICIE initWithMultiplex: aMul timeslot: aTs).
        ^ ass
    ]

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
            self releaseAudio.
            self release.
        ].
    ]

    mapCipherModeCompl: aData [
        <category: 'BSSMAP'>
        'CIPHER MODE COMPL' printNl.
        aData inspect.
    ]

    terminate [
        <category: 'private'>
        "Cancel all transactions"
        sem critical: [
            transactions do: [:each |
                [each cancel] on: Error do: [:e |
                    e logException: 'GSMProc(srcref:%1) failed cancel: %2' %
                        {self srcRef. each class} area: #bsc.
                ]
            ].

            transactions := OrderedCollection new.
            self releaseAudio.
        ].
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

    "Audio handling"
    allocateEndpoint [
        <category: 'audio'>
        "The endpoint allocation is a complicated and async process. It
         starts with picking a timeslot to the BSC, it continues with trying
         to assign the timeslot via MGCP, then will send the ASSIGNMENT
         COMMAND. This means even with multiple phone calls there will be
         only one assigned timeslot.

         To make things more complicated we might have a CRCX or such
         pending while we need to tear things down. This means we will
         need to check in the transaction complete/timeout what we need to
         do next and also keep a list of transactions."


         "Right now only one call is allowed. we have no support of switching
          calls during the call."

        self trunk critical: [
            endp ifNotNil: [
                self logError: 'GSMProc(srcref:%1) already has endpoint.'
                        % {self srcRef} area: #bsc.
                ^ nil].

            endp := self trunk allocateEndpointIfFailure: [
                self logError: 'GSMProc(srcref:%1) no endpoint availabble.'
                        % {self srcRef} area: #bsc.
                ^ nil].

            self sendAssignment.
        ].
    ]

    generateCallId [
        <category: 'audio'>
        "I can be up to 32 chars of hexdigits. No need to be globally unique"
        ^ (Random between: 10000000 and: 999999999) asString
    ]

    trunk [
        <category: 'audio'>
        ^ conManager bsc trunk.
    ]

    callAgent [
        <category: 'audio'>
        ^ conManager msc mgcpCallAgent
    ]

    releaseAudio [
        "I try to release things right now."
        <category: 'audio'>
        self trunk critical: [
            endp ifNil: [^self].
            endp isUnused ifTrue: [^self].

            "Check if we have ever send a CRCX, if not release it"
            endp isReserved ifTrue: [
                endp callId isNil
                    ifTrue:  [
                        self logDebug:
                            'GSMProc(srcref:%1) MGCP CRCX never sent.'
                                % {self srcRef} area: #bsc.
                        endp used. endp free]
                    ifFalse: [
                        self logDebug:
                            'GSMProc(srcref:%1) MGCP pending CallID:%2. no release.'
                                % {self srcRef. endp callId} area: #bsc.].
                ^ self
            ].

            (endp isUsed and: [endp callId isNil not]) ifTrue: [
                self sendDLCX.
            ].
        ].
    ]

    sendAssignment [
        | ass |
        <category: 'audio-connect'>

        "TODO: Maybe start a timer but we are guarded here anyway."
        ass := self class createAssignment: endp multiplex timeslot: endp timeslot.
        self nextPutData: (BSSAPManagement initWith: ass).
    ]

    mapAssComplete: aData [
        <category: 'audio-connect'>

        sem critical: [self trunk critical: [
            endp callId isNil ifTrue: [self sendCRCX].
        ]].
    ]

    mapAssFailure: aData [
        <category: 'audio-connect'>
        sem critical: [self trunk critical: [
            self logError: 'GSMProc(srcref:%1) GSM0808 Assignment failed.'
                    % {self srcRef} area: #bsc.
            self assignmentFailure.]]
    ]

    assignmentSuccess [
        <category: 'audio-connect'>

        transactions do: [:each |
            each assignmentSuccess.
        ]
    ]

    assignmentFailure [
        <category: 'audio-connect'>
        "Tell the transactions that there will be no audio."

        transactions do: [:each |
            each assignmentFailure.
        ]
    ]

    takeLocks: aBlock [
        <category: 'audio-locking'>
        "Take the locks in lock-order for audio callbacks"
        conManager critical: [
            sem critical: [
                self trunk critical: [
                    aBlock value]]]
    ]

    sendCRCX [
        | trans crcx |
        <category: 'audio-connect'>
        endp callId: self generateCallId.
        trans := Osmo.MGCPTransaction on: endp of: self callAgent.
        crcx := (Osmo.MGCPCRCXCommand createCRCX: endp callId: endp callId)
                    parameterAdd: 'M: recvonly';
                    yourself.
        trans command: crcx.
        trans onResult: [:endp :result |
            self takeLocks: [self crcxResult: result]].
        trans onTimeout: [:endp |
            self takeLocks: [self crcxTimeout]].
        trans start.

        self logDebug: 'GSMProc(srcref:%1) CRCX on %2 with CallID: %3'
                % {self srcRef. endp endpointName. endp callId} area: #bsc.
    ]

    crcxResult: aResult [
        <category: 'audio-connect'>

        "save the sdp and callId"
        endp used.

        "Did this succeed?"
        aResult isSuccess ifFalse: [
            self logError: 'GSMProc(srcref:%1) CRCX failed aCode: %2'
                    % {self srcRef. aResult code} area: #bsc.
            self freeEndpoint.
            self assignmentFailure.
            ^ self
        ].

        "Check if there is a connId"
        connId := aResult parameterAt: 'I' ifAbsent: [
            self logError: 'GSMProc(srcref:%1) CRCX lacks connId'
                    % {self srcRef} area: #bsc.
            self freeEndpoint.
            self assignmentFailure.
            ^ self
        ].

        "Check what to do next"
        state = self class stateAcked
            ifTrue:  [
                self logDebug: 'GSMProc(srcref:%1) CRCX compl(%2) Code: %3.'
                        % {self srcRef. endp callId. aResult code} area: #bsc.
                self assignmentSuccess.
            ]
            ifFalse: [
                self logDebug: 'GSMProc(srcref:%1) CRCX compl(%2), call gone.'
                        % {self srcRef. endp callId} area: #bsc.
                self releaseAudio.
            ].
    ]

    crcxTimeout [
        <category: 'audio-connect'>

        self logDebug: 'GSMProc(srcref:%1) CRCX timeout on %2 with CallID: %3.'
                % {self srcRef. endp endpointName. endp callId} area: #bsc.

        "Free the endpoint"
        endp used.
        self freeEndpoint.

        "tell transactions. in case we get this late then there are no
         transactions left and this is a no-op."
        self assignmentFailure.
    ]

    freeEndpoint [
        <category: 'audio-release'>

        endp free.
        endp := nil.
        connId := nil.
    ]

    sendDLCX [
        | trans dlcx |
        <category: 'audio-release'>
        "I sent the DLCX, I also make the endpoint forget the callid. As this
         is our indicator that things have been cleared or will be cleared."

        trans := Osmo.MGCPTransaction on: endp of: self callAgent.
        dlcx := Osmo.MGCPDLCXCommand createDLCX: endp callId: endp callId.
        endp clearCallId.
        connId isNil ifFalse: [dlcx parameterAdd: 'I: %1' % {connId}].
        trans command: dlcx.
        trans onResult: [:endp :result |
            self takeLocks: [self dlcxResult: result]].
        trans onTimeout: [:endp |
            self takeLocks: [self dlcxTimeout]].
        trans start.
    ]

    dlcxResult: aResult [
        <category: 'audio-release'>


        aResult isSuccess
            ifTrue: [
                self logError: 'GSMProc(srcref:%1) DLCX succeeded on endp(%2).'
                    % {self srcRef. endp endpointName} area: #bsc.
                self freeEndpoint.]
            ifFalse: [
                self logError: 'GSMProc(srcref:%1) DLCX failed on endp(%2).'
                    % {self srcRef. endp endpointName} area: #bsc.].
    ]

    dlcxTimeout [
        <category: 'audio-release'>

        self logError: 'GSMProc(srcref:%1) DLCX timedout Endp(%2) stays blocked.'
                % {self srcRef. endp endpointName} area: #bsc.
        endp := nil.
        connId := nil.
    ]
]
