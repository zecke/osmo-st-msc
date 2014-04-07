"
 (C) 2011-2012 by Holger Hans Peter Freyther
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

OsmoGSM.GSM48MSG extend [
    dispatchMoCall: aCon [
        <category: '*OsmoMSC-Call'>
        aCon moUnknown: self.
    ]
]

OsmoGSM.GSM48CCConnectAck extend [
    dispatchMoCall: aCon [
        <category: '*OsmoMSC-Call'>
        aCon moConnectAck: self.
    ]
]

OsmoGSM.GSM48CCDisconnect extend [
    dispatchMoCall: aCon [
        <category: '*OsmoMSC-GSM'>
        aCon moDisconnect: self.
    ]
]

OsmoGSM.GSM48CCRelease extend [
    dispatchMoCall: aCon [
        <category: '*OsmoMSC-GSM'>
        aCon moRelease: self.
    ]
]

OsmoGSM.GSM48CCReleaseCompl extend [
    dispatchMoCall: aCon [
        <category: '*OsmoMSC-GSM'>
        aCon moReleaseCompl: self.
    ]
]

OsmoGSM.GSM48CCStatus extend [
    dispatchMoCall: aCon [
        <category: '*OsmoMSC-GSM'>
        aCon moStatus: self.
    ]
]

OsmoGSM.GSM48CCSetup extend [
    openTransactionOn: aCon sapi: aSapi [
        | tran |
        <category: '*OsmoMSC-GSM'>
        tran := (GSMMOCall on: aSapi with: self ti)
                    con: aCon;
                    yourself.
        aCon openTransaction: tran with: self.
    ]
]

