PackageLoader fileInPackage: 'OsmoSIP'.

Eval [
    FileStream
        fileIn: 'src/Logging.st';
        fileIn: 'src/VLR.st';
        fileIn: 'src/HLR.st';
        fileIn: 'src/BSCConfig.st';
        fileIn: 'src/BSCListener.st';
        fileIn: 'src/BSCSCCPHandler.st';
        fileIn: 'src/auth/GSMAuthenticatorBase.st';
        fileIn: 'src/auth/GSMIdentityAuthenticator.st';
        fileIn: 'src/auth/GSMNullAuthenticator.st';
        fileIn: 'src/GSMProcessor.st';
        fileIn: 'src/call/Extensions.st';
        fileIn: 'src/call/GSMMOCall.st';
        fileIn: 'src/call/SIPMTCall.st';
        fileIn: 'src/GSMLURequest.st';
        fileIn: 'src/GSMCMServiceRequest.st';
        fileIn: 'src/GSMEmergencySetup.st';
        fileIn: 'src/BSCIPAConnection.st';
        fileIn: 'src/PagingManager.st';
        fileIn: 'src/MSC.st'.

"
"
]
