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

TestCase subclass: SIPIdentityManagerTest [
    testEmpty [
        | manager |
        manager := SIPIdentityManager new.
        self assert: manager available isEmpty.
    ]

    testAvailable [
        | manager |
        manager := SIPIdentityManager initWith: MockSIPUserAgent new.
        manager addIdentity: (MSCSIPIdentity new
                                username: 'user';
                                hostname: 'localhost';
                                yourself).
        self assert: manager available isEmpty.
    ]
]
