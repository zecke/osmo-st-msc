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

TestCase subclass: VLRTest [
    <category: 'OsmoMSC-Tests'>

    testVLRFind [
        | vlr sub1 sub2 |
        vlr := VLRLocalCollection initWith: HLRDummyResolver new.
        self assert: (vlr insertSubscriber: '123456').

        sub1 := vlr findSubscriberByIMSI: '123456' ifAbsent: [2342].
        self assert: sub1 imsi = '123456'.
        self assert: sub1 tmsi isNil.

        sub2 := vlr findSubscriberByTMSI: 2342 ifAbsent: [true].
        self assert: (sub2 isKindOf: True).

        sub1 instVarNamed: #tmsi put: 2342.
        sub2 := vlr findSubscriberByTMSI: 2342 ifAbsent: [false].
        self assert: sub1 = sub2.
    ]
]
