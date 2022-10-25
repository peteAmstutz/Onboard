<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
	 Created on:   	3/31/2018 6:49 PM
	 Created by:   	pamstutz
	 Organization: 	
	 Filename:     	RestoreGoldDb.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
Try
{
	$returnObj = New-Object PSCustomObject -Property @{ [string] 'Status' = ''; [string] 'Logdata' = ''; }
	if (($updateObj.MultiBank -eq '1') -and ($global:skipRestore -eq $true))
	{
		$returnObj.status = 'Complete'
		$returnObj.LogData = "GoldDB restore skip selected."
		return $returnObj
	}
	if ((Query-Sql -DataBase Master -Query "select name from sys.databases" -SqlInstance $updateObj.SqlInstance).name -contains 'TestBankOneDep' -eq $false)
	{
		Query-Sql -DataBase Master -Query 'CREATE DATABASE TestBankOneDep' -SqlInstance $updateObj.SqlInstance
	}
	if ($updateObj.SqlUncPath -eq '')
	{
		$tstBnkDepDstPath = $updateObj.SqlBackupPath +  '\'  + (Split-Path $updateObj.GoldDbBakPath -Leaf)
		Copy-Item  $updateObj.GoldDbBakPath -Destination $tstBnkDepDstPath -Force
		if (!(Test-Path $tstBnkDepDstPath)) {throw "$tstBnkDepDstPath not found in $($updateObj.SqlBackupPath)"} 
	}
	ElseIf ($updateObj.SqlUncPath -ne '')
	{
		$tstBnkDepDstPath = $updateObj.SqlUncPath + '\' + (Split-Path $updateObj.GoldDbBakPath -Leaf)
		Copy-Item  $updateObj.GoldDbBakPath -Destination "fileSystem::$tstBnkDepDstPath" -Force
		if (!(Test-Path $tstBnkDepDstPath)) { throw "$tstBnkDepDstPath not found in $($updateObj.SqlUncPath)" }
	}
	$testBankSrcFile = $updateObj.SqlBackupPath + '\' + "testbankonedep$Updateversion.bak"
	Restore-SqlDatabase -ServerInstance $updateObj.SqlInstance -Database TestBankOneDep -BackupFile $testBankSrcFile -ReplaceDatabase
	$query = @"
IF EXISTS (SELECT name FROM sys.schemas WHERE name = N'Onboard')
   BEGIN
      DROP SCHEMA [Onboard]
END
GO
ALTER AUTHORIZATION ON SCHEMA::[db_owner] TO [dbo]
GO
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = N'Onboard')
DROP USER [Onboard]
CREATE USER [Onboard] FOR LOGIN [Onboard]
EXEC sp_addrolemember N'db_owner', N'Onboard'
GO
"@
	Query-Sql -DataBase TestBankOneDep -Query $query -SqlInstance $updateObj.SqlInstance
	$returnObj.status = 'Complete'
	$returnObj.LogData = "Database OnBoardDep_Gold.bak restored"
	return $returnObj
}

Catch
{
	$returnObj.status = 'Failed'
	$returnObj.LogData = (Format-Message $_).full
	return $returnObj
}
