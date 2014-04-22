"
 (C) 2014 by Holger Hans Peter Freyther
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

Object subclass: SIPIdentityManager [
    | identities useragent |

    <category: 'OsmoMSC-SIP'>
    <comment: 'I help in managing and registering different
    SIPIdentities. This includes running the register transaction,
    re-running it shortly before the expiration and helping to
    keep track which one is used and not.'>

    SIPIdentityManager class >> new [
        ^super new
            initialize;
            yourself
    ]

    SIPIdentityManager class >> initWith: aUseragent [
        ^self new
            useragent: aUseragent;
            yourself
    ]

    initialize [
        identities := OrderedCollection new.
    ]

    useragent [
        ^useragent
    ]

    useragent: aUseragent [
        useragent := aUseragent
    ]

    addIdentity: anIdentity [
        identities add: anIdentity.
        anIdentity
            manager: self;
            startRegistration.
    ]

    available [
        ^identities select: [:each | each isAvailable]
    ]

    availableAndUnused [
        ^identities select: [:each | each isAvailable and: [each isUnused]]
    ]
]
