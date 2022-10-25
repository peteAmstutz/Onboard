<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
	 Created on:   	3/31/2018 6:51 PM
	 Created by:   	pamstutz
	 Organization: 	
	 Filename:     	UpdateWebsite.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

function Backup-Website($BackupFolder)
{
	If (Test-path $backupFolder) { Throw "Backup Path $backupFolder already exists" }
	Copy-item -Recurse $updateObj.WebSitePath -Destination $backupFolder
	Write-Log -LogData "Website backed up to $backupFolder)" -LogFilePath $updateObj.LogFilePath
}

Try
{
	$returnObj = New-Object PSCustomObject -Property @{ [string] 'Status' = ''; [string] 'Logdata' = ''; }
	$newDllVersion = (Get-ChildItem "$($updateObj.SharedSvcFldr)\bin\OnBoardSharedServices.dll").VersionInfo.FileVersion
	$binPath = (gci -directory $updateObj.WebSitePath -filter "bin").fullname
	if ($updateObj.MultiBank -ne '1')
	{
		$backupFolder = $updateObj.UpdatePath + "\WebSite Backup" + "\" + $updateObj.CurrentVersion
		Backup-Website -BackupFolder $BackupFolder
	}
	elseif ($updateObj.MultiBank -eq '1')
	{
		if ($regInfo.GetValue('Hosted') -ne '1')
		{
			$backupFolder = "$($multiBankObj.BankUpdFolder)\WebSiteBackup\$($updateObj.CurrentVersion)"
			Backup-Website -BackupFolder $BackupFolder
		}
		elseif ($regInfo.GetValue('Hosted') -eq '1') { Write-Log -LogData "Bank is hosted backup skipped.)" -LogFilePath $updateObj.LogFilePath }
		
	}
	
	GCI $binPath -Filter "*.dll" | ForEach-Object { Remove-Item -path $_.fullname }
	Copy-Item -Recurse "$($updateObj.SharedSvcFldr)\*" -Destination $updateObj.WebSitePath -Force
	$binDllVersion = (Get-ChildItem "$($updateObj.WebSitePath)\bin\OnBoardSharedServices.dll").VersionInfo.FileVersion
	if (($binDllVersion) -ne $newDllVersion) { throw "OnBoardSharedServices.dll versions do not match." }
	if ($regInfo.GetValue('Hosted') -ne '1') 
	{ 
		Stop-Website -Name $updateObj.Website
		Start-Website -Name $updateObj.Website
	}
	if ($regInfo.GetValue('Hosted') -eq '1') { Stop-Website -Name $updateObj.Website}
	$returnObj.status = 'Complete'
	$returnObj.LogData = "Website Update Complete."
	return $returnObj
}

Catch
{
	$returnObj.status = 'Failed'
	$returnObj.LogData = (Format-Message $_).full
	return $returnObj
}

