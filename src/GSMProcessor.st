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

PackageLoader fileInPackage: 'OsmoGSM'.

OsmoGSM.BSSAPMessage extend [
    dispatchTrans: aCon [
        <category: '*-OsmoMSC-GSM'>
        aCon bssapUnknownData: self
    ]
]

OsmoGSM.BSSAPManagement extend [
    dispatchTrans: aCon [
        <category: '*-OsmoMSC-GSM'>
        self dispatchMAP: aCon.
    ]

    dispatchMAP: aCon [
        <category: '*-OsmoMSC-GSM'>
        (Dictionary from: {
            OsmoGSM.GSM0808Helper msgComplL3   -> #mapLayer3:.
            OsmoGSM.GSM0808Helper msgClearReq  -> #mapClearReq:.
            OsmoGSM.GSM0808Helper msgClearComp -> #mapClearCompl:.
            OsmoGSM.GSM0808Helper msgCipherModeCmpl -> #mapCipherModeCompl:.
            OsmoGSM.GSM0808Helper msgAssComplete -> #mapAssComplete:.
            OsmoGSM.GSM0808Helper msgAssFailure -> #mapAssFailure:.
            OsmoGSM.GSM0808Helper msgCMUpdate -> #mapCMUpdate:.
            }) at: self data type ifPresent: [:sel |
            ^ aCon perform: sel with: self.
        ].

        ^ aCon mapUnknown: self.
    ]
]

OsmoGSM.BSSAPDTAP extend [
    dispatchTrans: aCon [
        <category: '*-OsmoMSC-GSM'>
        aCon dispatchDTAP: self.
    ]
]

OsmoGSM.GSM48MSG extend [
    openTransactionOn: aCon sapi: aSapi [
        <category: '*-OsmoMSC-GSM'>
        self logError: 'Can not open transaction for %1' % {self class} area: #bsc.
    ]
]

Object subclass: GSMTransaction [
    | sapi ti con |

    <category: 'OsmoMSC-GSM'>
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

    canHandle: aMsg sapi: aSapi [
        ^ self sapi = aSapi and: [self ti = aMsg ti].
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

    con [
        <category: 'creation'>
        ^ con
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

OsmoGSM.SCCPConnectionBase subclass: GSMProcessor [
    | transactions state endp connId mgcp_trans auth pending info |

    <category: 'OsmoMSC-GSM'>
    <comment: 'I am driving a SCCP Connection. This consists of being
hosting various transactions and dispatching to them.'>
    <import: OsmoGSM>

    GSMProcessor class >> stateInitial [<category: 'states'> ^ 0 ]
    GSMProcessor class >> stateAcked   [<category: 'states'> ^ 1 ]
    GSMProcessor class >> stateAuth    [<category: 'states'> ^ 2 ]
    GSMProcessor class >> stateRelease [<category: 'states'> ^ 3 ]
    GSMProcessor class >> stateError   [<category: 'states'> ^ 4 ]

    GSMProcessor class >> authenticator [
        <category: 'authenticator'>
        ^ GSMIdentityAuthenticator
    ]

    GSMProcessor class >> createAssignment: aMul timeslot: aTs [
        | ass |
        <category: 'audio-connect'>
        ass := IEMessage initWith: GSM0808Helper msgAssRequest.
        ass
            addIe: ((GSM0808ChannelTypeIE
                    initWith: GSM0808ChannelTypeIE speechSpeech
                    audio: GSM0808ChannelTypeIE chanSpeechFullPref)
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
        info := Dictionary new.
        ^ super initialize.
    ]

    addInfo: aKey value: aValue [
        <category: 'misc'>
        "Store additional info about this call here."
        info at: aKey put: aValue.
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
            self
                verifyState: [state = self class stateRelease];
                releaseAudio;
                releaseAuth;
                release.
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
            self
                releaseAudio;
                releaseAuth.
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

    openTransaction: aTran with: aMsg [
        <category: 'transaction'>
        self addTransaction: aTran.

        "The authentication has happend, just start the transaction."
        state = self class stateAuth ifTrue: [
            ^ aTran start: aMsg
        ].

        "An authentication is pending."
        auth isNil ifFalse: [
            self logNotice: 'GSMProc(srcref:%1) auth pending.'
                    % {self srcRef} area: #bsc.
            pending add: (aTran -> aMsg).
            ^ true.
        ].

        "Remember to launch this transaction"
        pending := OrderedCollection new
            add: (aTran -> aMsg);
            yourself.

        auth := self class authenticator new
            connection: self;
            onAccept: [:auth | self authenticationAccepted];
            onReject: [:auth | self authenticationRejected];
            yourself.
        auth start: aMsg.
    ]

    addTransaction: aTran [
        <category: 'private'>
        "Must be locked"
        self logDebug: 'GSMProc(srcref:%1) adding transaction %2'
                % {self srcRef. aTran class} area: #bsc.
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

    dispatchDTAP: aMsg [
        <category: 'private'>
        sem critical: [self dispatchGSM: aMsg data sapi: aMsg sapi]
    ]

    dispatchGSM: aMsg sapi: aSapi [
        <category: 'private'>
        "Must be locked"

        "Pass everything to the authenticator if present."
        auth isNil ifFalse: [
            ^ auth onData: aMsg.
        ].

        "Find an active transaction for this. TODO: For CM Service Request
        we need to hand everything there. With multiple transactions we
        should have a ranking. E.g. with bi-directional SMS this needs to be
        handled specially. We need the existing transaction to take preference."
        transactions do: [:each |
            (each canHandle: aMsg sapi: aSapi) ifTrue: [
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

    selectAudioRouteForEmergency: aLeg [
        <category: 'call'>
        ^ conManager msc
            selectAudioRouteForEmergency: self leg: aLeg.
    ]

    selectAudioRoute: aPlan leg: aLeg [
        <category: 'call'>
        ^ conManager msc
            selectAudioRoute: self plan: aPlan leg: aLeg
    ]

    releaseAuth [
        <category: 'auth'>
        auth isNil
            ifTrue: [^true].

        "Give up on the authentication."
        auth cancel.
        auth := nil.
    ]

    releaseAudio [
        "I try to release things right now."
        <category: 'audio'>
        self trunk critical: [
            endp ifNil: [^self].
            endp isUnused ifTrue: [^self].

            "Check if we have ever sent a CRCX, if not release it"
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
        ass := self class createAssignment: endp multiplex timeslot: endp timeslot - 1.
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

    mapCMUpdate: aData [
        <category: 'map-classmark'>
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

    mgcpQueueTrans: aTrans [
        <category: 'audio-connect'>
        mgcp_trans add: aTrans.
        mgcp_trans size = 1 ifTrue: [
            aTrans start.]
    ]

    mgcpTransFinished: aTrans [
        <category: 'audio-connect'>
        mgcp_trans first = aTrans ifFalse: [
            self logError: 'GSMProc(srcref:%1) wrong MGCP transaction finished.'
                    % {self srcRef} area: #bsc.
            ^false].

        mgcp_trans removeFirst.
        mgcp_trans isEmpty ifFalse: [
            mgcp_trans first start.
        ].
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
            self takeLocks: [self crcxResult: result. self mgcpTransFinished: trans]].
        trans onTimeout: [:endp |
            self takeLocks: [self crcxTimeout. self mgcpTransFinished: trans]].
        mgcp_trans := OrderedCollection with: trans.
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

        "Assign the current SDP file"
        endp sdp: aResult sdp.

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

    sdpFile [
        <category: 'audio-sdp'>
        ^ endp sdp
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
            self takeLocks: [self dlcxResult: result. self mgcpTransFinished: trans]].
        trans onTimeout: [:endp |
            self takeLocks: [self dlcxTimeout. self mgcpTransFinished: trans]].
        self mgcpQueueTrans: trans.
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

    sendMDCX: aSDPRecord state: aState [
        | trans mdcx |
        <category: 'audio-modify'>

        trans := Osmo.MGCPTransaction on: endp of: self callAgent.
        mdcx := Osmo.MGCPMDCXCommand createMDCX: endp callId: endp callId.
        mdcx
            parameterAdd: 'I: %1' % {connId};
            parameterAdd: 'M: %1' % {aState};
            sdp: aSDPRecord.
        
        trans
            command: mdcx;
            onResult: [:endp :result |
                self takeLocks: [self mdcxResult: result. self mgcpTransFinished: trans]];
            onTimeout: [:endp |
                self takeLocks: [self mdcxTimeout. self mgcpTransFinished: trans]].
        self mgcpQueueTrans: trans.
    ]

    mdcxResult: aResult [
    ]

    mdcxTimeout: aTimeout [
    ]

    authenticationAccepted [
        <category: 'auth'>
        "Must be locked"
        "TODO: where to start the encryption? CM Service Accept/Ciphering Command?"
        auth := nil.
        state := self class stateAuth.
        pending do: [:each |
            each key start: each value].
        pending := nil.
    ]

    authenticationRejected [
        <category: 'auth'>
        "Must be locked"

        "TODO"
        "Send a CM Service Reject/LU Reject to the phone. Probably the
        transaction should reject it."

        "Close down the connection. FIXME: use a better error value"
        self clearCommand: 0.
    ]
]
