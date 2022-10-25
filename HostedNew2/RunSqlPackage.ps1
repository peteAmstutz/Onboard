<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
	 Created on:   	3/31/2018 6:50 PM
	 Created by:   	pamstutz
	 Organization: 	
	 Filename:  	RunSqlPackage.ps1   	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

Try
{
	$returnObj = New-Object PSCustomObject -Property @{ [string] 'Status' = ''; [string] 'Logdata' = ''; }
	$pubXmlPath = "$($updateObj.LogFolder)\PublishXml.xml"
	$dacPacPath = $updateObj.UpdatePath + '\DBDeploy\DeployFiles\OnBoardDepositsDB.dacpac'
	$sqlPackagePath = "$($updateObj.SqlPackageFldr)\$($updateObj.SqlVersion)\SqlPackage.exe"
	$sqlObj = Import-Clixml  "$($updateObj.UpdatePath)\SqlScripts\SqlPkgScript.xml"
	$scripts = $sqlObj.psobject.properties.value
	if ($scripts -ne '')
	{
		ForEach ($script in $scripts)
		{
			Try
			{
				Invoke-Sqlcmd -Database $($updateObj.DbName) -InputFile "$($updateObj.UpdatePath)\SqlScripts\$script" -ServerInstance $($updateObj.SqlInstance) -AbortOnError -ConnectionTimeout 30 -OutputSqlErrors $true
				$sqlPkgLogPath = "$($updateObj.LogFolder)\SqlPackage.log"
				Add-Content "$($updateObj.LogFolder)\SqlPkgScript.log" -value "Sql package script $script completed on database $($updateObj.DbName).`r"
				$returnObj.LogData += "Sql package script $script completed.`r"
			}
			Catch
			{
				throw $returnObj.LogData += ("Script $script failed.Error is:`r" + $_.Exception.message)
			}
		}
	}
	$publishXmlData =
	@"
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
<PropertyGroup>
<IncludeCompositeObjects>True</IncludeCompositeObjects>
<TargetDatabaseName>$($updateObj.DbName)</TargetDatabaseName>
<DeployScriptFileName>publishXml</DeployScriptFileName>
<TargetConnectionString>Data Source=$($updateObj.SqlInstance);Integrated Security=True;Pooling=False</TargetConnectionString>
<ProfileVersionNumber>1</ProfileVersionNumber>
<ScriptDatabaseOptions>True</ScriptDatabaseOptions>
<BlockOnPossibleDataLoss>False</BlockOnPossibleDataLoss>
<ScriptRefreshModule>False</ScriptRefreshModule>
</PropertyGroup>
</Project>
"@
	Set-Content $pubXmlPath -Value $publishXmlData
	$sqlPackageParms = "/Action:Publish /SourceFile:`"$dacPacPath`" /Profile:`"$pubXmlPath`""
	$sqlPkgErrsPath = "$($updateObj.LogFolder)\SqlPackageError.log"
	$sqlPkgLogPath = "$($updateObj.LogFolder)\SqlPackage.log"
	Add-content -Value "$sqlPackagePath  $sqlpackageparms" -Path $updateObj.LogFilePath
	Start-Process -wait -FilePath $sqlPackagePath -ArgumentList $sqlPackageParms -RedirectStandardError $sqlPkgErrsPath -RedirectStandardOutput $sqlPkgLogPath
	if ((select-string -Path $sqlPkgLogPath -SimpleMatch 'Successfully published database') -eq $null)
	{
		
		Throw ("Invoke SqlPackage errored. Error is:`nErrors occurred.`n" + (GC $sqlPkgErrsPath))
	}
	$returnObj.status = 'Complete'
	$returnObj.LogData += "Run Sql Package Completed"
	return $returnObj
}

Catch
{
	$returnObj.status = 'Failed'
	$returnObj.LogData += (Format-Message $_).full
	return $returnObj
}
