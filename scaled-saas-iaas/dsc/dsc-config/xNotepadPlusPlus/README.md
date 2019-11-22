# xNotepadPlusPlus

The **xNotepadPlusPlus** module is a part of the Windows PowerShell Desired State Configuration (DSC) Resource Kit, which is a collection of DSC Resources produced by the PowerShell Team.
This module contains the **MSFT_xNotepadPlusPlus** resource.
The **MSFT_xNotepadPlusPlus** DSC Resource allows you to install the latest version of Notepad++.

**All of the resources in this module are provided AS IS, and are not supported through any Microsoft standard support program or service. The "x" prefix in the module name stands for "experimental," which means that these resources will be fix-forward and monitored by the module owner(s).**

## Installation

To install **xNotepadPlusPlus** PowerShell DSC module:

*   Unzip the content under the `$env:ProgramFiles\WindowsPowerShell\Modules` folder
*   **OR** Run `Install-Module -Name xNotepadPlusPlus` from an administrative PowerShell prompt

To confirm installation:  

*   Run `Get-DSCResource -Module xNotepadPlusPlus` to see that `MSFT_xNotepadPlusPlus` is among the DSC Resources listed  
*   Run the `Get-Module -ListAvailable -Name xNotepadPlusPlus` command to verify that the `xNotepadPlusPlus` DSC module is listed

## Requirements

This module requires the latest version of PowerShell (v4.0, which ships in Windows 8.1 or Windows Server 2012R2).
To easily use PowerShell 4.0 on older operating systems, [install WMF 4.0](http://www.microsoft.com/en-us/download/details.aspx?id=40855).
Please read the installation instructions that are present on both the download page and the release notes for WMF 4.0.

## Description

The `xNotepadPlusPlus` module contains the `MSFT_xNotepadPlusPlus` DSC Resource. This DSC Resource allows you to install the latest version of NOtepad++.

## Details

The **MSFT_xNotepadPlusPlus** DSC Resource has following optional properties:

*  **MajorVersion**: Specify the major veriosn of the software to be installed. Default it is 6.
*  **MinorVersion**: Specify the minor veriosn of the software to be installed. Default it is 6.8.

## Versions

### 1.0.0.0

*   Initial release with the following resources 
    *   MSFT_xNotepadPlusPlus 

## Examples

### Install the Notepad++ editor

Install the latest Notepad++ editor.

```
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
```

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).
