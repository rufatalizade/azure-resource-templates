#Installs the specified version of Notepad++.

Configuration Sample_InstallNotepadPlusPlus
{
    param
    (
		
	[Parameter(Mandatory)]
	$MajorVersion,
		
    [Parameter(Mandatory)]
	$MinorVersion		
		
    )
	
	Import-DscResource -module xNotepadPlusPlus
	
	MSFT_xNotepadPlusPlus notepadplusplus
	{
	    MajorVersion = $MajorVersion
		MinorVersion = $MinorVersion
	}
}