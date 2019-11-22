Configuration MSFT_xNotepadPlusPlus
{
    param
    (
		[string]$MajorVersion = "6",
		[string]$MinorVersion = "8.6",
		[string]$LocalPath = "$env:SystemDrive\Windows\DtlDownloads\npp." + $MajorVersion + "." + $MinorVersion + ".Installer.exe"
    )
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    xRemoteFile Downloader
    {
		Uri = "http://notepad-plus-plus.org/repository/" + $MajorVersion + ".x/" + $MajorVersion + "." + $MinorVersion + "/npp." + $MajorVersion + "." + $MinorVersion + ".Installer.exe"
		DestinationPath = $LocalPath
    }
	 
    Package Installer
    {
		Ensure = "Present"
		Path = $LocalPath
		Name = "Notepad++ " + $MajorVersion + "." + $MinorVersion
		ProductId = ''
		Arguments = "/S"
		DependsOn = "[xRemoteFile]Downloader"
    }
}