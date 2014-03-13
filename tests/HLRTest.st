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

TestCase subclass: HLRTest [
    <category: 'OsmoMSC-Tests'>

    testHLRFind [
        | hlr sub |
        hlr := HLRLocalCollection new.
        hlr addSubscriber: '123456'.
        hlr addSubscriber: '345677'.

        self deny: (hlr findSubscriberByIMSI: '123456') isNil.
        self deny: (hlr findSubscriberByIMSI: '345677') isNil.
        self assert: (hlr findSubscriberByIMSI: '432432') isNil.

        sub := hlr findSubscriberByIMSI: '123456'.
        self assert: sub imsi = '123456'.
    ]
]
