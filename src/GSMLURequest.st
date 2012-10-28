"
 (C) 2012 by Holger Hans Peter Freyther
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

PackageLoader
    fileInPackage: 'OsmoCore';
    fileInPackage: 'OsmoGSM'.

OsmoGSM.GSM48LURequest extend [
    openTransactionOn: aCon sapi: aSapi [
        | tran |
        <category: '*-OsmoMSC-GSM'>
        'foo' printNl.

        tran := (GSMLURequest on: aSapi with: self ti)
                  con: aCon;
                  yourself.
        aCon openTransaction: tran with: self.
    ]
]


GSMTransaction subclass: GSMLURequest [
    | timeout |
    <category: 'OsmoMSC-GSM'>
    <comment: 'I handle LU requests and do things. I am being written before
    the actual code'>

    initialize [
        <category: 'creation'>
    ]

    start: aCCMessage [
        <category: 'start'>

      aCCMessage inspect.
      timeout := Osmo.TimerScheduler instance
          scheduleInSeconds: 5 block: [self timeOut].
    ]

    timeOut [
        self logError: 'GSMLURequest(srcref:%1) timeout.' % {con srcRef} area: #bsc.
        con removeTransaction: self.
    ]
]
