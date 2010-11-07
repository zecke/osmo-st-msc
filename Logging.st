PackageLoader fileInPackage: 'OsmoLogging'.

Osmo.LogArea subclass: LogAreaBSC [
    LogAreaBSC class >> areaName [ ^ #bsc ]
    LogAreaBSC class >> areaDescription [ ^ 'BSC Connectivty' ]
    LogAreaBSC class >> default [
        ^ self new
            enabled: true;
            minLevel: Osmo.LogLevel debug;
            yourself
    ]
]
