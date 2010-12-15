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

PackageLoader fileInPackage: 'SUnit'.

TestCase subclass: HLRTest [
    testHLRFind [
        | hlr sub |
        hlr := HLRLocalCollection new.
        hlr addSubscriber: '123456'.
        hlr addSubscriber: '345677'.

        self assert: (hlr findSubscriberByIMSI: '123456') isNil not.
        self assert: (hlr findSubscriberByIMSI: '345677') isNil not.
        self assert: (hlr findSubscriberByIMSI: '432432') isNil.

        sub := hlr findSubscriberByIMSI: '123456'.
        self assert: sub imsi = '123456'.
    ]
]

HLRResolver subclass: HLRDummyResolver [
    insertSubscriber: aIMSI [ ^ true ]
]

TestCase subclass: VLRTest [
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

TestCase subclass: BSCConfigTest [
    <comment: 'I will test the BSCConfig'>

    testConfigItem [
        | item1 item2 addr |
        addr := Sockets.SocketAddress byName: '127.0.0.1'.
        item1 := BSCConfigItem initWith: '127.0.0.1' name: 'test1'.
        item2 := BSCConfigItem initWith: addr name: 'test2'.

        self assert: item1 name = 'test1'.
        self assert: item1 peer = addr.
        self assert: item1 lac = -1.
        self assert: item1 connected not.

        self assert: item2 name = 'test2'.
        self assert: item2 peer = addr.
        self assert: item2 lac = -1.
        self assert: item2 connected not.
    ]

    testConfig [
        | cfg |

        "Test that adding stuff again is refused"

        cfg := BSCConfig new.
        self shouldnt:
            [cfg addBSC: '127.0.0.1' withName: 'abc1' andLac: 2311]
            raise: Exception description: 'Simply adding it'.
        self should:
            [cfg addBSC: '127.0.0.1' withName: 'abc2' andLac: 1123]
            raise: Exception description: 'Same IP is forbidden'.
        self should:
            [cfg addBSC: '127.0.0.2' withName: 'abc3' andLac: 2311]
            raise: Exception description: 'Different IP same lac'.
        self shouldnt:
            [cfg addBSC: '127.0.0.2' withName: 'abc4' andLac: 1123]
            raise: Exception description: 'Different IP, different lac'.

        self assert: cfg bscList size = 2 description: 'Two BSCs should be registered'.


        cfg removeBSC: '127.0.0.1'.
        self assert: cfg bscList size = 1 description: 'One BSC should be gone'.
        cfg removeBSCByLac: 1123.
        self assert: cfg bscList size = 0 description: 'All BSCsshould be removed'.
    ]
]
