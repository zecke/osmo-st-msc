PackageLoader fileInPackage: 'OsmoLogging'.

Osmo.LogArea subclass: LogAreaBSC [
    <category: 'osmo-msc-logging'>
    LogAreaBSC class >> areaName [ ^ #bsc ]
    LogAreaBSC class >> areaDescription [ ^ 'BSC Connectivty' ]
    LogAreaBSC class >> default [
        ^ self new
            enabled: true;
            minLevel: Osmo.LogLevel debug;
            yourself
    ]
]

Osmo.LogArea subclass: LogAreaHLR [
    <category: 'osmo-msc-logging'>
    LogAreaHLR class >> areaName [ ^ #hlr ]
    LogAreaHLR class >> areaDescription [ ^ 'HLR work' ]
    LogAreaHLR class >> default [
        ^ self new
            enabled: true; minLevel: Osmo.LogLevel debug; yourself.
    ]
]

Osmo.LogArea subclass: LogAreaVLR [
    <category: 'osmo-msc-logging'>
    LogAreaVLR class >> areaName [ ^ #vlr ]
    LogAreaVLR class >> areaDescription [ ^ 'VLR work' ]
    LogAreaVLR class >> default [
        ^ self new
            enabled: true; minLevel: Osmo.LogLevel debug; yourself.
    ]
]

Osmo.LogArea subclass: LogAreaMSC [
    <category: 'osmo-msc-logging'>
    LogAreaMSC class >> areaName [ ^ #msc ]
    LogAreaMSC class >> areaDescription [ ^ 'MSC work' ]
    LogAreaMSC class >> default [
        ^ self new
            enabled: true; minLevel: Osmo.LogLevel debug; yourself.
    ]
]
