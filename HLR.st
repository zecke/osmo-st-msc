"
This is the interface to the local HLR. It consists out of simple
data that will be used inside the HLR.
"

Object subclass: HLRSubscriber [
    |imsi msisdn vlrnumber auKey name |
    <category: 'osmo-msc'>
    <comment: 'I am one subscriber in the HLR'>

    imsi      [ <category: 'accessing'> ^ imsi      ]
    msisdn    [ <category: 'accessing'> ^ msisdn    ]
    vlrnumber [ <category: 'accessing'> ^ vlrnumber ]
    aukey     [ <category: 'accessing'> ^ auKey     ]
    name      [ <category: 'accessing'> ^ name      ]
]

Object subclass: HLR [
    <category: 'osmo-msc'>
    <comment: 'I am a HLR and I can find subscribers'>

    findSubscriberByIMSI: aIMSI [
        <category: 'accessing'>
        ^ self subclassResponsibility
    ]

    updateVLRNumber: aIMSI number: aNumber [
        ^ self subclassResponsibility
    ]
]

HLR subclass: HLRLocalCollection [
    | subs |
    <category: 'osmo-msc-simple'>
    <comment: 'I am a very simple local HLR'>

    findSubscriberByIMSI: aIMSI [
        <category: 'accessing'>
        self subs do: [:each |
            (each imsi = aIMSI)
                ifTrue: [^each]].

        ^ nil
    ]

    addSubscriber: aIMSI [
        | sub |
        sub := HLRSubscriber new.
        sub instVarNamed: #imsi put: aIMSI.

        self subs add: sub.
    ]

    subs [<category: 'private'> ^subs ifNil: [subs := OrderedCollection new]]
]
