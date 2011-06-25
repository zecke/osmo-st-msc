"
 (C) 2011 by Holger Hans Peter Freyther
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
        aCon moUnknown: self.
    ]
]

OsmoGSM.GSM48CCConnectAck extend [
    dispatchMoCall: aCon [
        aCon moConnectAck: self.
    ]
]

OsmoGSM.GSM48CCDisconnect extend [
    dispatchMoCall: aCon [
        aCon moDisconnect: self.
    ]
]

OsmoGSM.GSM48CCRelease extend [
    dispatchMoCall: aCon [
        aCon moRelease: self.
    ]
]

OsmoGSM.GSM48CCReleaseCompl extend [
    dispatchMoCall: aCon [
        aCon moReleaseCompl: self.
    ]
]

OsmoGSM.GSM48CCSetup extend [
    openTransactionOn: aCon sapi: aSapi [
        | tran |
        tran := (GSMMOCall on: aSapi with: self ti)
                    instVarNamed: #seq put: seq;
                    con: aCon;
                    yourself.
        aCon addTransaction: tran.
        tran start: self.
    ]
]

GSMTransaction subclass: GSMMOCall [
    | seq state timeout wait_for_ass |
    <comment: 'I handle Mobile-Originated calls as of 5.2.1 of GSM 04.08'>

    GSMMOCall class >> stateNull        [ <category: 'states'> ^ 0 ]
    GSMMOCall class >> stateProceeding  [ <category: 'states'> ^ 1 ]
    GSMMOCall class >> stateReceived    [ <category: 'states'> ^ 2 ]
    GSMMOCall class >> stateConnectReq  [ <category: 'states'> ^ 3 ]
    GSMMOCall class >> stateConnectCon  [ <category: 'states'> ^ 4 ]
    GSMMOCall class >> stateDisconnInd  [ <category: 'states'> ^ 5 ]
    GSMMOCall class >> stateReleaseReq  [ <category: 'states'> ^ 6 ]
    GSMMOCall class >> stateReleaseCompl [ <category: 'states'> ^ 7]

    initialize [
        <category: 'creation'>
        state := self class stateNull.
    ]

    nextPutSapi: aMsg [
        <category: 'output'>
        aMsg ti: (ti bitOr: 8).
        aMsg seq: seq.
        ^ super nextPutSapi: aMsg.
    ]

    netAlerting [
        <category: 'external'>
        "I am called by the other side of the call"
    ]

    netConnect [
        <category: 'external'>
        "I am called by the other side of the call"
    ]

    netDisconnect [
        <category: 'external'>
        "I am called by the other side of the call"
    ]

    moConnectAck: aMsg [
        <category: 'mo-message'>
    ]

    moDisconnect: aMsg [
        <category: 'mo-message'>
    ]

    moRelease: aMsg [
        <category: 'mo-message'>
    ]

    moRelaseCompl: aMsg [
        <category: 'mo-message'>
    ]

    moUnknown: aMsg [
        <category: 'mo-message'>
        ^ self logUnknown: aMsg.
    ]

    dispatch: aMsg [
        aMsg dispatchMoCall: self.
    ]

    sendReleaseComplete [
        | rlc |
        <category: 'gsm-routines'>

        rlc := OsmoGSM.GSM48CCReleaseCompl new.
        rlc causeOrDefault data: #(16rE1 16r83).
        self nextPutSapi: rlc.
    ]

    sendProceeding [
        | msg |
        <category: 'gsm-routines'>

        msg := OsmoGSM.GSM48CCProceeding new.
        self nextPutSapi: msg.
    ]

    releaseComplete [
        <category: 'transaction'>

        state := self class stateReleaseCompl.
        self sendReleaseComplete.
        self cancel.
        con removeTransaction: self.
    ]

    start: aCCMessage [
        <category: 'transaction'>

        "Failed to allocate an endpoint"
        con allocateEndpoint isNil ifTrue: [
            self releaseComplete.
            ^ self
        ].

        "We are waiting for an assignment"
        wait_for_ass := true.
        state := self class stateProceeding.
        self sendProceeding.

        timeout := Osmo.TimerScheduler instance scheduleInSeconds: 10 block: [
            "hack to release things immediately"
            con removeTransaction: self.
        ]
    ]

    cancel [
        timeout ifNotNil: [timeout cancel].
        ^ super cancel
    ]

    assignmentFailure [
        "The assignment failed, let's see if it could be for us"
        wait_for_ass ifTrue: [
            self releaseComplete.
        ]
    ]

    assignmentSuccess [

    ]
]

