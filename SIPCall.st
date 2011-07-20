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
    | remoteLeg |
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
        'Session NEW' printNl.
        remoteLeg isNil
            ifFalse:  [remoteLeg netConnect]
            ifTrue: [self terminate].
    ]

    sessionFailed [
        'Session Failed' printNl.
        "We have failed to connect things, tell the other side."
        self terminateRemote.
    ]

    sessionEnd [
        'Session END' printNl.
        "The session is now disconnected, tell the other side."
        self terminateRemote.
    ]

    terminateRemote [
        remoteLeg isNil
            ifFalse: [remoteLeg netTerminate. remoteLeg := nil].
    ]

    sdp [
        <category: 'audio'>
        ^ sdp_result
    ]
] 
