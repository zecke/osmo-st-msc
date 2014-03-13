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

Object subclass: GSMProcessorMockBase [
    | auth dict |
    <category: 'OsmoMSC-Tests'>

    GSMProcessorMockBase class >> initWith: anAuth [
        ^ self new
            instVarNamed: #auth put: anAuth;
            instVarNamed: #dict put: Dictionary new;
            yourself.
    ]

    addInfo: aName value: aValue [
        dict at: aName put: aValue.
    ]

    getInfo: aName [
        ^ dict at: aName
    ]

    srcRef [
        ^ 1
    ]

    takeLocks: aBlock [
        aBlock value
    ]
]
