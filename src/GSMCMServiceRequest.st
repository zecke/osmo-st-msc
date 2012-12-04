"
 (C) 2012 by Holger Hans Peter Freyther
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

OsmoGSM.GSM48CMServiceReq extend [
    openTransactionOn: aCon sapi: aSapi [
        | tran |
        <category: '*-OsmoMSC-GSM'>

        "This is weird. We can accept or reject the service."
        tran := (GSMCMServiceRequest on: aSapi with: self ti)
                    con: aCon; yourself.
        aCon openTransaction: tran with: self.
    ]
]

OsmoGSM.GSM48MSG extend [
    dispatchForCMOn: aCon [
        <category: '*-OsmoMSC-GSM'>
        self logError: '%1(srcref:%2) unknown dispatch for CM Service Request'
            % {self class. aCon srcref} with: #bsc.
        ^ false
    ]
]

GSMTransaction subclass: GSMCMServiceRequest [
    | timeout service state |
    <category: 'OsmoMSC-GSM'>
    <comment: 'I am used by the MS to ask for a service. I can check
    if we want to have this service and Accept/Reject it. Atfer this
    I need to wait a bit for the actual service to be started.'>

    GSMCMServiceRequest class >> stateNull          [ <category: 'states'> ^ #null ]
    GSMCMServiceRequest class >> stateWaitService   [ <category: 'states'> ^ #service ]

    canHandle: aMsg sapi: aSapi [
        "TODO: check if there are other transactions that should be called? Or
        deal with it differently?"
        ^ true
    ]

    initialize [
        <category: 'creation'>
        state := self class stateNull.
    ]

    start: aCMServiceRequest [
        | accept |
        state := self class stateWaitService.
        accept := OsmoGSM.GSM48CMServiceAccept new.
        timeout := Osmo.TimerScheduler instance
                    scheduleInSeconds: 5 block: [con takeLocks: [self timeOut]].
        self nextPutSapi: accept.
    ]

    dispatch: aMsg [
        | res |
        "I am now getting the real MO-request. Let's see how we can
        morph it into a real request."

        res := aMsg dispatchForCMOn: self.
        res ifFalse: [^self].

        "We are done. Remove ourselves from the list."
        timeout cancel.
        con removeTransaction: self
    ]

    cancel [
        timeout cancel.
        ^ super cancel
    ]

    timeOut [
        self logError: 'GSMCMServiceRequest(srcref:%1) timeout in state %2'
            % {con srcRef. state} area: #bsc.
        con removeTransaction: self.
    ]
]
