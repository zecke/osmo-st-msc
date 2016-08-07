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

Osmo.SIPCall subclass: SIPMTCall [
    | remoteLeg sdp_alert msc mscIdentity |

    <category: 'OsmoMSC-Call'>
    <comment: 'I represent a SIP terminated call. It is called Mobile
    Terminated to stay with the GSM speech.'>

    msc: aMsc [
        <category: 'creation'>
        msc := aMsc
    ]

    mscIdentity: anIdentity [
        mscIdentity := anIdentity
        mscIdentity usedBy: self.
    ]

    remoteLeg: aLeg [
        <category: 'creation'>
        remoteLeg := aLeg.
    ]

    remoteLeg [
        ^remoteLeg
    ]

    netTerminate [
        <category: 'external'>
        "The other side of the call has terminated, we need to
        clean up things."

        remoteLeg := nil.
        self releaseMscIdentity.
        self terminate.
    ]

    sessionRedirect: aContact [
        | newLeg |
        remoteLeg ifNil: [^self].

        self releaseMscIdentity.
        newLeg := msc selectRedirectFor: self to: aContact.
        newLeg isNil
            ifTrue: [
                self terminateRemote]
            ifFalse: [
                remoteLeg changeRemoteLeg: newLeg.
                remoteLeg := nil].
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

    terminate [
        self releaseMscIdentity.
        ^super terminate
    ]

    sessionNotification: aNot [
        | code |
        "The session has some information. We will use it to tell
        the other leg of the connection."
        code := aNot code asInteger.
        ((code = 180) or: [code = 183]) ifTrue: [
            remoteLeg isNil ifFalse: [
                sdp_alert := aNot sdp.
                remoteLeg netAlerting]].
    ]

    terminateRemote [
        remoteLeg isNil
            ifFalse: [remoteLeg netTerminate. remoteLeg := nil].
        self releaseMscIdentity.
    ]

    sdp [
        <category: 'audio'>
        ^ sdp_result
    ]

    sdpAlert [
        <category: 'audio'>
        ^ sdp_alert
    ]

    releaseMscIdentity [
        mscIdentity ifNotNil: [mscIdentity usedBy: nil. mscIdentity := nil].
    ]
] 
