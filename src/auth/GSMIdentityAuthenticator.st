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


GSMAuthenticatorBase subclass: GSMIdentityAuthenticator [
    | state timeout |
    <category: 'OsmoMSC-GSM-Auth'>
    <comment: 'I query for the IMSI and IMEI but do this in an insecure
    way and will never switch on the crypto. I will ask for the IMSI and
    IMEI'>

    cancel [
        "Cancel all timers"
        timeout ifNotNil: [timeout cancel. timeout := nil].
    ]

    reject: aMsg [
        <category: 'reject'>
        self logError: 'GSMIdentityAuthenticator(srcref:%1) rejecting type %2'
            % {connection srcRef. aMsg class} area: #bsc.
        state := #rejected:.
        onReject value: self.
    ]

    start: aMsg [
        "TODO we could take the IMSI from the first message but this
        is mostly for educational purpose."
        (self appropriateInitialMessage: aMsg)
            ifTrue: [self askForIMSI]
            ifFalse: [self reject: aMsg].
    ]

    askForIMSI [
        | req |

        timeout := Osmo.TimerScheduler instance
            scheduleInSeconds: 5 block: [self timeOut].

        "I ask for the IMSI."
        req := GSM48IdentityReq new.
        req idType type: GSM48IdentityType typeIMSI.
        state := #askForIMSI:.
        self nextPut: req toMessage.
    ]

    askForIMSI: aIdResponse [
        connection
            addInfo: 'IMSI'
            value: aIdResponse mi imsi.
        self logNotice: 'GSMIdentityAuthenticator(srcref:%1) got IMSI(%2).'
                % {connection srcRef. aIdResponse mi imsi} area: #bsc.
        timeout cancel.
        onAccept value: self.
    ]

    onData: aMsg [
        [
            self perform: state with: aMsg.
        ] on: Error do: [:e |
            e logException: 'GSMIdentityAuthenticator(srcref:%1) failed dispatch.'
                % {connection srcRef} area: #bsc.
            timeout cancel.
            onReject value: self.
        ].
    ]

    timeOut [
        self logError: 'GSMIdentityAuthenticator(srcref:%1) no reply to %2'
               % {connection srcRef. state} area: #bsc.
        state := #timedout:.
        connection takeLocks: [onReject value: self].
    ]
]
