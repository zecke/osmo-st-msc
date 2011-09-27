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
This is the interface to the local HLR. It consists out of simple
data that will be used inside the HLR.
"

Object subclass: HLRSubscriber [
    |imsi msisdn vlrnumber auKey name |

    <category: 'OsmoMSC-HLR'>
    <comment: 'I am one subscriber in the HLR'>

    imsi      [ <category: 'accessing'> ^ imsi      ]
    msisdn    [ <category: 'accessing'> ^ msisdn    ]
    vlrnumber [ <category: 'accessing'> ^ vlrnumber ]
    aukey     [ <category: 'accessing'> ^ auKey     ]
    name      [ <category: 'accessing'> ^ name      ]
]

Object subclass: HLR [
    <category: 'OsmoMSC-HLR'>
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

    <category: 'OsmoMSC-HLR'>
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
