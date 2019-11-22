Configuration DSCCoreConfiguration
{
  param (
  [string]$MachineName,
  [string]$role,
  [string]$packageToCopyUri,
  [string]$env
  )

if ($AllNodes.where{$_.role -eq $role -and $_.SetLocalVariableSet -eq 'Yes'}) {
$hash = $AllNodes.where{$_.role -eq $role}
for ($i=0;$i -le $hash.Keys.Length;$i++) {
if ($hash.Keys[$i] -ne $null) {
New-Variable -Name $hash.Keys[$i] -Value $hash.Values[$i] -ErrorAction SilentlyContinue
  }
 }
}


    Import-DscResource -ModuleName cAeroAzureCustomResources
    Import-DscResource -Module xWebAdministration
    Import-DscResource -module xChrome
    #Import-DscResource -Module xAzure      
    #Import-DscResource -Module xComputerManagement 
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DSCResource -ModuleName xNetworking
    Import-DSCResource -ModuleName xDisk
    Import-DscResource -ModuleName xPendingReboot
    # Dynamically find the applicable nodes from configuration data

    Node $MachineName
        {
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
            LocalConfigurationManager
                {
                    ConfigurationMode = "ApplyAndAutoCorrect"
                    ConfigurationModeFrequencyMins = 120 #must be a multiple of the RefreshFrequency and how often configuration is checked
                    RebootNodeIfNeeded = $true
                    ActionAfterReboot = 'ContinueConfiguration'
                    AllowModuleOverwrite = $true
                    DebugMode = 'All'
                }
            if ($env -ne 'dev' -and $env -ne 'test' -and $env -ne 'nonenv')
                {
                    xWaitforDisk AdditionalDisk1
                        {
                            DiskNumber = 2
                            RetryIntervalSec = 60
                        }
                    xDisk SVolume
                        {
                            DiskNumber = 2
                            DriveLetter = $AllNodes.where{$_.role -eq $role}.DriveLetter
                        }
                    xWaitforDisk AdditionalDisk2
                        {
                            DiskNumber = 3
                            RetryIntervalSec = 60
                        }
                    xDisk LVolume
                        {
                            DiskNumber = 3
                            DriveLetter = $AllNodes.where{$_.role -eq $role}.DriveLetterL
                        }
                }
            If($AllNodes.where{$_.role -eq $role}.InstallChrome -eq "Yes")
                {
                    MSFT_xChrome chrome 
                        {
                            Language = "en"
                            LocalPath = "$env:SystemDrive\Windows\DtlDownloads\GoogleChromeStandaloneEnterprise.msi"
                        }
                }
           If($AllNodes.where{$_.role -eq $role}.InstallJava -eq "Yes")
                {
                    xRemoteFile DownloadJava
                        {
                            Uri = "http://javadl.oracle.com/webapps/download/AutoDL?BundleId=236888_42970487e3af4f5aa5bca3f542482c60"
                            DestinationPath = "$env:SystemDrive\Windows\DtlDownloads\JRE8\JreInstall236888.exe"
                        }
                    Package InstallJava
                        {
                            Ensure = 'Present'
                            Name = "Java 8"
                            Path = "$env:SystemDrive\Windows\DtlDownloads\JRE8\JreInstall236888.exe"
                            Arguments = "/s REBOOT=0 SPONSORS=0 REMOVEOUTOFDATEJRES=1 INSTALL_SILENT=1 AUTO_UPDATE=0 EULA=0 /l*v `"$env:SystemDrive\Windows\DtlDownloads\JRE8\JreInstall236888.log`""
                            ProductId = "26A24AE4-039D-4CA4-87B4-2F64180201F0"
                            DependsOn = "[xRemoteFile]DownloadJava"
                        }
                    Environment setEnvJavaPath
                        {
                            Ensure = "Present"
                            Name = "JAVA_HOME"
                            Path = $true
                            Value = "C:\Program Files\Java\jre1.8.0_201"
                            DependsOn = "[Package]InstallJava"
                        }
                        
                }

           If($AllNodes.where{$_.role -eq $role}.Install7zip -eq "Yes")
                {
                    xRemoteFile Download7zip
                        {
                            Uri = "https://www.7-zip.org/a/7z1604-x64.msi"
                            DestinationPath = "$env:SystemDrive\Windows\DtlDownloads\7zip\7zip.msi"
                        }
                    Package Install7zip
                        {
                            Ensure = "Present"
                            Name = "7-Zip 16.04 (x64 edition)"
                            Path = "$env:SystemDrive\Windows\DtlDownloads\7zip\7zip.msi"
                            ProductId = '23170F69-40C1-2702-1604-000001000000'
                            Arguments = '/qn /norestart'
                            DependsOn = "[xRemoteFile]Download7zip"
                        }
                }
            If($AllNodes.where{$_.role -eq $role}.Role -eq "solr" -or $AllNodes.where{$_.role -eq $role}.Role -eq "solrcloud")
                {
                    xRemoteFile DownloadPackage
                        {
                            Uri = "$packageToCopyUri"
                            DestinationPath = "$env:SystemDrive\Windows\DtlDownloads\packageToCopyUri.zip"
                        }
	                File createDirForPackage
                        {
                            Type = 'Directory'
                            DestinationPath =  $AllNodes.where{$_.role -eq $role}.PackageDirPath
                            Ensure = "Present"
                            DependsOn = "[xRemoteFile]DownloadPackage"
                        }
                    xArchive extractPackage
                        {
                            Path        = "$env:SystemDrive\Windows\DtlDownloads\packageToCopyUri.zip"
                            Destination =  $AllNodes.where{$_.role -eq $role}.PackageDirPath
                            DestinationType = 'Directory'
                            CompressionLevel = "Optimal"
                            MatchSource = $true
                            DependsOn = "[File]createDirForPackage"
                        }
                    Script extractEachPackage {

			                GetScript =  { @{ Result = ((get-childitem -path $using:PackageDirPath -Directory).Length -eq (get-childitem -path $using:PackageDirPath -File -Filter "*.zip").Length) } }

			                SetScript =  {
                                           get-childitem -path $using:PackageDirPath -File  -Filter "*.zip" | % { Expand-Archive -Path $_.fullname -DestinationPath "$using:PackageDirPath\$($_.basename)"}
                                           Remove-Item -Path "$using:PackageDirPath\*" -Filter "*.zip"  -Confirm:$false
			                             }	

			                TestScript = {(get-childitem -path $using:PackageDirPath -Directory).Length -eq (get-childitem -path $using:PackageDirPath -File -Filter "*.zip").Length}
		                }
                    Environment setEnvOpenSSLPath
                        {
                            Ensure = "Present"
                            Name = "Path"
                            Path = $true
                            Value = "C:\Program Files (x86)\OpenSSL"
                        }
                }
            If($AllNodes.where{$_.role -eq $role}.InstallIIS -eq "Yes")
                {
                    # Install IIS
                    WindowsFeature IIS 
                        { 
                            Ensure = "Present" 
                            Name = "Web-Server"
                        } 
                    # Install IIS managment tool
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
                    # Install the ASP .NET 4.5 role 
                    WindowsFeature AspNet45  
                        {
                            Ensure = "Present"  
                            Name = "Web-Asp-Net45"  
                        }
                    WindowsFeature AspNet35  
                        {  
                            Ensure = "Present"  
                            Name = "NET-FRAMEWORK-CORE"  
                        }
                    xWebsite Remove_default_site  
                        { 
                            Ensure          = "Absent" 
                            Name            = "Default Web Site"  
                            PhysicalPath    = "$Env:SystemDrive\inetpub\wwwroot" 
                        }
                }
            If($AllNodes.where{$_.role -eq $role}.RebootAfterDSCComplete -eq "Yes")
                {
                    Script Reboot
                        {
                            TestScript = {
                                return (Test-Path HKLM:\SOFTWARE\MyMainKey\RebootKey)
                            }
                            SetScript = {
                                New-Item -Path HKLM:\SOFTWARE\MyMainKey\RebootKey -Force
                                 $global:DSCMachineStatus = 1 

                            }
                            GetScript = { return @{result = 'result'}}
                            
                        }
                    xPendingReboot Reboot1
                        {
                            Name = ‘RestartMachine’
                            DependsOn = '[Script]Reboot'
                        }

                }
        }
}