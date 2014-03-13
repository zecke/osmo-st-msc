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

TestCase subclass: AuthTestNull [
    <category: 'OsmoMSC-Tests'>
    <comment: 'I smoke-test the null authenticator and that it
    fires an accept callback right away.'>

    testImmediateAccept [
        | auth accepted |
        auth := GSMNullAuthenticator new
                    onAccept: [:a| self assert: a = auth. accepted := true];
                    onReject: [:a| self shouldNotImplement];
                    yourself.
        auth start: OsmoGSM.GSM48CMServiceReq new.
        self assert: accepted.
    ]

    testWrongInitialMessage [
        | auth rejected wait |

        Transcript nextPutAll: 'Going to send an initial message'; nl.

        wait := Semaphore new.
        auth := GSMNullAuthenticator new
                    onAccept: [:a | ^self error: 'This should not be accepted'];
                    onReject: [:a | self assert: a = auth. rejected := true. wait signal];
                    yourself.
        auth
            connection: nil;
            start: OsmoGSM.GSM48IdentityReq new.

        wait wait.
        self assert: rejected.
    ]
]
