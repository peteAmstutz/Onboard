<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
	 Created on:   	3/31/2018 6:51 PM
	 Created by:   	pamstutz
	 Organization: 	
	 Filename:     	DataMigration.ps1
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
	$ddmSqlScript = (gci  "$($updateObj.UpdatePath)\DDMScripts" -filter "*.sql").fullname
	if ($ddmSqlScript -ne $null)
	{
		Invoke-Sqlcmd -Database $updateObj.DbName -InputFile $ddmSqlScript -ServerInstance $updateObj.SqlInstance -AbortOnError -ConnectionTimeout 30 -OutputSqlErrors $true
		$returnObj.LogData += "Script $ddmSqlScript complete.`r"
	}
	if (Test-Path "$($updateObj.LogFolder)\DDMExceptions.log") { Remove-Item "$($updateObj.LogFolder)\DDMExceptions.log" }
	if (Test-Path "$($updateObj.LogFolder)\DDMExceptions.log") { Remove-Item "$($updateObj.LogFolder)\DdmOutput.log" }
	$arguList = " $($updateObj.SqlInstance) $goldDbName $($updateObj.DbName)  `"$($updateObj.LogFolder)`""
	start-process -Wait -FilePath "$($updateObj.DataMigPath)" -ArgumentList $arguList -RedirectStandardOutput "$($updateObj.LogFolder)\DdmOutput.log"
	if (Test-Path "$($updateObj.LogFolder)\DDMExceptions.log")
	{
		[string]$logData = Get-Content "$($updateObj.LogFolder)\DDMExceptions.log"
		Throw "Data Migration failed. Error is `r$logData"
	}
	elseif (((Get-Content "$($updateObj.LogFolder)\DdmOutput.log") | Select-String -SimpleMatch "Database Changes were Rolled Back due to an Exception") -ne $null)
	{
		$xlsPath = (gci "$($updateObj.LogFolder)" -Filter '*.xlsx' | Sort-Object -Property lastwritetime -Descending)[0]
		Throw "Data Migration failed. Error is `"Database Changes were Rolled Back due to an Exception`"`rError log file is in `r$($xlsPath.fullname)`r"
	}
	else
	{
		$returnObj.status = 'Complete'
		$returnObj.LogData += "Data Migration complete."
		return $returnObj
	}
}

Catch
{
	$returnObj.status = 'Failed'
	$returnObj.LogData += (Format-Message $_).full
	return $returnObj
}