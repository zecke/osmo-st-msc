"
Copyright (C) 2012 Holger Hans Peter Freyther
Configure and start a MSC
"

"Load the MSC code"
PackageLoader fileInPackage: #OsmoMSC.

"Fix some defaults in the openbsc"
OsmoMSC.GSMProcessor class extend [
    createAssignment: aMul timeslot: aTs [
        | ass |
        <category: 'audio-connect'>
        ass := IEMessage initWith: GSM0808Helper msgAssRequest.
        ass
            addIe: ((GSM0808ChannelTypeIE
                    initWith: GSM0808ChannelTypeIE speechSpeech
                    audio: GSM0808ChannelTypeIE chanSpeechFullPref)
                        audioCodecs: {GSM0808ChannelTypeIE speechFullRateVersion1};
                        yourself);
            addIe: (GSM0808CICIE initWithMultiplex: aMul timeslot: aTs).
        ^ ass
    ]
]

OsmoMSC.MSCApplication extend [
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
]

"Now start the application"
Eval [
    | msc |
    msc := OsmoMSC.MSCApplication new.
    msc config
        bscIP: '0.0.0.0';
        bscPort: 5000;
        sipIP: '127.0.0.1'.
    msc bscConfig
        addBSC: '127.0.0.1' withName: 'test1' andLac: 4711 sendOsmoRSIP: true;
        addBSC: '10.240.240.1' withName: 'test2' andLac: 4712 sendOsmoRSIP: true.

    "Start processing now"
    msc returnedFromSnapshot.

    Smalltalk at: #MSC put: msc.
]
