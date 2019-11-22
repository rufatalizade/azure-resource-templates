
  param (
  [string]$packageDir,
  [string]$environment
  )


$sslpassword             = "SlrselfsignCert"


$packageMetadataFileName = "$packageDir\PackagesMetadata\PackagesMetadata.json"


Set-Location $packageDir

$packageConfiguration =  (gc "$packageMetadataFileName" | convertfrom-json).$environment



function ScriptAsService ($serviceName, $solrPath,$solrHttpsCloudPath,$solrHttpCloudPath,$zklist,$zkPath,$port) {

if (-not(Test-Path $packageConfiguration.nssm.destinationPath))
    {
        $nssmFoldername = $([IO.Path]::GetFileNameWithoutExtension($($packageConfiguration.nssm.filename)))
        New-Item -path $packageConfiguration.nssm.destinationPath -ItemType Directory -force
        copy-item -Path  "$packageDir\$nssmFoldername\*" -Destination  $packageConfiguration.nssm.destinationPath -Force -Recurse
    }

        if ($solrPath)
            {
             &"$($packageConfiguration.nssm.destinationPath)\win64\nssm.exe" install "$serviceName" "$solrPath\bin\solr.cmd" "-f" "-p $port"
            }
            elseif ($solrHttpsCloudPath)
                {
                 &"$($packageConfiguration.nssm.destinationPath)\win64\nssm.exe" install  "$serviceName" "$($solrHttpsCloudPath)\bin\solr.cmd" "start" "-cloud" "-f" "-p $($port)" "-Dsolr.ssl.checkPeerName=false" "-z" ('\"'+"$($zklist)"+'\"')
                #Write-Host "$($solrCloudPath)\bin\solr start -cloud -p $($port) -z `"$($zklist)`"" 
                }
                 elseif ($solrHttpCloudPath)
                    {
                     &"$($packageConfiguration.nssm.destinationPath)\win64\nssm.exe" install  "$serviceName" "$($solrHttpCloudPath)\bin\solr.cmd" "start" "-cloud" "-f" "-p $($port)" "-z" ('\"'+"$($zklist)"+'\"')
                    #Write-Host "$($solrCloudPath)\bin\solr start -cloud -p $($port) -z `"$($zklist)`"" 
                    }
                    elseif ($zkPath)
                        {
                         &"$($packageConfiguration.nssm.destinationPath)\win64\nssm.exe" install "$serviceName" "$zkPath"
                        }    
}



function InitializeIndexes ($solrPath,$solrPort,$protocol) { 
  
    $indexesFoldername = $([IO.Path]::GetFileNameWithoutExtension($($packageConfiguration.initializeIdexes.filename)))
    $indexes =  Get-ChildItem  "$packageDir\$indexesFoldername\" 
    foreach ($index in $indexes)
            {
            copy-item $index.FullName -Destination "$solrPath\server\solr\" -Force -Recurse
            $indexName = $index.BaseName
            Start-Sleep -Seconds 3
            $url = "$($protocol)://localhost:$solrport/solr/admin/cores?action=CREATE&name=$indexName&instanceDir=$indexName&dataDir=data&config=solrconfig.xml&schema=schema.xml"
            Write-host $url 
            Write-host $index.BaseName
            Invoke-WebRequest $url -UseBasicParsing -Method Post | Out-Null
            }

}


function InitializeCloudIndexes ($configName,$solrPort,$protocol) { 
  
  #"sitecore_master_index",
$indexes =  "sitecore_core_index", `
"sitecore_web_index", `
"sitecore_master_index", `
"sitecore_marketingdefinitions_master", `
"sitecore_marketingdefinitions_web", `
"sitecore_marketing_asset_index_master", `
"sitecore_marketing_asset_index_web", `
"sitecore_testing_index", `
"sitecore_suggested_test_index", `
"sitecore_fxm_master_index", `
"sitecore_fxm_web_index", `
"social_messages_master", `
"social_messages_web"


    foreach ($index in $indexes)
            {
            Start-Sleep -Seconds 3
            $url = "$($protocol)://localhost:$solrPort/solr/admin/collections?action=CREATE&name=$($index)&numShards=1&replicationFactor=3&maxShardsPerNode=1&collection.configName=$($configName)"
            Invoke-WebRequest $url -UseBasicParsing -Method Post | Out-Null
            }

}


function ConfigureSolrSelfSignCert ($solrPath,$instanceName)  {

$localIp = (Get-NetIPAddress | ? {$_.InterfaceAlias -eq 'Ethernet' -and $_.PrefixLength -eq '24'}).ipaddress
				$cert  = New-SelfSignedCertificate -FriendlyName "$($env:COMPUTERNAME)-$($instanceName)" -DnsName  @($env:COMPUTERNAME,$localIp) -CertStoreLocation "cert:\LocalMachine" -NotAfter (Get-Date).AddYears(10)
				$store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root","LocalMachine"
				$store.Open("ReadWrite")
				$store.Add($cert)
				$store.Close()
				$cert | Remove-Item

				$cert      = Get-ChildItem Cert: -Recurse | where FriendlyName -eq "$($env:COMPUTERNAME)-$($instanceName)"
				$certStore = "$solrPath\server\etc\solr-ssl.keystore.pfx"
				$certPwd   = ConvertTo-SecureString -String "$sslpassword" -Force -AsPlainText
				$cert      | Export-PfxCertificate -FilePath $certStore -Password $certPwd | Out-Null

				
				
				$cfg    = Get-Content "$solrPath\bin\solr.in.cmd"
                $cfg    | Set-Content "$solrPath\bin\solr.in.cmd.old"	
				$newCfg = $cfg    | % { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$certStore" }
				$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=$sslpassword" }
				$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$certStore" }
				$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=$sslpassword" }
				$newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$localIp" }
				$newCfg | Set-Content "$solrPath\bin\solr.in.cmd"

                $jettySsl  = [xml](Get-Content "$solrPath\server\etc\jetty-ssl.xml")
                ($jettySsl.SelectNodes('//Configure').ChildNodes | where {$_.name -eq 'KeyStorePath'}).Property.default   = "$certStore"
                ($jettySsl.SelectNodes('//Configure').ChildNodes | where {$_.name -eq 'TrustStorePath'}).Property.default = "$certStore"
                ($jettySsl.SelectNodes('//Configure').ChildNodes | where {$_.name -eq 'KeyStorePassword'}).Env.default    = "$sslpassword"
                ($jettySsl.SelectNodes('//Configure').ChildNodes | where {$_.name -eq 'TrustStorePassword'}).Env.default  = "$sslpassword"
                $jettySsl.Save("$solrPath\server\etc\jetty-ssl.xml")


}

function ConfigureSolrcloudCert ($solrPath,$sslPath,$sslpassword)  {

$localIp = (Get-NetIPAddress | ? {$_.InterfaceAlias -eq 'Ethernet' -and $_.PrefixLength -eq '24'}).ipaddress
$p12path = (Get-ChildItem  "$sslPath\" -Filter "*.p12").fullname
Import-PfxCertificate -FilePath $p12path -CertStoreLocation Cert:\LocalMachine\Root -Password (ConvertTo-SecureString -AsPlainText -Force ('secret')) 

copy-item -Path  "$sslPath\*" -Destination "$solrPath\server\etc"  -Force -Recurse

				$cfg    = Get-Content "$solrPath\bin\solr.in.cmd"
                $cfg    | Set-Content "$solrPath\bin\solr.in.cmd.old"	
				$newCfg = $cfg    | % { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks" }
				$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=secret" }
				$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks" }
				$newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=$sslpassword" }
				$newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$($env:computername)" } #
				$newCfg | Set-Content "$solrPath\bin\solr.in.cmd"
}



function IgnoreSelfSignCert { 
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}


function WaitRemoteInstanceByPort ([object]$servers) {
$retryInSeconds = '60'
    foreach ($server in $servers)
        {
            $name = ($server -split ':')[0]
            $port = ($server -split ':')[1]
            while (!$connected) 
             {
                try {
                Start-Sleep -seconds $retryInSeconds
                Write-Output "checking $($name) with $($port)"
                    $Connected = [bool](Test-NetConnection -computername $($name) -Port $($port) -InformationLevel Quiet)
                    }
                        catch {
                            Write-Output "no response from $($name) with $($port), waiting more $($waitForMilliSeconds)sec"
                        }
                
            } 

            Write-output "connection to hostname $($name) with $($port) has established"
            rv connected -ea silentlycontinue
        }

Start-Sleep -Seconds 30
}


if ($packageConfiguration.solrSingleConfigure -eq 'true')
        {

        IgnoreSelfSignCert

            foreach ($solr in $packageConfiguration.solrSingle) 
                    
                    {


                    $foldername = $([IO.Path]::GetFileNameWithoutExtension($($solr.filename)))
                    New-Item -path $solr.destinationPath -ItemType Directory -force
                    copy-item -Path  "$packageDir\$foldername\*" -Destination  $solr.destinationPath -Force -Recurse

                    Start-Sleep -Seconds 30
                    if ($solr.useSSL -eq 'Yes')
                            {

                            ConfigureSolrSelfSignCert -solrPath $solr.destinationPath -instanceName $solr.instanceName
                                
                                ScriptAsService -serviceName $solr.instanceName -solrPath $solr.destinationPath -port $solr.sslPort
                                start-service $solr.instanceName
                                Start-Sleep -Seconds 30
                                InitializeIndexes -solrPath $solr.destinationPath $solr.sslPort  -protocol 'https'

                                    $ips=@()
                                    ($packageConfiguration.solrSingle.firewallAllowFrom | where {$_ -ne $null})|foreach {$ips+=$_}
                                    New-NetFirewallRule -DisplayName "$($solr.instanceName)" -RemoteAddress $ips  -Direction Inbound -LocalPort $solr.sslPort -Protocol TCP -Action Allow
                                    
                            }
                        
                        else { 
                                ScriptAsService -serviceName $solr.instanceName -solrPath $solr.destinationPath -port $solr.port 
                                start-service $solr.instanceName
                                Start-Sleep -Seconds 30
                                InitializeIndexes -solrPath $solr.destinationPath $solr.port -protocol 'http'

                                    $ips=@()
                                    ($packageConfiguration.solrSingle.firewallAllowFrom | where {$_ -ne $null})|foreach {$ips+=$_}
                                    New-NetFirewallRule -DisplayName "$($solr.instanceName)" -RemoteAddress $ips  -Direction Inbound -LocalPort $solr.port -Protocol TCP -Action Allow
                             }

                    }



        }



 function ConfigureSolrCloud ([object]$solr,[object]$allSolrsNodes,$zkList,$myid) {

        IgnoreSelfSignCert

                $foldername = $([IO.Path]::GetFileNameWithoutExtension($($solr.filename)))

                New-Item -path $solr.destinationPath -ItemType Directory -force
                copy-item -Path  "$packageDir\$foldername\*" -Destination  $solr.destinationPath -Force -Recurse
                    
                if ($solr.useSSL -eq 'Yes')
                        {
                        
                        $sslfoldername = $([IO.Path]::GetFileNameWithoutExtension($($solr.predefinedSslSolrcloudAccFileName)))

                        ConfigureSolrcloudCert -solrPath $solr.destinationPath -sslPath "$packageDir\$sslfoldername" -sslpassword 'secret'

                        $zklistConvertedToIP = $zkList
                        ($zkList -split ',') -replace ":.*" | % {$zklistConvertedToIP = $zklistConvertedToIP -replace $_,$(((Resolve-DnsName $_).Where{$_.Type -eq 'A'}).IpAddress)}

                        $zkclibat = "$($solr.destinationPath)\server\scripts\cloud-scripts\zkcli.bat" 
                        start  $zkclibat  -ArgumentList "-zkhost $zklist -cmd clusterprop -name urlScheme -val https"  -Wait -NoNewWindow
                        #&"$($solr.destinationPath)\server\scripts\cloud-scripts\zkcli.bat" -zkhost $zklist -cmd clusterprop -name urlScheme -val https

                        Start-Sleep -Seconds 3

                            ScriptAsService -serviceName $solr.instanceName -solrHttpsCloudPath $solr.destinationPath -port $solr.sslPort -zklist $zklist
                            Start-Sleep -Seconds 30
                            start-service $solr.instanceName
                           

                            $port = $solr.sslPort
                            $protocol = 'https'
                        }
                        
                          else { 
                                    ScriptAsService -serviceName $solr.instanceName -solrHttpCloudPath $solr.destinationPath -port $solr.port -zklist $zkList
                                    start-service $solr.instanceName
                                    Start-Sleep -Seconds 30


                                    $port = $solr.port
                                    $protocol = 'http'
                                }


        if ($solr.createConfigSet -eq 'yes' -and $($packageConfiguration.solrCloudConfigSet.initializeIndexesOnZkId) -eq $myid)
                    {
                    WaitRemoteInstanceByPort $allSolrsNodes

                        $ConfigsetForSitecoreFolderName  = $([IO.Path]::GetFileNameWithoutExtension($($packageConfiguration.solrCloudConfigSet.filename)))
                        copy-item -path "$packageDir\$ConfigsetForSitecoreFolderName" -destination "$($solr.destinationPath)\server\solr" -Recurse
                        
                        $zkclibat = "$($solr.destinationPath)\server\scripts\cloud-scripts\zkcli.bat" 
                        $configSetPath = "$($solr.destinationPath)\server\solr\$ConfigsetForSitecoreFolderName\conf"       
                        start  $zkclibat  -ArgumentList "-zkhost $zklist -cmd upconfig -confname ConfigsetForSitecore -confdir $configSetPath"  -Wait -NoNewWindow
                        #&"$($solr.destinationPath)\server\scripts\cloud-scripts\zkcli.bat" -zkhost $zklist -cmd upconfig -confname ConfigsetForSitecore -confdir "$($solr.destinationPath)\server\solr\$ConfigsetForSitecoreFolderName\conf"

                        Start-Sleep -Seconds 120

                            if ($($packageConfiguration.solrCloudConfigSet.createCollections -eq 'yes'))
                                {
                                    InitializeCloudIndexes -configName 'ConfigsetForSitecore' -solrPort $port -protocol $protocol
                                                         
                                }
                    }
 }



 if ($packageConfiguration.solrCloudConfigure -eq 'true')
        {

        Write-Output $_ 
        Start-Sleep -Seconds 2
    #[Environment]::SetEnvironmentVariable("ZOOKEEPER_HOME", "L:\zookeeper-3.4.10-1", [System.EnvironmentVariableTarget]::Machine)
    #[Environment]::SetEnvironmentVariable("Path", $env:Path + ";%ZOOKEEPER_HOME%\bin", [System.EnvironmentVariableTarget]::Machine)

        New-NetFirewallRule -DisplayName "AllowLocalSubnetInbound" -RemoteAddress 'LocalSubnet' -Action Allow

           foreach ($zoo in $packageConfiguration.zookeeper)
            {   
                $loopIndex           = $packageConfiguration.zookeeper.IndexOf($zoo)
                if ($($packageConfiguration.solrCloud[$loopIndex]).useSSL -eq 'yes'){$solrport = $($packageConfiguration.solrCloud[$loopIndex]).sslPort}
                    else{$solrport=$($packageConfiguration.solrCloud[$loopIndex]).port}

                $zookeeperFolderName = $([IO.Path]::GetFileNameWithoutExtension($($zoo.filename)))
                $zookeeperPath       = "$($zoo.destinationPath)"
                $instanceName        = "$($zoo.instanceName)"
                $instancePort        = "$($zoo.instancePort)"
                $zkInternalPort      = "$($zoo.zkInternalPort)"

                New-Item   -path $zookeeperPath -ItemType Directory -force
                copy-item  -Path "$packageDir\$zookeeperFolderName\*" -Destination  $zookeeperPath -Force -Recurse

                $zooConfig     =  New-Item -Path "$zookeeperPath\conf\zoo.cfg" -ItemType File 
                $newDataFolder =  New-Item -path "$zookeeperPath\data" -ItemType Directory -force
                $zooData       =  $newDataFolder.FullName.Replace('\','/')
                $myid          =  new-item -Path $newDataFolder.FullName -Name 'myid' -ItemType file
                $localZkId     =  ($zoo.nodes).($env:COMPUTERNAME)
                $localZkId   | add-content -path $myid

                "tickTime=2000"       | add-content -path $zooconfig
                "dataDir=$($zooData)" | add-content -path $zooconfig
                "clientPort=$($instancePort)" | add-content -path $zooconfig
                "initLimit=5"  | add-content -path $zooconfig
                "syncLimit=2"  | add-content -path $zooconfig

                $zklist   = @()
                $solrlist = @()
                $nodes = ($zoo.nodes|gm|where{$_.membertype -eq 'noteproperty'}).Name
                    foreach ($node in $nodes){
                        $servername = $node
                        $serverid   = (($zoo.nodes).$node)
                        $server     = "server.$($serverid)=$($servername):$($zkInternalPort)"
                        $server     | add-content -path $zooconfig
                        $zklist     = $zklist   + "$($servername):$($instancePort)"
                        $solrlist   = $solrlist + "$($servername):$($solrport)"
                    }

                $allZkNodes  = $zklist
                $zklistForSolrStartup = $zklist -join ','


                ScriptAsService -serviceName $instanceName -zkPath "$zookeeperPath\bin\zkServer.cmd"
                start-service $instanceName 
                Start-Sleep -Seconds 10


                WaitRemoteInstanceByPort $allZkNodes

                
                ConfigureSolrCloud -solr $($packageConfiguration.solrCloud[$loopIndex]) -zkList $zklistForSolrStartup -myid $localZkId -allSolrsNodes $solrlist


                    $ips=@()
                    ($zoo.firewallAllowFrom | where {$_ -ne $null})|foreach {$ips+=$_}
                    New-NetFirewallRule -DisplayName "$instanceName" -RemoteAddress $ips  -Direction Inbound -LocalPort $instancePort -Protocol TCP -Action Allow
            }
    


  }







