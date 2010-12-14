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
