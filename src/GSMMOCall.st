"
 (C) 2011-2012 by Holger Hans Peter Freyther
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

OsmoGSM.GSM48MSG extend [
    dispatchMoCall: aCon [
        <category: '*-OsmoMSC-GSM'>
        aCon moUnknown: self.
    ]
]

OsmoGSM.GSM48CCConnectAck extend [
    dispatchMoCall: aCon [
        <category: '*-OsmoMSC-GSM'>
        aCon moConnectAck: self.
    ]
]

OsmoGSM.GSM48CCDisconnect extend [
    dispatchMoCall: aCon [
        <category: '*-OsmoMSC-GSM'>
        aCon moDisconnect: self.
    ]
]

OsmoGSM.GSM48CCRelease extend [
    dispatchMoCall: aCon [
        <category: '*-OsmoMSC-GSM'>
        aCon moRelease: self.
    ]
]

OsmoGSM.GSM48CCReleaseCompl extend [
    dispatchMoCall: aCon [
        <category: '*-OsmoMSC-GSM'>
        aCon moReleaseCompl: self.
    ]
]

OsmoGSM.GSM48CCStatus extend [
    dispatchMoCall: aCon [
        <category: '*-OsmoMSC-GSM'>
        aCon moStatus: self.
    ]
]

OsmoGSM.GSM48CCSetup extend [
    openTransactionOn: aCon sapi: aSapi [
        | tran |
        <category: '*-OsmoMSC-GSM'>
        tran := (GSMMOCall on: aSapi with: self ti)
                    con: aCon;
                    yourself.
        aCon openTransaction: tran with: self.
    ]
]

GSMTransaction subclass: GSMMOCall [
    | state wait_for_ass remoteLeg |

    <category: 'OsmoMSC-GSM'>
    <comment: 'I handle Mobile-Originated calls as of 5.2.1 of GSM 04.08. I should
    represent the states found in Figure 5.1b/3GPP TS 04.08: Overview call controll
    protocol/Network side. Right now the set of states is incomplete and is mixed
    for MO and MT. It is not very clear if the text and the state machine fit together.'>

    GSMMOCall class >> stateNull        [ <category: 'states'> ^ #null ]
    GSMMOCall class >> stateProceeding  [ <category: 'states'> ^ #proceeding ]
    GSMMOCall class >> stateConnectInd  [ <category: 'states'> ^ #connect_indication ]
    GSMMOCall class >> stateActive      [ <category: 'states'> ^ #active ]
    GSMMOCall class >> stateDisconnInd  [ <category: 'states'> ^ #disconn_ind ]
    GSMMOCall class >> stateReleaseReq  [ <category: 'states'> ^ #release_req ]
    GSMMOCall class >> stateReleaseCompl [ <category: 'states'> ^ #release_compl ]

    initialize [
        <category: 'creation'>
        state := self class stateNull.
    ]

    nextPutSapi: aMsg [
        <category: 'output'>
        aMsg ti: (ti bitOr: 8).
        aMsg seq: 0.
        ^ super nextPutSapi: aMsg.
    ]

    netAlerting [
        <category: 'external'>
        "I am called by the other side of the call"

        (state = self class stateProceeding) ifTrue: [
            con sendMDCX: remoteLeg sdpAlert state: 'recvonly'.
            self sendAlerting.
        ].
    ]

    netConnect [
        <category: 'external'>
        "I am called by the other side of the call. I will need to get
         the SDP file of this side to send a MGCP message down the stream."

        (state = self class stateProceeding) ifTrue: [
            state := self class stateConnectInd.
            con sendMDCX: remoteLeg sdp state: 'sendrecv'.
            self sendConnect.
        ].
    ]

    netTerminate [
        <category: 'external'>
        "The other side of the call has terminated, let
        us do the clean up."
        remoteLeg isNil ifFalse: [
            remoteLeg := nil.
            state := self class stateDisconnInd.
            self sendDisconnect: #(16rE1 16r90)
        ].
    ]

    moConnectAck: aMsg [
        <category: 'mo-message'>
        (state = self class stateConnectInd) ifTrue: [
            self logNotice: 'GSMMOCall(srcref:%1) call is connected.'
                % {con srcRef} area: #bsc.
            state := self class stateActive.
        ].
    ]

    moDisconnect: aMsg [
        <category: 'mo-message'>
        state := self class stateDisconnInd.
        self sendRelease: #(16rE1 16r90).

        "Disconnect the remote"
        remoteLeg isNil ifFalse: [
            remoteLeg netTerminate.
            remoteLeg := nil.
        ].
    ]

    moRelease: aMsg [
        <category: 'mo-message'>
        state = self class stateDisconnInd ifFalse: [
            self logError: 'GSMMOCall(srcref:%1) release in state %2'
                % {con srcRef. self state} area: #bsc.
        ].

        self releaseComplete.
    ]

    moReleaseCompl: aMsg [
        <category: 'mo-message'>
        self cancel.
        con removeTransaction: self.
    ]

    moUnknown: aMsg [
        <category: 'mo-message'>
        ^ self logUnknown: aMsg.
    ]

    moStatus: aMsg [
        <category: 'mo-message'>
        "We did something wrong, just give up and see how it can be fixed."
        self logError: 'GSMOCall(srcref:%1) something wrong with call state.'
                % {con srcRef} area: #bsc.
        self cancel.
        con removeTransaction: self.
    ]

    dispatch: aMsg [
        aMsg dispatchMoCall: self.
    ]

    sendReleaseComplete: aCause [
        | rlc |
        <category: 'gsm-routines'>

        rlc := OsmoGSM.GSM48CCReleaseCompl new.
        rlc causeOrDefault data: aCause.
        self nextPutSapi: rlc.
    ]

    sendRelease: aCause [
        | rel |
        <category: 'gsm-routines'>
        rel := OsmoGSM.GSM48CCRelease new.
        rel causeOrDefault data: aCause.
        self nextPutSapi: rel.
    ]

    sendProceeding [
        | msg |
        <category: 'gsm-routines'>

        msg := OsmoGSM.GSM48CCProceeding new.
        self nextPutSapi: msg.
    ]

    sendAlerting [
        | msg |
        <category: 'gsm-routines'>

        msg := OsmoGSM.GSM48CCAlerting new.
        self nextPutSapi: msg.
    ]

    sendConnect [
        | msg |
        <category: 'gsm-routines'>
        msg := OsmoGSM.GSM48CCConnect new.
        self nextPutSapi: msg.
    ]

    sendDisconnect: aCause [
        | msg |
        <category: 'gsm-routines'>

        msg := OsmoGSM.GSM48CCDisconnect new.
        msg cause data: aCause.
        self nextPutSapi: msg.
    ]

    releaseComplete [
        <category: 'transaction'>

        state := self class stateReleaseCompl.
        self sendReleaseComplete: #(16rE1 16r83).
        self cancel.
        con removeTransaction: self.
    ]

    selectAudioRoute: aCCMessage [
        "select route for this call, or release the call"
        remoteLeg := con selectAudioRoute: aCCMessage calledOrDefault leg: self.
        remoteLeg isNil ifTrue: [
            self logError:
                'GSMMOCall(srcref:%1) failed to select audio route.'
                    % {con srcRef} area: #bsc.
            self releaseComplete.
        ].
    ]

    start: aCCMessage [
        <category: 'transaction'>

        self selectAudioRoute: aCCMessage.
        remoteLeg isNil ifTrue: [^self].

        "Failed to allocate an endpoint"
        con allocateEndpoint isNil ifTrue: [
            self releaseComplete.
            ^ self
        ].

        "We are waiting for an assignment"
        wait_for_ass := true.
        state := self class stateProceeding.
        self sendProceeding.

        con sendAssignment.
    ]

    cancel [
        remoteLeg ifNotNil: [remoteLeg netTerminate].
        ^ super cancel
    ]

    assignmentFailure [
        "The assignment failed, let's see if it could be for us"
        wait_for_ass ifTrue: [
            remoteLeg := nil.
            self releaseComplete.
        ]
    ]

    assignmentSuccess [
        wait_for_ass := false.
        remoteLeg createCall: con sdpFile.
    ]
]

