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

PackageLoader fileInPackage: 'OsmoSIP'.

Osmo.SIPCall subclass: SIPMTCall [
    | remoteLeg sdp_alert |
    <category: 'sip'> 
    <comment: 'I represent a SIP terminated call. It is called Mobile
    Terminated to stay with the GSM speech.'>

    remoteLeg: aLeg [
        <category: 'creation'>
        remoteLeg := aLeg.
    ]

    netTerminate [
        <category: 'external'>
        "The other side of the call has terminated, we need to
        clean up things."

        remoteLeg := nil.
        self terminate.
    ]

    sessionNew [
        "We now have connected call, tell the other side."
        remoteLeg isNil
            ifFalse:  [remoteLeg netConnect]
            ifTrue: [self terminate].
    ]

    sessionFailed [
        "We have failed to connect things, tell the other side."
        self terminateRemote.
    ]

    sessionEnd [
        "The session is now disconnected, tell the other side."
        self terminateRemote.
    ]

    sessionNotification: aNot [
        "The session has some information. We will use it to tell
        the other leg of the connection."
        (aNot code asInteger = 183) ifTrue: [
            remoteLeg isNil ifFalse: [
                sdp_alert := aNot sdp.
                remoteLeg netAlerting]].
    ]

    terminateRemote [
        remoteLeg isNil
            ifFalse: [remoteLeg netTerminate. remoteLeg := nil].
    ]

    sdp [
        <category: 'audio'>
        ^ sdp_result
    ]

    sdpAlert [
        <category: 'audio'>
        ^ sdp_alert
    ]
] 