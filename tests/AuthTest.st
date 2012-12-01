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
    <comment: 'I smoke-test the null authenticator and that it
    fires an accept callback right away.'>

    testImmediateAccept [
        | auth accepted |
        auth := GSMNullAuthenticator new
                    onAccept: [:a| self assert: a = auth. accepted := true];
                    onReject: [:a| self shouldNotImplement];
                    yourself.
        auth start: nil.
        self assert: accepted.
    ]
]

Object subclass: GSMProcessorMockBase [
    | auth dict |

    GSMProcessorMockBase class >> initWith: anAuth [
        ^ self new
            instVarNamed: #auth put: anAuth;
            instVarNamed: #dict put: Dictionary new;
            yourself.
    ]

    addInfo: aName value: aValue [
        dict at: aName put: aValue.
    ]

    getInfo: aName [
        ^ dict at: aName
    ]

    srcRef [
        ^ 1
    ]

    takeLocks: aBlock [
        aBlock value
    ]
]

GSMProcessorMockBase subclass: GSMProcessorMockForAuthCheat [
    nextPutData: aData [
        "Ignore the data for now. Should be a identity request"
        OsmoDispatcher dispatchBlock: [
            | msg |

            "Reply with a wrong identity response"
            msg := OsmoGSM.GSM48IdentityResponse new.
            msg mi imei: '234324234234'.
            auth onData: msg.]
    ]
]

GSMProcessorMockBase subclass: GSMProcessorMockForAuthIMSI [
    usedIMSI [
        ^ '234324234234'
    ]

    nextPutData: aData [
        "Ignore the data for now. Should be a identity request"
        OsmoDispatcher dispatchBlock: [
            | msg |

            "Reply with a wrong identity response"
            msg := OsmoGSM.GSM48IdentityResponse new.
            msg mi imsi: self usedIMSI.
            auth onData: msg.]
    ]
]

GSMProcessorMockBase subclass: GSMProcessorMockForAuthTimeout [
    nextPutData: aData [
        "Do nothing"
    ]
]

TestCase subclass: AuthTestIdentity [
    <comment: 'I test various aspects of the IMSI requestor.'>

    testWrongResponse [
        | auth rejected wait |

        Transcript nextPutAll: 'Going to send a wrong response leading to an exception.'; nl.

        wait := Semaphore new.
        auth := GSMIdentityAuthenticator new
                    onAccept: [:a | ^self error: 'This should not be accepted'];
                    onReject: [:a | self assert: a = auth. rejected := true. wait signal];
                    yourself.
        auth
            connection: (GSMProcessorMockForAuthCheat initWith: auth);
            start: nil.

        wait wait.
        self assert: rejected.
    ]

    testTimeout [
        | auth rejected wait |
        wait := Semaphore new.
        auth := GSMIdentityAuthenticator new
                    onAccept: [:a | ^self error: 'This should not be accepted'];
                    onReject: [:a | self assert: a = auth. rejected := true. wait signal];
                    yourself.
        auth
            connection: (GSMProcessorMockForAuthTimeout initWith: auth);
            start: nil.

        wait wait.
        self assert: rejected.
    ]

    testIMSI [
        | auth accept wait |
        wait := Semaphore new.
        auth := GSMIdentityAuthenticator new
                    onAccept: [:a | self assert: a = auth. accept := true. wait signal];
                    onReject: [:a | ^self error: 'This should not be rejected'];
                    yourself.
        auth
            connection: (GSMProcessorMockForAuthIMSI initWith: auth);
            start: nil.

        wait wait.
        self assert: accept.
        self assert: (auth connection getInfo: 'IMSI') = auth connection usedIMSI.
    ]
]
