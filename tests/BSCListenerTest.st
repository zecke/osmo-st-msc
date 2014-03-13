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

TestCase subclass: BSCListenerTest [
    <category: 'OsmoMSC-Tests'>
    <comment: 'Test some basic socket functionality'>

    testListenAndStop [
        | listener res |
        listener := BSCListener initWith: '127.0.0.1' port: 9245 handler: nil.

        'Will attempt to stop the connection' printNl.
        [(Delay forSeconds: 2) wait. listener stop] fork.
        res := listener serve.
        self deny: res.

        "Test that it will work again"
        'Will attempt to stop the connection2' printNl.
        listener start.
        [(Delay forSeconds: 2) wait. listener stop] fork.
        res := listener serve.
        self deny: res.
    ]

    testListenOnDeadSocket [
        | listener res |
        listener := BSCListener initWith: '127.0.0.1' port: 9245 handler: nil.
        listener stop.
        res := listener serve.
        self deny: res.
    ]
]
