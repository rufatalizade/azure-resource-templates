Configuration GenericcV1
{

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration' 
    Import-DscResource -ModuleName 'xStorage'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'

   #$Cred = Get-AutomationPSCredential -Name "SomeCredentialAsset"
   #Write-Host $ConfigurationData.AllNodes.InstallSCCMAgent

    $SourcePath = "\\smb1.domain.net\sources\pkgs"
    $DestinationPath = "G:\Sources"
    $SCOMMGMTGroup = "mgmt1"
    $SCOMServer = "scom1.domain.net"
    $wid = Get-AutomationVariable -Name "WorkspaceID"
    $wkey = Get-AutomationVariable -Name "WorkspaceKey"



     node localhost {    

        xWaitforDisk Disk3 {
            DiskId = 3
            RetryIntervalSec = 60
            RetryCount = 5
        }
        xDisk GVolume {
            DiskId = 3
            DriveLetter = 'G'
            FSLabel = 'DATA'
            DependsOn = "[xWaitForDisk]Disk3"
        }

    Script MSMonitorAgentConfig {
                    GetScript = {
                        $mma = New-Object  object
                        Return @{
                            'obj'= $mma;
                        }

                    }
                    SetScript = {
                         start-sleep -Seconds 40

                    }
                    TestScript = {
                         return $false
                       }

                    DependsOn = "[Service]MSMonitorAgent"
                }
         }

        if ($AllNodes.InstallSCOMAgent -eq $true)
	     {

            File CopySCOM 
                {
                    Ensure = "Present" # Ensure the directory is Present on the target node.
                    Type = "Directory" # The default is File.
                    Recurse = $true # Recursively copy all subdirectories.
                    SourcePath = "$SourcePath\SCOMAgent"
                    DestinationPath = "$DestinationPath\SCOMAgent"
                    DependsOn = "[xDisk]GVolume"
                }

            Package SCOM 
                {
                    Ensure = "Present"
                    Path = "$DestinationPath\SCOMAgent\MOMAgent.msi"
                    Name = "Microsoft Monitoring Agent"
                    ProductId = "{EE0183F4-3BF8-4EC8-8F7C-44D3BBE6FDF0}"
                    Arguments = "USE_SETTINGS_FROM_AD=0 MANAGEMENT_GROUP=MGT MANAGEMENT_SERVER_DNS=`"$SCOMServer`" MANAGEMENT_SERVER_AD_NAME=`"$SCOMServer`" ACTIONS_USE_COMPUTER_ACCOUNT=1 USE_MANUALLY_SPECIFIED_SETTINGS=1 AcceptEndUserLicenseAgreement=1"
                    DependsOn = "[File]CopySCOM"
                }
            Service MSMonitorAgent 
                {
                    Name = "HealthService"
                    State = "Running"
                    DependsOn = "[Package]SCOM"
                }
            Script MSMonitorAgentConfig {
                    GetScript = {
                        $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
                        Return @{
                            'Managementgroups'= $mma.GetManagementGroups();
                        }

                    }
                    SetScript = {
                        $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
                        $mma.AddCloudWorkspace($($using:wid),$($using:wkey) )
                        $mma.ReloadConfiguration()
                        Restart-Service -Name "HealthService"

                    }
                    TestScript = {
                        $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
                        if (($mma.GetCloudWorkspaces() | select workspaceId).workspaceId -eq $($using:wid)) 
                                {return $true
                                    } else {
                                            return $false
                                                }
                       }

                    DependsOn = "[Service]MSMonitorAgent"
                }
         }

        if ($AllNodes.InstallSCCMAgent -eq $true)
	     {

            File CopySCCM 
                {
                    Ensure = "Present" # Ensure the directory is Present on the target node.
                    Type = "Directory" # The default is File.
                    Recurse = $true # Recursively copy all subdirectories.
                    SourcePath = "$SourcePath\SCCMAgent"
                    DestinationPath = "$DestinationPath\SCCMAgent"
                    DependsOn = "[xDisk]GVolume"
                }

            Package SCCM 
                {
                    Ensure = "Present"
                    Path = "$DestinationPath\SCCMAgent\ccmsetup.exe"
                    Name = "Configuration Manager Client"
                    ProductId = "{6343A6B8-D881-4B6C-AC85-2384F0B839BD}"
                    Arguments = 'SMSMP=https://SCCMP1.domain.net SMSSITECODE=P01'
                    DependsOn = "[File]CopySCCM"
                }

         }

        if ($AllNodes.InstallLAPS -eq $true)
	     {
        
                File CopyLAPS 
                {
                   Ensure = "Present" # Ensure the directory is Present on the target node.
                   Type = "Directory" # The default is File.
                   Recurse = $true # Recursively copy all subdirectories.
                   SourcePath = "$SourcePath\LAPS"
                   DestinationPath = "$DestinationPath\LAPS"
                   DependsOn = "[xDisk]GVolume"
                }
                Package LAPS 
                {
                    Ensure = "Present"
                    Path = "$DestinationPath\LAPS\LAPS_x64.msi"
                    Name = "Local Administrator Password Solution"
                    ProductId = "{EA8CB806-C109-4700-96B4-F1F268E5036C}"
                    Arguments = '/norestart'
                    DependsOn = "[File]CopyLAPS"
                }
        }


        if ($AllNodes.InstallJavaRuntime -eq $true)
        {

            File CopyJava 
                {
                   Ensure = "Present" # Ensure the directory is Present on the target node.
                   Type = "Directory" # The default is File.
                   Recurse = $true # Recursively copy all subdirectories.
                   SourcePath = "$SourcePath\Jre8u201"
                   DestinationPath = "$DestinationPath\Jre8u201"
                   DependsOn = "[xDisk]GVolume"
                }
            Package InstallJava
                {
                    Ensure = 'Present'
                    Name = "Java 8"
                    Path = "$DestinationPath\Jre8u201\jre-8u201-windows-x64.exe"
                    Arguments = "/s REBOOT=0 SPONSORS=0 REMOVEOUTOFDATEJRES=1 INSTALL_SILENT=1 AUTO_UPDATE=0 EULA=0 /l*v `"$DestinationPath\Jre8u201\JreInstall236888.log`""
                    ProductId = "26A24AE4-039D-4CA4-87B4-2F64180201F0"
                    DependsOn = "[File]CopyJava"
                }   
        }

        if ($AllNodes.InstallIIS -eq $true)
        {
                    WindowsFeature IIS 
                        { 
                            Ensure = "Present" 
                            Name = "Web-Server"
                        } 
                    WindowsFeature IISMgmtTools
                        {
                            Name = "Web-Mgmt-Tools"
                            Ensure = "Present"
                            DependsOn = "[WindowsFeature]IIS"
                        }     
                    WindowsFeature IISWebMgmtConsole
                        {
                            Name = "Web-Mgmt-Console"
                            Ensure = "Present"      
                            DependsOn = "[WindowsFeature]IIS"
                        }
                    WindowsFeature WebBasicAuth
                        {
                            Name = "Web-Basic-Auth"
                            Ensure = "Present"      
                            DependsOn = "[WindowsFeature]IIS"
                        }
                    WindowsFeature AspNet45  
                        {
                            Ensure = "Present"  
                            Name = "Web-Asp-Net45"  
                        }
        }
         

            Script extractEachPackage {

			    GetScript =  { @{ Result = "hash"} }

			    SetScript =  {
                                [System.Environment]::SetEnvironmentVariable("role", "$($using:AllNodes.role)", "Machine");
                                [System.Environment]::SetEnvironmentVariable("environment", "$($using:AllNodes.environment)", "Machine")
                             }	

			    TestScript = {$false}

		        }
        if ($AllNodes.role -eq 'default')
	     {
		    File installSspql
		    { 
			    Type = "Directory"
			    DestinationPath = "C:\examples" 
			    Ensure = "Present"
   		    }
         }


        if ($AllNodes.environment -eq 'prod')
	     {
		    File installSqsl
		    { 
			    Type = "Directory"
			    DestinationPath = "C:\envProdFolder" 
			    Ensure = "Present"
   		    }
         }



     }

}






