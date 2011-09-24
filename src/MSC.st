"
 (C) 2010-2011 by Holger Hans Peter Freyther
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
    <category: 'MSC-IP'>
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
            [[
                aConfig connected: true.
                self connections add: bsc.
                bsc process. 
            ] on: SystemExceptions.EndOfStream do: [:ex |
                aConfig connected: false.
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
    <comment: 'I am a MSC as I have the VLR/HLR and other instances'>

    hlr [ ^ hlr ifNil: [HLRLocalCollection new]]
    vlr [ ^ vlr ifNil: [VLRLocalCollection new]]

    config [ ^ config ifNil: [config := MSCConfig new]]
    bscConfig [ ^ bscConfig ifNil: [bscConfig := BSCConfig new]]
    bscConHandler [ ^ bscConHandler ifNil: [bscConHandler := MSCBSCConnectionHandler initWith: self]]

    mgcpCallAgent [
        <category: 'MGCP-Audio'>
        ^ mgcp ifNil: [
            mgcp := (Osmo.MGCPCallAgent startOn: config bscIP)
                start;
                yourself]
    ]

    sipGateway [
        <category: 'SIP-Audio'>
        ^ sip ifNil: [ | transport |
            transport := Osmo.SIPUdpTransport
                            startOn: self config sipIP port: self config sipPort.
            sip := Osmo.SIPUserAgent createOn: transport.
            transport start.
            sip]
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
            addBSC: '127.0.0.1' withName: 'test' andLac: 4711.

        "Make sure MGCP is running"
        msc mgcpCallAgent.

        "Make sure we handle SIP"
        msc sipGateway.

        msc logNotice: 'Serving BSCs now' area: #msc.
        [msc serveBSC. 'MSC has exited' printNl] fork.

        ^ msc.
    ]
]
