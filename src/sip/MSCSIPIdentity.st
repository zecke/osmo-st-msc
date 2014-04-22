"
 (C) 2014 by Holger Hans Peter Freyther
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

Osmo.SIPIdentity subclass: MSCSIPIdentity [
    | available manager registerTimer |
    <category: 'OsmoMSC-SIP'>
    <comment: 'I add timers and others to the plain identity. This
    way we can keep track if something is available or not.'>

    MSCSIPIdentity class >> new [
        ^super new
            initialize;
            yourself
    ]

    initialize [
        available := false.
    ]

    manager: aManager [
        manager := aManager
    ]

    startRegistration [
        | register dialog |
        dialog := (Osmo.SIPDialog fromUser: 'sip:', username host: hostname port: 5060)
                        identity: self;
                        yourself.
        register := (Osmo.SIPRegisterTransaction createWith: dialog on: manager useragent cseq: 1)
                        destination: 'sip:', hostname;
                        onTimeout: [self registrationTimedOut];
                        onFailure: [:response :dialog | self registrationFailed]; 
                        onSuccess: [:response :dialog | self registrationSuccess];
                        yourself.
        register start.
    ]

    registrationTimedOut [
        self logNotice: 'SIPIdentity(%1@%2) registration timed-out' % {username. hostname}
                area: #mscSIP.
        available := false.
        self reRegisterIn: 10.
    ]

    registrationFailed [
        self logNotice: 'SIPIdentity(%1@%2) registration timed-out' % {username. hostname}
                area: #mscSIP.
        available := false.
        self reRegisterIn: 10.
    ]

    registrationSuccess [
        self logNotice: 'SIPIdentity(%1@%2) registered' % {username. hostname}
                area: #mscSIP.
        available := true.
        self reRegisterIn: 3590.
    ]

    reRegisterIn: seconds [
        "Re-register the identity..."
        registerTimer ifNotNil: [registerTimer cancel].
        registerTimer := (Osmo.TimerScheduler instance)
                scheduleInSeconds: seconds block: [self startRegistration].
    ]

    isAvailable [
        ^available
    ]
]
