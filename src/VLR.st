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
"
This is the interface to the VLR
"

Object subclass: VLRSubscriber [
    |imsi tmsi msisdn lac|

    <category: 'OsmoMSC-VLR'>
    <comment: 'I am one subscriber in the VLR'>
    

    imsi   [ <category: 'accessing'> ^ imsi   ]
    tmsi   [ <category: 'accessing'> ^ tmsi   ]
    msisdn [ <category: 'accessing'> ^ msisdn ]
    lac    [ <category: 'accessing'> ^ lac    ]
]

Object subclass: VLR [
    <category: 'OsmoMSC-VLR'>
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
    <category: 'OsmoMSC-HLR'>
    insertSubscriber: aIMSI [
        ^ self subclassResponsibility
    ]
]

VLR subclass: VLRLocalCollection [
    | subs resolver |

    <category: 'OsmoMSC-VLR'>

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
