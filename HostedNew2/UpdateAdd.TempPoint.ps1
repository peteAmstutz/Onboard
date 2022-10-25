<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.179
	 Created on:   	7/7/2020 4:51 PM
	 Created by:   	administrator
	 Organization: 	
	 Filename:     	UpdateAdd.ps1
	===========================================================================
	.DESCRIPTION
		Upate Additions Code added to address misc issues, like changes to AppSettings.config
#>

#region Get-JwtPwd
Function Get-JwtPwd
{
	$chars = "abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ0123456789".ToCharArray()
	$newPassword = ""
	0 .. 127 | ForEach { $newPassword += $chars | Get-Random }
	write $newPassword
}
#endregion Get-JwtPwd

#region function Install-Msi
function Install-Msi ($msiPath)
{
	$msiPath = '"' + $msiPath + '"'
	$psi = new-object System.Diagnostics.ProcessStartInfo
	$psi.RedirectStandardError = $true
	$psi.UseShellExecute = $false
	$psi.FileName = 'msiexec'
	$psi.Verb = "runas"
	$psi.Arguments = "	/i " + $msiPath + ' /quiet'
	$psi.WorkingDirectory = $runPath
	$s = [System.Diagnostics.Process]::Start($psi)
	$s.WaitForExit()
	if ($s.ExitCode -ne 0) { Throw "$msiPath install failed with error`'$($s.ExitCode)`'" }
}
#endregion function Install-Msi
$returnObj = New-Object PSCustomObject -Property @{ [string] 'Status' = ''; [string] 'Logdata' = ''; }
Try
{
	
<#	# Update Harland or JHKEY.key file
	$files = gci -path $($updateObj.WebSitePath) -file -recurse | where -FilterScript { $_.name -eq "harland.key" -or $_.name -eq 'JHKEY.key' -or $_.name -eq 'JHAKEY.key' }
	if ($files -ne $null)
	{
		$files |
		%{
			if ($_.name -eq "harland.key")
			{
				$parentFolder = $_.fullname | split-path -Parent
				Remove-Item $_.fullname
				copy-item "$global:ScriptDirectory\JHKEY.key" -Destination "$parentFolder\harland.key"
			}
			elseif ($_.name -eq "JHAKEY.key")
			{
				$parentFolder = $_.fullname | split-path -Parent
				Remove-Item $_.fullname
				copy-item "$global:ScriptDirectory\JHKEY.key" -Destination "$parentFolder\JHAKEY.key"
			}
			elseif ($_.name -eq "JHKEY.key") { copy-item "$global:ScriptDirectory\JHKEY.key" -Destination $_.fullname -Force }
		}
	}#>
	
	#region Update Web Config
	$date = ((get-date -UFormat %m-%d-%R).ToString()).replace(':', '-')
	$binding = (Get-WebSite $updateObj.Website).bindings.collection.bindinginformation
	if ($binding -like "*443*") { $newWebCfgPath = "$global:ScriptDirectory\SslWeb.config" }
	else { $newWebCfgPath = "$global:ScriptDirectory\NoSslWeb.config" }
	$webCfgPath = "$($updateObj.WebSitePath)\Web.config"
	[xml]$oldCfgXml = Get-Content $webCfgPath # Read the web.config file 
	$oldCfgXmlObj = Select-Xml -Xml $oldCfgXml -XPath ('//configuration/loggingConfiguration[@name=""]/listeners') # Navigate to logging Configuration in web.config file 
	$node = $oldCfgXmlObj.Node # Get listeners child node 
	$oldCfgLogFilePath = $node.add.fileName
	Rename-Item $webCfgPath -NewName "Web$date.config" -Force
	$content = Get-Content $newWebCfgPath
	$lineNumber = ($content | Select-String -SimpleMatch 'fileName=""').LineNumber
	$lineNumber--
	$content[$lineNumber] = "`tfileName=`"$oldCfgLogFilePath`""
	Set-Content -Value $content -Path "$($updateObj.WebSitePath)\Web.config"
	Write-Log -LogData "Web.Config update completed." -LogFilePath $updateObj.LogFilePath
	#endregion Update Web Config>
	
	#region Install Rewrite MSI
	if ((Get-Package | Where-Object -Property name -Like "*rewrite*") -eq $null)
	{
		Install-Msi -msiPath "$global:ScriptDirectory\rewrite_amd64.msi"
		Write-Log -LogData "Rewrite install complete" -LogFilePath $updateObj.LogFilePath
		cmd /c iisreset
	}
		#endregion Install Rewrite MSI
	
	#region DisableSamlTokenMessages
	#	$appConfigPath = "$($updateObj.WebSitePath)\AppSettings.config"
	#	if (!(Check-AppCfgKey -AppCfgPath $appConfigPath -key 'SpeedTestFilePath'))
	#	{
	#		Add-AppCfgNode -AppCfgPath $appConfigPath -key 'SpeedTestFilePath' -value 'C:\logs\50MB.zip'
	#	}
	#endregion DisableSamlTokenMessages
	
	#region DisableLogCsiJobTicket
	#	if ((Get-AppCfgValue -key 'LogCSiJobTicket' -AppCfgPath $appConfigPath) -eq 'true')
	#	{
	#		Change-AppCfgValue -key 'LogCSiJobTicket' -value 'false' -AppCfgPath $appConfigPath
	#	}
	#endregion DisableLogCsiJobTicket
	
	#region DeleteOldTxlFiles
	$numTxlDeleted = Delete-OldFiles -FolderPath c:\txl -FileExtension txl -Days 30 -Recurse Y
	#Write-Log -LogData "$numTxlDeleted txl files deleted." -LogFilePath $updateObj.LogFilePath
	#endregion DeleteOldTxlFiles
	
	#region EnableCacheControl
	#Invoke-Sqlcmd -ServerInstance $updateObj.SqlInstance  -Database $updateObj.DbName -Query "Update deposits.cachecontrol set enable = '1'"
	#endregion EnableCacheControl	
	
	#	#region Add-JwtPassword
	#	$appConfigPath = "$($updateObj.WebSitePath)\AppSettings.config"
	#	if ((Get-AppCfgValue -key 'JwtPassword' -AppCfgPath $appConfigPath) -eq $false)
	#	{
	#		Add-AppCfgNode -key 'JwtPassword' -AppCfgPath $appConfigPath -value (Get-JwtPwd) | Out-Null
	#	}
	#	#endregion Add-JwtPassword
	
	#	#region Add-DefaultWindowsTokenKey
	#	$appConfigPath = "$($updateObj.WebSitePath)\AppSettings.config"
	#	if ((Get-AppCfgValue -key 'DefaultWindowsTokenKey' -AppCfgPath $appConfigPath) -eq $false)
	#	{
	#		Add-AppCfgNode -key 'DefaultWindowsTokenKey' -AppCfgPath $appConfigPath -value 'aGVsbG9iYW5randlaHJvd2Vyd2lvZSBjd2lldWUgbHJpaHRsZXVyaGVqdHJpNzYzNjQyeG5jZzR1aXR5IHAyeGlvd2VbMnV1NGV0cm94IHU1Ny0zIDR0NDVwOXUgdHFbMzRpIHV0ODlpZXUgdA==' | Out-Null
	#	}
	#	#endregion Add-DefaultWindowsTokenKey
	
	#region Add AppSettings value.
	$key = 'LogMainStreetRequestsVerbose'
	$keyValue = 'true'
	$appConfigPath = "$($updateObj.WebSitePath)\AppSettings.config"
	if ((Get-AppCfgValue -key $key -AppCfgPath $appConfigPath) -eq $false)
	{
		$r = Add-AppCfgNode -key $key -AppCfgPath $appConfigPath -value $keyValue | Out-Null #ALWAYS ADD OUT-NULL or you will get weird errors.
		$r
	}
	#endregion Add AppSettings value.
	
	$returnObj.status = 'Complete'
	$returnObj.LogData = "Update Additions Complete."
	return $returnObj
}
Catch
{
	$returnObj.status = 'Failed'
	$returnObj.LogData = (Format-Message $_).full
	return $returnObj
}

