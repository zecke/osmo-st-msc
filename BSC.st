Object subclass: BSCConfig [
    | lacs password |
    <comment: 'I represent a BSC configuration'>

    BSCConfig class >> initialize: aPassword [
        ^ (self new)
            initialize;
            password: aPassword;
            yourself
    ]

    initialize [
        lacs := OrderedCollection new.
    ]

    password: aPassword [
        password := aPassword.
    ]

    addLac: aLac [
       lacs add: aLac. 
    ]
]

