"
 (C) 2011 by Holger Hans Peter Freyther
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
I am helping to get things started on the first image resume
"

PackageLoader fileInPackage: #OsmoMSC.

Object subclass: Loader [
    <category: 'OsmoMSC-Loader'>
    <comment: 'I wait for the image to resume and then I start the
    MSC example application and put it into the OsmoMSC namespace.'>

    Loader class >> new [
        <category: 'creation'>

        ^ super new
            initialize;
            yourself.
    ]

    initialize [
        <category: 'creation'>
        ObjectMemory addDependent: self.
    ]

    update: aSymbol [
        <category: 'initialize'>

        aSymbol = #returnFromSnapshot ifTrue: [
            OsmoMSC at: #MSC put: OsmoMSC.MSCApplication startExample.
            ObjectMemory removeDependent: self.
        ].
    ]
]

Eval [
    | l | 
    l := Loader new.
    ObjectMemory snapshot: Smalltalk arguments first
]
