function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

$script:updateversion = Get-ScriptDirectory | Split-Path -Parent | Split-Path -Parent | Split-Path -Leaf

#[string]$ScriptDirectory = Get-ScriptDirectory
#(gci -directory "C:\DepositsUpdateHosted\2020.3.5.0\UpdateCode\HostedUpdates")  | Split-Path -Parent

#Split-Path -Path "C:\DepositsUpdateHosted\2020.3.5.0\UpdateCode\HostedUpdates" | Split-Path -Parent | Split-Path -Leaf