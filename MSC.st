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

Object subclass: MSCConfig [
    | ip port |

    bscIP: aIP     [ ip := aIP ]
    bscPort: aPort [ port := aPort ]

    bscIP   [ <category: 'accessing'> ^ ip ]
    bscPort [ <category: 'accessing'> ^ port ]
]

Object subclass: MSCBSCConnectionHandler [
    | msc connections |

    <comment: 'I take incoming connections, find a handler for them and
    will register them. I will be passed to the BSCListener'>

    MSCBSCConnectionHandler class >> initWith: aMSC [
        ^ self new
                instVarNamed: #msc put: aMSC; yourself
    ] 

    connections [ ^ connections ifNil: [connections := OrderedCollection new]]

    setupConnection: aConnection on: aConfig [
        | bsc |
        self logNotice: 'BSC-Socket: New Connection for lac', (aConfig lac asString)
             area: #bsc.

        "Create the BSC first and then assume it is present"
        [
            bsc := BSCIPAConnection createOn: aConnection withConfig: aConfig.
        ] on: Exception do: [:ex |
            self logError: 'BSC: Creating a handler failed.' area: #bsc.
            ex printNl.
            aConnection close.
            ^ false
        ].


        [
            [[
                aConfig connected: true.
                self connections add: bsc.
                bsc process. 
            ] on: SystemExceptions.EndOfStream do: [:ex |
                aConfig connected: false.
                self logNotice: 'BSC disconnected for lac', (aConfig lac asString)
                     area: #bsc.
            ] on: Exception do: [:ex |
                self logError: 'Unexpected exception for lac', (aConfig lac asString)
                    area: #bsc.
            ]] ensure: [
                self logNotice: 'BSC being disconnected' area: #bsc. 
                bsc terminateAll.
                self connections remove: bsc ifAbsent: [
                    self logError: 'BSC was never added?' area: #bsc].

                aConfig connected: false.
                aConnection close.
            ].
        ] fork.  
    ]

    newConnection: aConnection [
        | peer |
        <category: 'handling'>

        peer := aConnection remoteAddress.
        msc bscConfig bscList do: [:each |
            each peer = peer ifTrue: [
                each connected ifTrue: [
                    self logError: 'BSC-Socket: Still connected.' area: #bsc.
                    aConnection close.
                    ^ false
                ].

                self setupConnection: aConnection on: each.
                ^ true
            ].
        ]
    ]
]

Object subclass: MSCApplication [
    | hlr vlr config bscListener bscConfig bscConHandler |
    <comment: 'I am a MSC as I have the VLR/HLR and other instances'>

    hlr [ ^ hlr ifNil: [HLRLocalCollection new]]
    vlr [ ^ vlr ifNil: [VLRLocalCollection new]]

    config [ ^ config ifNil: [config := MSCConfig new]]
    bscConfig [ ^ bscConfig ifNil: [bscConfig := BSCConfig new]]
    bscConHandler [ ^ bscConHandler ifNil: [bscConHandler := MSCBSCConnectionHandler initWith: self]]

    serveBSC [
        "I will start to listen for BSCs"
        bscListener ifNotNil: [bscListener stop.].
        bscListener := BSCListener
                        initWith: config bscIP
                        port: config bscPort
                        handler: self bscConHandler.
        bscListener serve.
    ]


    MSCApplication class >> startExample [
        | msc |

        msc := MSCApplication new.
        msc config
            bscIP: '127.0.0.1';
            bscPort: 5000.
        msc bscConfig
            addBSC: '127.0.0.1' withName: 'test' andLac: 4711.

        msc logNotice: 'Serving BSCs now' area: #msc.
        [msc serveBSC. 'MSC has exited' printNl] fork.

        ^ msc.
    ]
]
