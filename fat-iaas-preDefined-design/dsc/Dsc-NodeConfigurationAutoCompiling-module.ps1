
function getInfraConfigData ($role,$environment) {
    $infraConfigData = (
        @{
            NodeName = 'nodeId0'
            Role = 'default'
            Environment = 'prod'
            InstallSCOMAgent = $true
            InstallSCCMAgent = $true
            InstallFramework35 = $true
            InstallIIS = $true
            InstallJavaRuntime = $true
            InstallChrome = $true
            InstallLAPS  = $true
            PSDscAllowPlainTextPassword = $True
            PSDscAllowDomainUser = $True
        },
        @{
            NodeName = 'nodeId1'
            Role = 'workgroup'
            Environment = 'prod'
            InstallSCOMAgent = $true
            InstallSCCMAgent = $true
            InstallFramework35 = $true
            InstallIIS = $true
            InstallJavaRuntime = $true
            InstallChrome = $true
            InstallLAPS  = $true
            PSDscAllowPlainTextPassword = $True
            PSDscAllowDomainUser = $True
        },
        @{
            NodeName = 'nodeId2'
            Role = 'frontEnd'
            Environment = 'acc'
            InstallSCOMAgent = $true
            InstallSCCMAgent = $true
            InstallFramework35 = $true
            InstallIIS = $true
            InstallJavaRuntime = $true
            InstallChrome = $true
            InstallLAPS  = $true
            PSDscAllowPlainTextPassword = $True
            PSDscAllowDomainUser = $True
        },
        @{
            NodeName = 'nodeId3'
            Role = 'backEnd'
            Environment = 'test'
            InstallSCOMAgent = $true
            InstallSCCMAgent = $true
            InstallFramework35 = $true
            InstallIIS = $true
            InstallJavaRuntime = $true
            InstallChrome = $true
            InstallLAPS  = $true
            PSDscAllowPlainTextPassword = $True
            PSDscAllowDomainUser = $True
        }
    )
    
    
    $infraConfigData = $infraConfigData | where {$_.Role -eq $role -and $_.Environment -eq $environment}
    $ConfigData = @{}
    $ConfigData.Add('AllNodes',$infraConfigData)
    return $ConfigData
    }
    
    $ConfigData = getInfraConfigData -role "default" -environment "prod"
    
    
    
    
    
    Import-AzAutomationDscConfiguration -SourcePath "SourcePath:\GenericcV1.ps1" `
    -ResourceGroupName "ResourceGroupName"  -AutomationAccountName "AutomationAccountName"  -Published -Force
    
    $CompilationJob = Start-AzAutomationDscCompilationJob -ResourceGroupName "ResourceGroupName" `
    -AutomationAccountName "AutomationAccountName"  -ConfigurationName 'GenericcV1' -ConfigurationData $ConfigData -Verbose
    
    
    while($CompilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null)
    {
        $CompilationJob = $CompilationJob | Get-AzAutomationDscCompilationJob
        Start-Sleep -Seconds 3
    }
    
    $nodeId = (Get-AzAutomationDscNode -AutomationAccountName "AutomationAccountName" -ResourceGroupName "ResourceGroupName" -Name "VMName").Id
    $nodeParams = @{
        NodeConfigurationName = "GenericV1.localhost"
        ResourceGroupName = "ResourceGroupName" 
        Id = $nodeId
        AutomationAccountName = "AutomationAccountName"
        Force = $true
    }
    $node = Set-AzAutomationDscNode @nodeParams
    
    
    
