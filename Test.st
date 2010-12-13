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
