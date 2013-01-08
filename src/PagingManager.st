"
 (C) 2013 by Holger Hans Peter Freyther
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

Object subclass: PagingManager [
    | msc |

    PagingManager class >> initWith: aMsc [
        ^ self new
            instVarNamed: #msc put: aMsc;
            yourself.
    ]


    pageAll: anImsi [
        <category: 'paging'>
        "Page a subscriber on all LACs of all BSCs"
        msc bscConfig bscList do: [:bscConfig |
            "This can race with a disconnect but that is fine."
            bscConfig connected ifTrue: [
                OsmoDispatcher dispatchBlock: [
                    self pageBSC: bscConfig with: anImsi]]].
    ]

    pageBSC: aBscConfig with: anImsi [
        | connection cmd |
        <category: 'paging'>
        "Page a single BSC"

        "Is the bsc still connected?"
        connection := aBscConfig connection.
        connection ifNil: [
            ^ false
        ].

        cmd := self createPagingCommand: aBscConfig lac with: anImsi.
        connection sendUdt: cmd toMessage asByteArray.
    ]

    createPagingCommand: aLac with: anImsi [
        | cmd |
        cmd := OsmoGSM.IEMessage initWith: OsmoGSM.GSM0808Helper msgPaging.
        cmd
            addIe: (OsmoGSM.GSM0808IMSI initWith: anImsi);
            addIe: (OsmoGSM.GSM0808CellIdentifierList new
                        ident: OsmoGSM.GSM0808CellIdentifierList cellLocationAreaCode;
                        cells: (Array with: aLac);
                        yourself);
            yourself.

        ^ OsmoGSM.BSSAPManagement initWith: cmd toMessage
    ]
]
