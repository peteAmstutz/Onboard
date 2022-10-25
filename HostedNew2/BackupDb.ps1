<#
	.SYNOPSIS
		A brief description of the Invoke-BackupDb_ps1 file.
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER UpdateVersion
		A description of the UpdateVersion parameter.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
		Created on:   	3/31/2018 6:48 PM
		Created by:   	pamstutz
		Organization:
		Filename:		BackupDb.ps1
		===========================================================================
#>
Try
{
	$returnObj = New-Object PSCustomObject -Property @{ [string] 'Status' = ''; [string] 'Logdata' = ''; }
	$dbBackupFileName = $updateObj.dbName + '-' + 'Version ' + $updateObj.CurrentVersion + ' - Date ' + (Get-Date -format M-d-yyyy-HH-mm).toString() + '.bak'
	$VerbosePreference = 'continue'
	(Backup-SqlDatabase -ServerInstance $updateObj.SqlInstance -Database $updateObj.DbName -BackupFile $dbBackupFileName -CopyOnly) *> "$($updateObj.LogFolder)\BackupDbLog.txt"
	if ($updateObj.SqlUncPath -ne '') { $testDbBackupPath = $updateObj.SqlUncPath + '\' + $dbBackupFileName }
	elseIf ($updateObj.SqlUncPath -eq '') { $testDbBackupPath = $updateObj.SqlBackupPath + '\' + $dbBackupFileName }
	if ((Select-String -Path "$($updateObj.LogFolder)\BackupDbLog.txt" -SimpleMatch -Pattern "BACKUP DATABASE successfully").lineNumber -ne $null)
	{
		$returnObj.status = 'Complete'
		$returnObj.LogData = "Backup of database $($updateObj.dbName) to $($updateObj.SqlBackupPath) successful"
		Write-Log -LogData (Get-Content "$($updateObj.LogFolder)\BackupDbLog.txt")[0] -LogFilePath $updateObj.LogFilePath
		return $returnObj
	}
	Else { Throw "Backup of database $($updateObj.dbName) failed." }
}

Catch
{
	$returnObj.status = 'Failed'
	$returnObj.LogData = (Format-Message $_).full
	return $returnObj
}

