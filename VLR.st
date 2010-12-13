"
This is the interface to the VLR
"

Object subclass: VLRSubscriber [
    |imsi tmsi msisdn lac|
    <category: 'osmo-msc'>
    <comment: 'I am one subscriber in the VLR'>
    

    imsi   [ <category: 'accessing'> ^ imsi   ]
    tmsi   [ <category: 'accessing'> ^ tmsi   ]
    msisdn [ <category: 'accessing'> ^ msisdn ]
    lac    [ <category: 'accessing'> ^ lac    ]
]

Object subclass: VLR [
    <category: 'osmo-msc'>
    <comment: 'I hold the active subscribers'>

    activeSubscribers [
        <category: 'accessing'>
        ^ self subclassResponsibility
    ]

    activeSubscribersByLAC: aLac [
        <category: 'accessing'>
        ^ self activeSubscribers
                reject: [:each | each ~= aLac ].
    ]

    findSubscriber: aMatch ifAbsent: aBlock [
        <category: 'private'>

        self activeSubscribers do: [:each |
            (aMatch value: each)
                ifTrue: [^each].
        ].

        ^ aBlock value.
    ]

    findSubscriberByIMSI: aIMSI ifAbsent: aBlock [
        <category: 'accessing'>
        ^ self findSubscriber: [:each | each imsi = aIMSI] ifAbsent: aBlock.
    ]

    findSubscriberByTMSI: aTMSI ifAbsent: aBlock [
        <category: 'accessing'>
        ^ self findSubscriber: [:each | each tmsi = aTMSI] ifAbsent: aBlock.
    ]

    insertSubscriber: aIMSI [
        ^ self subclassResponsibility
    ]
]

Object subclass: HLRResolver [
    insertSubscriber: aIMSI [
        ^ self subclassResponsibility
    ]
]

VLR subclass: VLRLocalCollection [
    | subs resolver |

    VLRLocalCollection class >> initWith: aResolver [
        ^ self new
            instVarNamed: #resolver put: aResolver;
            yourself.
    ]

    insertSubscriber: aIMSI [
        | hlr sub |
        hlr := resolver insertSubscriber: aIMSI.
        hlr ifNil: [^false].

        sub := self findSubscriberByIMSI: aIMSI
                    ifAbsent: [ | sub |
                        sub := VLRSubscriber new
                            instVarNamed: #imsi put: aIMSI; yourself.
                    self subs add: sub].
        ^ true
    ]

    activeSubscribers [
        <category: 'accessing'>
        ^ self subs
    ]

    subs [ <category: 'private'> ^ subs ifNil: [subs := OrderedCollection new]]
]
