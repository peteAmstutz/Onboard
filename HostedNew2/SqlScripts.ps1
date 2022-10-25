<#
	.SYNOPSIS
		A brief description of the Invoke-SqlScripts_ps1 file.
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER DisableReindex
		A description of the DisableReindex parameter.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
		Created on:   	3/31/2018 6:51 PM
		Created by:   	pamstutz
		Organization:
		Filename:  	SqlScripts.ps1
		===========================================================================
#>
function Run-ReIndex
{
	Try
	{
		Invoke-sqlcmd2 -ServerInstance $updateObj.SqlInstance -Database $updateObj.DbName -InputFile "$($updateObj.SqlSriptsFldr)\Re-Index\DboReindex.sql" -QueryTimeout 360
		$returnObj.LogData += "DboReindex complete"
		Invoke-sqlcmd2 -ServerInstance $updateObj.SqlInstance -Database $updateObj.DbName -InputFile "$($updateObj.SqlSriptsFldr)\Re-Index\DepositsReindex.sql" -QueryTimeout 360
		$returnObj.LogData += "DepositsReindex complete"
	}
	Catch
	{
		throw $returnObj.LogData += ("Re-Index failed.Error is:`r `r" + $_.Exception.message)
	}
}

Try
{
	$returnObj = New-Object PSCustomObject -Property @{ [string] 'Status' = ''; [string] 'Logdata' = ''; }
	$sqlObj = Import-Clixml  "$($updateObj.UpdatePath)\SqlScripts\SqlScripts.xml"
	$scripts = $sqlObj.psobject.properties.value
	if ($scripts -ne '')
	{
		ForEach ($script in $scripts)
		{
			Try
			{
				if ($script -like 'eform*')
				{
					$pdfName = $script.Split('.')[0] + '.pdf'
					$pdfPath = ("$($updateObj.UpdatePath)\eforms\$pdfName")
					$eformSqlScriptPath = ("$($updateObj.UpdatePath)\SqlScripts\$script")
					if ($updateObj.SqlUncPath -eq $null) { Copy-Item  $pdfPath -Destination "$($updateObj.SqlBackupPath)\$pdfName" -Force }
					else { Copy-Item  $pdfPath -Destination "$($updateObj.SqlUncPath)\$pdfName" -Force }
					$content = GC $eformSqlScriptPath
					$bulkLine = $content | Select-string -SimpleMatch Bulk
					$replace = $bulkLine.line.split("'")[1]
					$content = $content.replace($replace, "$($updateObj.SqlBackupPath)\$pdfName")
					set-content $eformSqlScriptPath -Value $content -force
					Invoke-Sqlcmd -Database $updateObj.DbName -InputFile $eformSqlScriptPath -ServerInstance $updateObj.SqlInstance -AbortOnError -ConnectionTimeout 30 -OutputSqlErrors $true | Out-Null
				}
				Else { Invoke-Sqlcmd -Database $updateObj.DbName -InputFile "$($updateObj.UpdatePath)\SqlScripts\$script" -ServerInstance $updateObj.SqlInstance -AbortOnError -ConnectionTimeout 30 -OutputSqlErrors $true | Out-Null }
				$returnObj.LogData += "Script $($updateObj.UpdatePath)\SqlScripts\$script complete.`r"
			}
			Catch
			{
				throw $returnObj.LogData += ("Script $script failed.Error is:`r `r" + $_.Exception.message)
			}
		}
	}
	if ($env:USERDNSDOMAIN -ne 'JHAHOSTING.COM') { Run-ReIndex }
	$returnObj.status = 'Complete'
	$returnObj.LogData += "SQL Scripts Completed`r"
	return $returnObj
}

Catch
{
	$returnObj.status = 'Failed'
	$returnObj.LogData = (Format-Message $_).full
	return $returnObj
}
