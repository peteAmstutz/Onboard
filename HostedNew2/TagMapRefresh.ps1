<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
	 Created on:   	3/31/2018 6:50 PM
	 Created by:   	pamstutz
	 Organization: 	
	 Filename:     	TagMapRefresh.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

param
(
	[Parameter(Mandatory = $true)]
	[string]$GoldDbName
)
Try
{
	$returnObj = New-Object PSCustomObject -Property @{ [string] 'Status' = ''; [string] 'Logdata' = ''; }
	$tagMapLog = "$($updateObj.LogFolder)\TagMap.log"
	if (Test-Path $tagMapLog) { Remove-Item -path $tagMapLog }
	Add-Content -Path $tagMapLog -Value ((Get-Date -format M-d-yyyy-HH:mm).toString() + "`r`n")
	$tagArgs = " -is:$($updateObj.SqlInstance) -idb:$goldDbName -iid:$($updateObj.DbUser) -ipw:$($updateObj.DbPassword) -os:$($updateObj.SqlInstance) -odb:$($updateObj.DbName)
	-oid:$($updateObj.DbUser) -opw:$($updateObj.DbPassword) -nw true"
	Start-Process -FilePath $updateObj.TagMapPath -ArgumentList $tagArgs -Wait -RedirectStandardOutput $tagMapLog
	$logData = Get-Content $tagMapLog
	if ($logData -like "*Error Exporting Data*") { Throw "Tag Map Refresh failed.`rTag map log file path is`r$tagMapLog" }
	else
	{
		$returnObj.status = 'Complete'
		$returnObj.LogData = 'Tagmapping Completed'
		return $returnObj
	}
}

Catch
{
	$returnObj.status = 'Failed'
	$returnObj.LogData = (Format-Message $_).full
	return $returnObj
}
