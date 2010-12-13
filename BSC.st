Object subclass: BSCConfig [
    | name lacs password |
    <comment: 'I represent a BSC configuration'>
    <category: 'osmo-msc-private'>

    BSCConfig class >> withName: aName [
        ^ (self new)
            initialize;
            name: aName;
            yourself
    ]

    initialize [
        lacs := OrderedCollection new.
    ]

    " simple setter/getter "
    name: aName [ name := aName.]
    name [ ^ name ]

    password: aPassword [ password := aPassword. ]
    password [ ^ password ]

    addLac: aLac [
       lacs add: aLac. 
    ]

    lacs [
        ^ lacs
    ]
]

Object subclass: BSCManager [
    | bscs |
    <comment: 'I represent the BSC config.'>

    BSCManager class >> new [
        ^ (super new)
            initialize;
            yourself.
    ]

    initialize [
        bscs := OrderedCollection new.
    ]

    addBsc: aName [
        | bsc |
        bsc := BSCConfig withName: aName.
    ]
]
