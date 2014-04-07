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

Object subclass: GSMAuthenticatorBase [
    | connection onAccept onReject |
    <category: 'OsmoMSC-GSM-Auth'>
    <comment: 'I am the base class for authenticating a given
    subscriber. My subclasses can either allow everyone, store
    the IMSI and IMEI or be fully GSM compliant and ask a HLR
    for an authentication tuple.
    When calling the callbacks make sure to go through the
    connection>>#takeLocks: selector to take the required locks.'>
    <import: OsmoGSM>

    LegalMessages := {OsmoGSM.GSM48CMServiceReq.
                      OsmoGSM.GSM48RRPagingResponse.
                      OsmoGSM.GSM48LURequest.
                      "As part of Local-Call-Routing deal with CC Setup"
                      OsmoGSM.GSM48CCSetup.
                        }.

    appropriateInitialMessage: aMsg [
        "Check if the message is one of the allowed initial messages."
        ^ LegalMessages includes: aMsg class
    ]

    connection: aCon [
        <category: 'creation'>
        connection := aCon.
    ]

    connection [
        <category: 'access'>
        ^ connection
    ]

    onAccept: aBlock [
        <category: 'creation'>
        "Called when the connection is accepted"
        onAccept := aBlock
    ]

    onReject: aBlock [
        <category: 'creation'>
        "Called when the connection is rejected"
        onReject := aBlock
    ]

    start: aMsg [
        <category: 'auth'>
        "Start authentication with the initial message."
        ^ self subclassResponsibility
    ]

    onData: aMsg [
        <category: 'auth'>
        "Called with data from the GSM connection"
        ^ self subclassResponsibility
    ]

    cancel [
        <category: 'auth'>
        "The GSM Connection has failed cancel everything."
        ^ self subclassResponsibility
    ]

    nextPut: aMsg [
        connection nextPutData: (BSSAPDTAP initWith: aMsg
                                    linkIdentifier: 0).
    ]
]
