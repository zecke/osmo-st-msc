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

Object subclass: BSCConfigItem [
    | peer token name lac connected |
    BSCConfigItem class >> initWith: aPeer name: aName [
        ^ self new
            peer: aPeer; name: aName; lac: -1; connected: false; yourself
    ]

    BSCConfigItem class >> resolveAddress: aPeer [
        ^ aPeer isString
            ifTrue:  [Sockets.SocketAddress byName: aPeer]
            ifFalse: [aPeer].
    ]

    peer [ <category: 'accessing'> ^ peer ]
    peer: aPeer [
        <category: 'private'>

        peer := self class resolveAddress: aPeer.
    ]

    name [ <category: 'accessing'> ^ name ]
    name: aName [
        <category: 'private'>
        name := aName.
    ]

    lac [ <category: 'accessing'> ^ lac ]
    lac: aLac [
        <category: 'private'>
        lac := aLac.
    ]

    connected [ <category: 'accessing'> ^ connected ]
    connected: aState [
        <category: 'private'>
        connected := aState.
    ]
]

Object subclass: BSCConfig [
    | bscList |
    <comment: 'I know the BSCs that can connect to me'>

    removeBSC: aPeer [
        | peer |
        peer := BSCConfigItem resolveAddress: aPeer.
        self bscList removeAllSuchThat: [:element | element peer = peer].
    ]

    removeBSCByLac: aLac [
        self bscList removeAllSuchThat: [:element | element lac = aLac].
    ]

    addBSC: ip withName: aName andLac: aLac [
        | addr bsc |
        <category: 'management'>
        "Make sure that no one with the same IP or LAC registers"

        addr := Sockets.SocketAddress byName: ip.
        bsc := BSCConfigItem initWith: addr name: aName.
        bsc lac: aLac.

        (self bscList anySatisfy: [:each | each peer = addr ])
            ifTrue: [
                self error: 'The address needs to be unique'.
        ].

        (self bscList anySatisfy: [:each | each lac = aLac])
            ifTrue: [
                self error: 'The lac needs to be unique'.
        ].

        self bscList add: bsc.
    ]

    bscList [ ^ bscList ifNil: [bscList := OrderedCollection new]]
]
