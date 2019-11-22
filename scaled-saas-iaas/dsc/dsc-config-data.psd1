@{
    AllNodes =
    @(
        @{
            NodeName                        = '*'
            DriveLetter                     = "S"
            DriveLetterL                    = "L"
            PSDscAllowPlainTextPassword     = $true
        },
        @{
            NodeName                        = "solrnode" 
            Role                            = "solr"
            SetLocalVariableSet             = "Yes"
            PSDscAllowPlainTextPassword     = $true 
            Environment                     = "dev"
            DriveLetter                     = "S"
            DriveLetterL                    = "L"
            PackageDirPath                  = "C:\PackageDir"
            InstallIIS                      = "Yes"
            InstallJava                     = "Yes"
            Install7zip                     = "Yes"
            RebootAfterDSCComplete          = "Yes"
            InstallChrome                   = "No"
            UserID                          = "rufat.alizada"
            SubscriptionName                = "Microsoft Azure Enterprise"
            AzureStorage                    = "vccaerostor"
            DscContainerName                = "dsc"
            InstallAppDynamics              = "No"
            AddMachinesToDomain             = "No"
            InstallNotepadPlusPlus          = "No"
            OctopusURL                      = "http://octopus.uri"
            OctopusAPI                      = "API-VKJYSXGKJ3V5CYGR0XXNFAPDCQ"
            OctopusEnvironment              = "TEST-WPI"
         },
        @{
            NodeName                        = "solrnodeCloud" 
            Role                            = "solrcloud"
            SetLocalVariableSet             = "Yes"
            PSDscAllowPlainTextPassword     = $true 
            Environment                     = "nonenv"
            DriveLetter                     = "S"
            DriveLetterL                    = "L"
            PackageDirPath                  = "C:\PackageDir"
            InstallIIS                      = "No"
            InstallJava                     = "Yes"
            Install7zip                     = "Yes"
            RebootAfterDSCComplete          = "Yes"
            InstallChrome                   = "No"
            UserID                          = "rufat.alizada"
            SubscriptionName                = "Microsoft Azure Enterprise"
            AzureStorage                    = "vccaerostor"
            DscContainerName                = "dsc"
            InstallAppDynamics              = "No"
            AddMachinesToDomain             = "No"
            InstallNotepadPlusPlus          = "No"
            OctopusURL                      = "http://octopus.uri"
            OctopusAPI                      = "API-VKJYSXGKJ3V5CYGR0XXNFAPDCQ"
            OctopusEnvironment              = "TEST-WPI"

         },
        @{
            NodeName                        = "solrnodeJumbbox" 
            Role                            = "mgmt"
            SetLocalVariableSet             = "Yes"
            PSDscAllowPlainTextPassword     = $true 
            Environment                     = "nonenv"
            DriveLetter                     = "S"
            DriveLetterL                    = "L"
            PackageDirPath                  = "C:\PackageDir"
            InstallIIS                      = "No"
            InstallJava                     = "No"
            Install7zip                     = "No"
            RebootAfterDSCComplete          = "Yes"
            InstallChrome                   = "No"
            UserID                          = "rufat.alizada"
            SubscriptionName                = "Microsoft Azure Enterprise"
            AzureStorage                    = "vccaerostor"
            DscContainerName                = "dsc"
            InstallAppDynamics              = "No"
            AddMachinesToDomain             = "No"
            InstallNotepadPlusPlus          = "No"
            OctopusURL                      = "http://octopus.uri"
            OctopusAPI                      = "API-VKJYSXGKJ3V5CYGR0XXNFAPDCQ"
            OctopusEnvironment              = "TEST-WPI"

         }
    )
}
