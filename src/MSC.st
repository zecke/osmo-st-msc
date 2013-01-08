"
 (C) 2010-2013 by Holger Hans Peter Freyther
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
    fileInPackage: 'OsmoMGCP';
    fileInPackage: 'OsmoSIP'.

Object subclass: MSCConfig [
    | ip port mgcp sip_ip sip_port |

    <category: 'OsmoMSC-MSC'>
    <comment: 'I contain a very simple MSC config for IP based BSCs'>

    bscIP: aIP [
        <category: 'config'>
        ip := aIP
    ]

    bscIP [
        <category: 'accessing'>
        ^ ip
    ]

    bscPort: aPort [
        <category: 'config'>
        port := aPort
    ]

    bscPort [
        <category: 'accessing'>
        ^ port
    ]

    mgcpIP: aIP [
        <category: 'config'>
        mgcp := aIP
    ]

    mgcpIP [
        <category: 'accessing'>
        ^ mgcp ifNil: [ip]
    ]

    sipIP: aIP [
        <category: 'config'>
        sip_ip := aIP
    ]

    sipIP [
        <category: 'accessing'>
        ^ sip_ip ifNil: [ip]
    ]

    sipPort: aPort [
        <category: 'config'>
        sip_port := aPort
    ]

    sipPort [
        <category: 'accessing'>
        ^ sip_port ifNil: [5061]
    ]
]

Object subclass: MSCBSCConnectionHandler [
    | msc connections |

    <category: 'OsmoMSC-MSC'>
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
            bsc := BSCIPAConnection createOn: aConnection withConfig: aConfig msc: msc.
        ] on: Exception do: [:ex |
            ex logException: 'BSC: Creating a handler failed.' area: #bsc.
            aConnection close.
            ^ false
        ].


        [
            Processor activeProcess name: 'MSCBSCConnectionHandler(%1)' % {aConfig lac}.

            [[
                aConfig connection: bsc.
                self connections add: bsc.
                bsc process. 
            ] on: SystemExceptions.EndOfStream do: [:ex |
                aConfig connection: nil.
                self logNotice: 'BSC disconnected for lac: %1' % {aConfig lac}
                     area: #bsc.
            ] on: Exception do: [:ex |
                self logError: 'Unexpected exception for lac: %1' % {aConfig lac}
                    area: #bsc.
                thisContext backtraceOn: Transcript.
            ]] ensure: [
                self logNotice: 'BSC being disconnected for lac: %1' % {aConfig lac}
                    area: #bsc. 
                bsc terminateAll.
                self connections remove: bsc ifAbsent: [
                    self logError: 'BSC was never added on lac: %1?' % {aConfig lac}
                        area: #bsc].

                aConfig connection: nil.
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
                    self logError: 'BSC-Socket: Still connected for lac: %1' % {each lac}
                            area: #bsc.
                    aConnection close.
                    ^ false
                ].

                self setupConnection: aConnection on: each.
                ^ true
            ].
        ].

        self logError: 'BSC-Socket: Unknown connection from %1' % {peer} area: #bsc.
        aConnection close.
    ]
]

Object subclass: MSCApplication [
    | hlr vlr config bscListener bscConfig bscConHandler mgcp sip |

    <category: 'OsmoMSC-MSC'>
    <comment: 'I am a MSC as I have the VLR/HLR and other instances'>

    MSCApplication class >> new [
        <category: 'creation'>
        ^ super new
            initialize;
            yourself
    ]

    initialize [
        <category: 'creation'>
        ObjectMemory addDependent: self.
    ]

    update: aSymbol [
        <category: 'initialize'>

        "We need to re-initialize the sockets and state"
        aSymbol = #returnFromSnapshot ifTrue: [
            self returnedFromSnapshot.
        ]
    ]


    hlr [ ^ hlr ifNil: [HLRLocalCollection new]]
    vlr [ ^ vlr ifNil: [VLRLocalCollection new]]

    config [ ^ config ifNil: [config := MSCConfig new]]
    bscConfig [ ^ bscConfig ifNil: [bscConfig := BSCConfig new]]
    bscConHandler [ ^ bscConHandler ifNil: [bscConHandler := MSCBSCConnectionHandler initWith: self]]

    returnedFromSnapshot [
        <category: 'resume'>

        mgcp isNil ifFalse: [
            mgcp start
        ].

        "Stop the UDP processing and create a new transport. We might need
        to do this in an atomic operation."
        sip isNil ifFalse: [|old transport|
            old := sip transport.
            old stop.
            transport := self newSipTransport.
            transport start.
            sip transport: transport].

        "Make sure MGCP is running"
        self mgcpCallAgent.

        "Make sure we handle SIP"
        self sipGateway.

        self logNotice: 'Serving BSCs now' area: #msc.
        [
            Processor activeProcess name: 'BSC Listener'.
            self serveBSC. 'MSC has exited' printNl] fork.
    ]

    mgcpCallAgent [
        <category: 'MGCP-Audio'>
        ^ mgcp ifNil: [
            mgcp := (Osmo.MGCPCallAgent startOn: config bscIP)
                start;
                yourself]
    ]

    newSipTransport [
        <category: 'private'>
        ^ Osmo.SIPUdpTransport
              startOn: self config sipIP port: self config sipPort.
    ]

    sipGateway [
        <category: 'SIP-Audio'>
        ^ sip ifNil: [ | transport |
            transport := self newSipTransport.
            sip := Osmo.SIPUserAgent createOn: transport.
            transport start.
            sip]
    ]

    selectAudioRouteForEmergency: aCon leg: aLeg [
        ^ (SIPMTCall
            fromUser: 'sip:1000@sip.zecke.osmocom.org'
            host: '127.0.0.1'
            port: 5060
            to: 'sip:911@127.0.0.1'
            on: self sipGateway)
            remoteLeg: aLeg;
            yourself
    ]


    selectAudioRoute: aCon plan: aPlan leg: aLeg [
        | nr |
        "TODO: Very simple and hardcoded rule"
        nr := aPlan number.

        "No number, let us return"
        nr isEmpty ifTrue: [^nil].

        "No special number"
        nr first = $* ifFalse: [^nil].


        ^ (SIPMTCall
            fromUser: 'sip:1000@sip.zecke.osmocom.org'
            host: '127.0.0.1'
            port: 5060
            to: 'sip:1%1@127.0.0.1' % {nr allButFirst}
            on: self sipGateway)
            remoteLeg: aLeg;
            yourself
    ]

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
            bscIP: '0.0.0.0';
            bscPort: 5000;
            sipIP: '127.0.0.1'.
        msc bscConfig
            addBSC: '127.0.0.1' withName: 'test1' andLac: 4711 sendOsmoRSIP: true;
            addBSC: '10.240.240.1' withName: 'test2' andLac: 4712 sendOsmoRSIP: true.

        msc returnedFromSnapshot.
        ^ msc.
    ]
]
