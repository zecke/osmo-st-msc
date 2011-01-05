"
 (C) 2010 by Holger Hans Peter Freyther
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

Object subclass: GSMProcBase [
]

Object subclass: GSMProcessor [
    | sccp msc |
    <comment: 'I am driving one subscriber connection'>
    <import: OsmoGSM>

    GSMProcessor class >> initWith: aConnection msc: aMsc [
        ^ self new
            instVarNamed: #sccp put: aConnection;
            instVarNamed: #msc put: aMsc;
            yourself.
    ]

    handleLU: aMsg [
        | msg | 
        "I handle the LU procedure on this connection"

        "Ask for both identities"
        msg := GSM48IdentityReq new.
        msg idType type: GSM48IdentityType typeIMSI.
        sccp nextPutData: (BSSAPDTAP initWith: msg linkIdentifier: 0).

        msg := sccp next.

        aMsg mi inspect.
    ]

    process [
        | msg bssmap data gsm|

        "The first message should be a Complete Layer3 Information"
        msg := sccp next.

        msg class msgType = BSSAPHelper msgManagemnt ifFalse: [
            ^ self logError: 'Wrong initial message on %1' % {sccp srcRef} area: #msc.
        ].

        bssmap := msg data.
        bssmap type = GSM0808Helper msgComplL3 ifFalse: [
            ^ self logError: 'Should be complete layer3 on %1' % {sccp srcRef} area: #msc.
        ].

        bssmap findIE: GSMCellIdentifier elementId ifAbsent: [
            ^ self logError: 'CellIdentifier not present on %1' % {sccp srcRef} area: #msc.
        ].
        data := bssmap findIE: GSMLayer3Info elementId ifAbsent: [
            ^ self logError: 'Layer3Infor not present on %1' % {sccp srcRef} area: #msc.
        ].

        "This is now the GSM data"
        gsm := data data.
        gsm type = GSM48LURequest messageType ifTrue: [
            self handleLU: gsm.
        ]
    ]
]
