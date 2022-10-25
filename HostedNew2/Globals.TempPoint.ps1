#region AppSettingsFunctions
function Check-AppCfgKey
{
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string]$key,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$AppCfgPath
	)
	
	$script:Result = $null
	[xml]$xml = Get-Content $AppCfgPath
	foreach ($_ in $xml.appsettings.add) #Search through the appsettings.add nodes
	{
		if ($_.key -eq $key) { return $true }
	}
	return $false
}

function Add-AppCfgNode
{
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[string]$key,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$value,
		[Parameter(Mandatory = $true,
				   Position = 2)]
		[string]$AppCfgPath
	)
	
	[xml]$xml = Get-Content $AppCfgPath
	$child = $xml.appSettings.add[0] #Get the first node in appsettings.add
	$clone = $child.clone() #Clone the node
	$clone.key = $key #Change add.key value to new value
	$clone.value = $value #Change the value
	$xml.appSettings.AppendChild($clone) #Apend the child to appsettings.add 
	$whitey = $xml.CreateWhitespace("`r`n") #Create white space
	$xml.appSettings.AppendChild($Whitey) #Add white space so to nodes are not on one line
	$xml.Save($AppCfgPath)
}

Function Change-AppCfgValue
{
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[string]$key,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$value,
		[Parameter(Mandatory = $true,
				   Position = 2)]
		[string]$AppCfgPath
	)
	
	[xml]$xml = Get-Content $AppCfgPath
	foreach ($_ in $xml.appsettings.add) #Search through the appsettings.add nodes
	{
		if ($_.key -eq $key) { $_.value = $value }
		$xml.Save($AppCfgPath)
	}
}

Function Check-AppCfgValue
{
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string]$key,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$AppCfgPath
	)
	
	[xml]$xml = Get-Content $AppCfgPath
	foreach ($_ in $xml.appsettings.add) #Search through the appsettings.add nodes
	{
		if ($_.key -eq $key)
		{
			if ($_.value -eq $value)
			{ return $true }
		}
	}
	return $false
}

function Get-AppCfgValue($key, $appCfgPath)
{
	[xml]$xml = Get-Content $appCfgPath
	foreach ($_ in $xml.appsettings.add) #Search through the appsettings.add nodes
	{
		if ($_.key -eq $key)
		{ return $_.value }
	}
	return $false
}
#endregion AppSettingsFunctions

function Center-Cells
{
	
	$datagridview1.Rows | %{
		$rowIndex = $_.Index
		for ($colIndex = $datagridview1.columns["Backup"].Index; $colIndex -lt $datagridview1.columns["UpdAdd"].Index; $colIndex++)
		{
			$dataGridView1.rows[$rowIndex].cells[$colIndex].Style.Alignment = 'TopCenter'
		}
	}
}

function Clear-Selected
{
	$datagridview1.Rows | %{
		$row = $_
		$row.cells[0].Style.ForeColor = 'Black'
	}
	$script:selectedRows = $null
	$buttonLaunch.Enabled = $false
}

function Check-GoldDb
{
	foreach ($row in $datagridview1.Rows)
	{
		$rowIndex = $row.Index
		if ($datagridview1.Rows[$rowIndex].cells[5].value -ne '1')
		{
			$datagridview1.Enabled = $false
			$richtextbox1.Text = "GoldDb must be restored to enbable data grid."
			$restored = $false
			break
		}
	}
	if ($restored -ne $false) { return $true }
	else { return $false }
}

function Convert-Step($stepName)
{
	switch ($stepName)
	{
		'Backup' 	{ write 'BackupDb' }
		'RestoreDb' { write 'RestoreGoldDb' }
		'RunSqlPkg' { write 'RunSqlPackage' }
		'TagMap' 	{ write 'TagMapRefresh' }
		'DataMig' 	{ write 'DataMigration' }
		'SqlScr' 	{ write 'SqlScripts' }
		'UpdSite' 	{ write 'UpdateWebsite' }
		'UpdAdd' 	{ write 'UpdateAdd' }
	}
}

function Get-DbRestoreLog($startTime, $endTime, $sqlInst, $dbName)
{
	$query = @"
DECLARE @logFileType SMALLINT= 1;
DECLARE @start DATETIME;
DECLARE @end DATETIME;
DECLARE @logno INT= 0;
SET @start = '$startTime';
SET @end = '$endTime';
DECLARE @searchString1 NVARCHAR(256)= '$dbName';
DECLARE @searchString2 NVARCHAR(256)= '';
EXEC master.dbo.xp_readerrorlog 
     @logno, 
     @logFileType, 
     @searchString1, 
     @searchString2, 
     @start, 
     @end;

"@
	$results = Invoke-Sqlcmd -ServerInstance $sqlInst -Query $query
	(($results | where { $_.text -like "*restored*" } | select -ExpandProperty text).split(','))[0]
}

function Delete-OldFiles
{
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[string]$FolderPath,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$FileExtension,
		[Parameter(Mandatory = $true,
				   Position = 3)]
		[ValidateSet('Y', 'N', IgnoreCase = $true)]
		[string]$Recurse,
		[Parameter(Mandatory = $true,
				   Position = 2)]
		[int]$Days
	)
	$fileCount = 0
	if (Test-Path $FolderPath)
	{
		if ($recurse -eq 'Y') { $oldfFiles = Get-ChildItem $folderPath -Filter "*.$fileExtension" -Recurse }
		elseif ($recurse -eq 'N') { $oldfFiles = Get-ChildItem $folderPath -Filter "*.$fileExtension" }
		
		foreach ($file in $oldfFiles)
		{
			$currentYear = (Get-Date).year
			$fileYear = ((Get-ChildItem $file.FullName).LastWriteTime).year
			if ($fileYear -lt $currentYear)
			{
				Remove-Item $file.FullName
				$fileCount++
				continue
			}
			$dayOfYear = Get-Date -UFormat %j
			$fileDayOfYear = get-date ((Get-ChildItem $file.fullName).LastWriteTime) -UFormat %j
			if (($dayOfYear - $fileDayOfYear) -gt $Days)
			{
				remove-item $file.Fullname
				$fileCount++
			}
		}
		Return $fileCount
	}
	Return "$FolderPath not found"
}

function Format-Message($errData)
{
	$errObj = [PSCustomObject] @{
		"Text"    = ""
		"Program" = ""
		"Line"    = ""
		"Full"    = ""
	}
	
	$errObj.Text = $errData.Exception.Message
	$scriptName = $errData.InvocationInfo.ScriptName
	$errObj.Program = $scriptName.Substring(($scriptName.LastIndexOf('\')) + 1)
	$errObj.Line = $errData.InvocationInfo.ScriptLineNumber
	$errObj.Full = "$($errObj.Text)`rProgram:$($errObj.Program)`rLine: $($errObj.Line)`r"
	return $errObj
}

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

function Get-SqlServerInfo($sqlinstance)
{
	$instance = Get-SqlInstance -ServerInstance $sqlinstance
	$sqlBackupPath = $instance.BackupDirectory
	switch ($instance.VersionMajor)
	{
		10	{ $sqlVersion = '2008'; break; }
		11	{ $sqlVersion = '2012'; break; }
		12 { $sqlVersion = '2014'; break; }
		13 { $sqlVersion = '2016'; break; }
		14 { $sqlVersion = '2017'; break; }
		15 { $sqlVersion = '2019'; break; }
	}
	if ($instance.ComputerNamePhysicalNetBIOS -ne $env:COMPUTERNAME)
	{
		if ($instance.BackupDirectory -like "\\*") { $SqlUncPath = $instance.BackupDirectory }
		Else
		{
			$SqlUncPath = "\\" + $instance.ComputerNamePhysicalNetBIOS + '\' + $instance.BackupDirectory
			$SqlUncPath = $SqlUncPath.Replace(':', '$')
		}
		
	}
	Elseif ($instance.ComputerNamePhysicalNetBIOS -eq $env:COMPUTERNAME) { $SqlUncPath = '' }
	$sqlInfoObj = New-Object PSCustomObject -Property ([Ordered] @{
			"SqlUncPath"    = $SqlUncPath
			"sqlVersion"    = $sqlVersion
			"sqlBackupPath" = $sqlBackupPath
		})
	Return $sqlInfoObj
}

function Invoke-Query
{
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$Qry,
		[Parameter(Mandatory = $true)]
		[string]$DbName,
		[string]$Instance = $regInfoObj.SqlInstance
	)
	
	Invoke-Sqlcmd -Database $DbName -ServerInstance $Instance -Query $qry -OutputSqlErrors $true
}

function Get-FiconfigInfo($Path)
{
	$xml = New-Object -TypeName XML
	$xml.Load("$Path\connectionstrings.config")
	$node = $xml.SelectSingleNode("//connectionStrings/add")
	$Cnnstring = $node.connectionString
	$split = $Cnnstring.split("=")
	$sqlInst = ($split[1].Split(";")[0])
	$sqlInst = $sqlinst.replace('.jhahosting.com', '')
	if ($sqlinst -like "*\*")
	{
		$slash = $sqlInst.IndexOf('\')
		$comma = $sqlInst.IndexOf(',')
		$sqlinst = $sqlInst.Remove($slash, ($comma - $slash))
		}
		$dbInfo = New-Object psobject -Property @{
		SqlInstance = $sqlinst.trim()
		FiConfigDb  = ($split[2].Split(";")[0])
		UserName    = ($split[3].Split(";")[0])
		Password    = ($split[4].Split(";")[0])
		DbName	    = ''
		Institution = ''
	}
	if ((Invoke-Query -Qry "Select * from sys.databases where name = '$($dbInfo.FiConfigDb)'" -Instance $dbInfo.SqlInstance -DbName Master) -ne $null)
	{
		$query = "SELECT [BankClassicConnectionString], [Name]  FROM [$($dbInfo.FiConfigDb)].[dbo].[Bank]"
		$dataRow = (Invoke-Query -DbName $dbInfo.FiConfigDb -Qry $query -Instance $dbInfo.SqlInstance)
		$dbInfo.DbName = ($dataRow.BankClassicConnectionString.Split(';'))[1].split('=')[1]
		$dbInfo.Institution = $dataRow.Name
		return $dbInfo
	}
	Else
	{
		$dbInfo = $null
		return $dbInfo
	}
}

function Get-DbInfo($Path)
{
	Try
	{
		$xml = New-Object -TypeName XML
		$xml.Load("$Path\connectionstrings.config")
		$node = $xml.SelectSingleNode("//connectionStrings/add")
		$Cnnstring = $node.connectionString
		$split = $Cnnstring.split("=")
		$dbInfo = New-Object psobject -Property @{
			City	    = ''
			State	    = ''
			Institution = ''
			SqlInstance = ($split[1].Split(";")[0])
			FiConfigDb  = ($split[2].Split(";")[0])
			DbName	    = ''
		}
		if ((Invoke-Sqlcmd -ServerInstance $dbInfo.SqlInstance -Database Master -Query "Select * from sys.databases where name = '$($dbInfo.FiConfigDb)'") -ne $null)
		{
			$query = "SELECT [BankClassicConnectionString], [Name]  FROM [$($dbInfo.FiConfigDb)].[dbo].[Bank]"
			$dataRow = (Invoke-Sqlcmd -ServerInstance $RegInfo.SqlInstance -Database $dbInfo.FiConfigDb -Query $query)
			$fiCfgDbName = ($dataRow.BankClassicConnectionString.Split(';'))[1].split('=')[1]
			$dbInfo.DbName = (Invoke-Sqlcmd -ServerInstance $dbInfo.SqlInstance -Database master -Query "select name from sys.databases where name = '$fiCfgDbName'").name
			$bankinfo = Invoke-Sqlcmd -ServerInstance $dbInfo.SqlInstance -Query "SELECT City,State,BankDisplayName FROM $($dbInfo.DbName).deposits.BankDetailInformation"
			$dbInfo.City = $bankinfo.City
			$dbInfo.State = $bankinfo.State
			$dbInfo.Institution = $bankinfo.BankDisplayName
			return $dbInfo
		}
		Else
		{
			$dbInfo = $null
			return $dbInfo
		}
	}
	Catch { Format-Message $_ }
}

function Get-Websites
{
<#	Try
	{
#>	$siteObjects = @()
	
	$allsites = @()
	$allSites = gci iis:\sites | Where-Object -FilterScript { $_.name -notlike "Default*" -and $_.name -notlike "JxSvc*" -and $_.name -notlike "Edpp*" }
	$allSites | ForEach-Object {
		$website = $_
		$websitePath = $_.physicalPath
		if (!(Test-Path ($_.physicalPath + '\connectionstrings.config')))
		{
			Throw "ConnectionsString.config file not found in $($_.physicalPath)"
		}
		$siteObj = New-Object PSCustomObject -Property ([Ordered] @{
				City		   = ''
				CurrentVersion = ''
				CsiServer	   = ''
				DbName		   = ''
				Institution    = ''
				SSL		       = ''
				SqlInstance    = ''
				WebSite	       = $website.name
				WebSitePath    = $websitePath
			})
		$siteObj.CurrentVersion = (gci "$websitePath\bin\OnBoardSharedServices.dll").VersionInfo.fileversion
		$CsiServer = Get-AppCfgValue -key CSiJobManagerUri -appCfgPath "$websitePath\appsettings.config"
		$siteObj.CsiServer = ($CsiServer.split(':'))[1] -replace '//', ''
		$dbInfo = Get-FiconfigInfo -Path $websitePath
		if ($dbInfo -eq $null) { Throw "Ficonfig Db Info not found." }
		$siteObj.DbName = $dbInfo.DbName
		$siteObj.Institution = $dbInfo.Institution
		$siteObj.SqlInstance = $dbInfo.SqlInstance
		$siteobj.city = $siteObj.WebSite.split('_')[1]
		if ($website.bindings.collection.protocol -eq 'https') { $siteObj.ssl = 'Y' }
		elseif ($website.bindings.collection.protocol -eq 'http') { $siteObj.ssl = 'N' }
		
		$siteObjects += $siteObj
	}
	return $siteObjects
	#$siteObjects | ForEach-Object { Populate-UpdSiteInfo $siteObjects }
}

function Get-SiteObjects
{
	$updateObjects = @()
		Get-Websites | %{
		$site = $_
		$updateObj = [PSCustomObject] @{
			[string] 'City'		     = $_.city
			[string] 'CoreType'	     = (Query-Sql -DataBase $site.DbName -Query 'select Coretype from dbo.BankInformation' -SqlInstance $site.SqlInstance).coretype
			[string] 'CurrentVersion' = (Get-ChildItem "$($site.WebSitePath)\bin\OnBoardSharedServices.dll").VersionInfo.FileVersion;
			[string] 'FxlPath'	     = Get-AppCfgValue -key 'CSiFXLPath' -appCfgPath "$($site.WebSitePath)\AppSettings.config"
			[string] 'Date'		     = (Get-Date -Format g).toString();
			[string] 'DataMigPath'   = "$updateFolderPath\DynamicDataMigration\DynamicDataMigration.exe"
			[string] 'DbName'	     = $site.DbName
			[string] 'DbDeployFldr'  = "$updateFolderPath\DbDeploy"
			[string] 'DbUser'	     = 'onboard'
			[string] 'DbPassword'    = '0nBoard6'
			[string] 'Errored'	     = $false
			[string] 'Institution'   = $site.Institution
			[string] 'LogData'	     = "";
			[string] 'LogFilePath'   = "$updateFolderPath\MultiBank\$($site.DbName)\logs\UpdateLog.txt";
			[string] 'LogFolder'	 = "$updateFolderPath\MultiBank\$($site.DbName)\logs"
			[string] 'MultiBank'	 = $true
			[string] 'SharedSvcFldr' = "$updateFolderPath\SharedServices"
			[string] 'SqlBackupPath' = ''
			[string] 'SqlInstance'   = $site.SqlInstance
			[string] 'SqlPackageFldr'= "$updateFolderPath\SqlPackage"
			[string] 'SqlSriptsFldr' = "$updateFolderPath\SqlScripts"
			[string] 'SqlUncPath'    = ''
			[string] 'SqlVersion'    = ''
			[string] 'StepsPath'	 = "$updateFolderPath\MultiBank\$($site.DbName)\XmlFiles\Steps.xml";
			[string] 'TagMapPath'    = "$updateFolderPath\TagMappingRefresh\FieldDataTransfer.exe"
			[string] 'UpdatePath'    = $updateFolderPath
			[string] 'UpdateUser'    = $env:USERNAME;
			[string] 'UpdateVersion' = $updateVersion;
			[string] 'Website'	     = $site.Website;
			[string] 'WebSitePath'   = $site.WebSitePath
			[string] 'XmlFldr'	     = "$updateFolderPath\MultiBank\$($site.DbName)\XmlFiles"
		}
		
		$sqlInfoObj = Get-SqlServerInfo -sqlinstance (Get-SqlFromCnnCfg -Path $updateObj.WebSitePath )	
		$updateObj.sqlBackupPath = $sqlInfoObj.sqlBackupPath
		$updateObj.SqlUncPath= $sqlInfoObj.SqlUncPath
		$updateObj.sqlVersion= $sqlInfoObj.sqlVersion
		$updateObjects += $updateObj
	}
	return $updateObjects
}

function Invoke-Sqlcmd2
{
	
	[CmdletBinding(DefaultParameterSetName = 'Ins-Que')]
	[OutputType([System.Management.Automation.PSCustomObject], [System.Data.DataRow], [System.Data.DataTable], [System.Data.DataTableCollection], [System.Data.DataSet])]
	param (
		[Parameter(ParameterSetName = 'Ins-Que',
				   Position = 0,
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   HelpMessage = 'SQL Server Instance required...')]
		[Parameter(ParameterSetName = 'Ins-Fil',
				   Position = 0,
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false,
				   HelpMessage = 'SQL Server Instance required...')]
		[Alias('Instance', 'Instances', 'ComputerName', 'Server', 'Servers')]
		[ValidateNotNullOrEmpty()]
		[string[]]$ServerInstance,
		[Parameter(Position = 1,
				   Mandatory = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[string]$Database,
		[Parameter(ParameterSetName = 'Ins-Que',
				   Position = 2,
				   Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[Parameter(ParameterSetName = 'Con-Que',
				   Position = 2,
				   Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[string]$Query,
		[Parameter(ParameterSetName = 'Ins-Fil',
				   Position = 2,
				   Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[Parameter(ParameterSetName = 'Con-Fil',
				   Position = 2,
				   Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[ValidateScript({ Test-Path $_ })]
		[string]$InputFile,
		[Parameter(ParameterSetName = 'Ins-Que',
				   Position = 3,
				   Mandatory = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[Parameter(ParameterSetName = 'Ins-Fil',
				   Position = 3,
				   Mandatory = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[System.Management.Automation.PSCredential]$Credential,
		[Parameter(ParameterSetName = 'Ins-Que',
				   Position = 4,
				   Mandatory = $false,
				   ValueFromRemainingArguments = $false)]
		[Parameter(ParameterSetName = 'Ins-Fil',
				   Position = 4,
				   Mandatory = $false,
				   ValueFromRemainingArguments = $false)]
		[switch]$Encrypt,
		[Parameter(Position = 5,
				   Mandatory = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[Int32]$QueryTimeout = 600,
		[Parameter(ParameterSetName = 'Ins-Fil',
				   Position = 6,
				   Mandatory = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[Parameter(ParameterSetName = 'Ins-Que',
				   Position = 6,
				   Mandatory = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[Int32]$ConnectionTimeout = 15,
		[Parameter(Position = 7,
				   Mandatory = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[ValidateSet("DataSet", "DataTable", "DataRow", "PSObject", "SingleValue")]
		[string]$As = "DataRow",
		[Parameter(Position = 8,
				   Mandatory = $false,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $false)]
		[System.Collections.IDictionary]$SqlParameters,
		[Parameter(Position = 9,
				   Mandatory = $false)]
		[switch]$AppendServerInstance,
		[Parameter(ParameterSetName = 'Con-Que',
				   Position = 10,
				   Mandatory = $false,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $false,
				   ValueFromRemainingArguments = $false)]
		[Parameter(ParameterSetName = 'Con-Fil',
				   Position = 10,
				   Mandatory = $false,
				   ValueFromPipeline = $false,
				   ValueFromPipelineByPropertyName = $false,
				   ValueFromRemainingArguments = $false)]
		[Alias('Connection', 'Conn')]
		[ValidateNotNullOrEmpty()]
		[System.Data.SqlClient.SQLConnection]$SQLConnection
	)
	
	Begin
	{
		if ($InputFile)
		{
			$filePath = $(Resolve-Path $InputFile).path
			$Query = [System.IO.File]::ReadAllText("$filePath")
		}
		
		Write-Verbose "Running Invoke-Sqlcmd2 with ParameterSet '$($PSCmdlet.ParameterSetName)'.  Performing query '$Query'"
		
		If ($As -eq "PSObject")
		{
			#This code scrubs DBNulls.  Props to Dave Wyatt
			$cSharp = @'
                using System;
                using System.Data;
                using System.Management.Automation;

                public class DBNullScrubber
                {
                    public static PSObject DataRowToPSObject(DataRow row)
                    {
                        PSObject psObject = new PSObject();

                        if (row != null && (row.RowState & DataRowState.Detached) != DataRowState.Detached)
                        {
                            foreach (DataColumn column in row.Table.Columns)
                            {
                                Object value = null;
                                if (!row.IsNull(column))
                                {
                                    value = row[column];
                                }

                                psObject.Properties.Add(new PSNoteProperty(column.ColumnName, value));
                            }
                        }

                        return psObject;
                    }
                }
'@
			
			Try
			{
				Add-Type -TypeDefinition $cSharp -ReferencedAssemblies 'System.Data', 'System.Xml' -ErrorAction stop
			}
			Catch
			{
				If (-not $_.ToString() -like "*The type name 'DBNullScrubber' already exists*")
				{
					Write-Warning "Could not load DBNullScrubber.  Defaulting to DataRow output: $_"
					$As = "Datarow"
				}
			}
		}
		
		#Handle existing connections
		if ($PSBoundParameters.ContainsKey('SQLConnection'))
		{
			if ($SQLConnection.State -notlike "Open")
			{
				Try
				{
					Write-Verbose "Opening connection from '$($SQLConnection.State)' state"
					$SQLConnection.Open()
				}
				Catch
				{
					Throw $_
				}
			}
			
			if ($Database -and $SQLConnection.Database -notlike $Database)
			{
				Try
				{
					Write-Verbose "Changing SQLConnection database from '$($SQLConnection.Database)' to $Database"
					$SQLConnection.ChangeDatabase($Database)
				}
				Catch
				{
					Throw "Could not change Connection database '$($SQLConnection.Database)' to $Database`: $_"
				}
			}
			
			if ($SQLConnection.state -like "Open")
			{
				$ServerInstance = @($SQLConnection.DataSource)
			}
			else
			{
				Throw "SQLConnection is not open"
			}
		}
		
	}
	Process
	{
		foreach ($SQLInstance in $ServerInstance)
		{
			Write-Verbose "Querying ServerInstance '$SQLInstance'"
			
			if ($PSBoundParameters.Keys -contains "SQLConnection")
			{
				$Conn = $SQLConnection
			}
			else
			{
				if ($Credential)
				{
					$ConnectionString = "Server={0};Database={1};User ID={2};Password=`"{3}`";Trusted_Connection=False;Connect Timeout={4};Encrypt={5}" -f $SQLInstance, $Database, $Credential.UserName, $Credential.GetNetworkCredential().Password, $ConnectionTimeout, $Encrypt
				}
				else
				{
					$ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2};Encrypt={3}" -f $SQLInstance, $Database, $ConnectionTimeout, $Encrypt
				}
				
				$conn = New-Object System.Data.SqlClient.SQLConnection
				$conn.ConnectionString = $ConnectionString
				Write-Debug "ConnectionString $ConnectionString"
				
				Try
				{
					$conn.Open()
				}
				Catch
				{
					Write-Error $_
					continue
				}
			}
			
			#Following EventHandler is used for PRINT and RAISERROR T-SQL statements. Executed when -Verbose parameter specified by caller
			if ($PSBoundParameters.Verbose)
			{
				$conn.FireInfoMessageEventOnUserErrors = $false # Shiyang, $true will change the SQL exception to information
				$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] { Write-Verbose "$($_)" }
				$conn.add_InfoMessage($handler)
			}
			
			$cmd = New-Object system.Data.SqlClient.SqlCommand($Query, $conn)
			$cmd.CommandTimeout = $QueryTimeout
			
			if ($SqlParameters -ne $null)
			{
				$SqlParameters.GetEnumerator() |
				ForEach-Object {
					If ($_.Value -ne $null)
					{ $cmd.Parameters.AddWithValue($_.Key, $_.Value) }
					Else
					{ $cmd.Parameters.AddWithValue($_.Key, [DBNull]::Value) }
				} > $null
			}
			
			$ds = New-Object system.Data.DataSet
			$da = New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
			
			Try
			{
				[void]$da.fill($ds)
			}
			Catch [System.Data.SqlClient.SqlException] # For SQL exception
			{
				$Err = $_
				
				Write-Verbose "Capture SQL Error"
				
				if ($PSBoundParameters.Verbose) { Write-Verbose "SQL Error:  $Err" } #Shiyang, add the verbose output of exception
				
				switch ($ErrorActionPreference.tostring())
				{
					{ 'SilentlyContinue', 'Ignore' -contains $_ } { }
					'Stop' { Throw $Err }
					'Continue' { Throw $Err }
					Default { Throw $Err }
				}
			}
			Catch # For other exception
			{
				Write-Verbose "Capture Other Error"
				
				$Err = $_
				
				if ($PSBoundParameters.Verbose) { Write-Verbose "Other Error:  $Err" }
				
				switch ($ErrorActionPreference.tostring())
				{
					{ 'SilentlyContinue', 'Ignore' -contains $_ } { }
					'Stop' { Throw $Err }
					'Continue' { Throw $Err }
					Default { Throw $Err }
				}
			}
			Finally
			{
				#Close the connection
				if (-not $PSBoundParameters.ContainsKey('SQLConnection'))
				{
					$conn.Close()
				}
			}
			
			if ($AppendServerInstance)
			{
				#Basics from Chad Miller
				$Column = New-Object Data.DataColumn
				$Column.ColumnName = "ServerInstance"
				$ds.Tables[0].Columns.Add($Column)
				Foreach ($row in $ds.Tables[0])
				{
					$row.ServerInstance = $SQLInstance
				}
			}
			
			switch ($As)
			{
				'DataSet'
				{
					$ds
				}
				'DataTable'
				{
					$ds.Tables
				}
				'DataRow'
				{
					$ds.Tables[0]
				}
				'PSObject'
				{
					#Scrub DBNulls - Provides convenient results you can use comparisons with
					#Introduces overhead (e.g. ~2000 rows w/ ~80 columns went from .15 Seconds to .65 Seconds - depending on your data could be much more!)
					foreach ($row in $ds.Tables[0].Rows)
					{
						[DBNullScrubber]::DataRowToPSObject($row)
					}
				}
				'SingleValue'
				{
					$ds.Tables[0] | Select-Object -ExpandProperty $ds.Tables[0].Columns[0].ColumnName
				}
			}
		}
	}
}

function Load-Datagrid
{
	##Creating Columns for DataTable##
	$col1 = New-Object System.Data.DataColumn("City")
	$col2 = New-Object System.Data.DataColumn("Institution")
	$col3 = New-Object System.Data.DataColumn("DbName")
	$col4 = New-Object System.Data.DataColumn("Version")
	$col5 = New-Object System.Data.DataColumn("Backup")
	$col6 = New-Object System.Data.DataColumn("RestoreDb")
	$col7 = New-Object System.Data.DataColumn("RunSqlPkg")
	$col8 = New-Object System.Data.DataColumn("TagMap")
	$col9 = New-Object System.Data.DataColumn("DataMig")
	$col10 = New-Object System.Data.DataColumn("SqlScr")
	$col11 = New-Object System.Data.DataColumn("UpdSite")
	$col12 = New-Object System.Data.DataColumn("UpdAdd")
	
	###Adding Columns for DataTable###
	$dtable.columns.Add($col1)
	$dtable.columns.Add($col2)
	$dtable.columns.Add($col3)
	$dtable.columns.Add($col4)
	$dtable.columns.Add($col5)
	$dtable.columns.Add($col6)
	$dtable.columns.Add($col7)
	$dtable.columns.Add($col8)
	$dtable.columns.Add($col9)
	$dtable.columns.Add($col10)
	$dtable.columns.Add($col11)
	$dtable.columns.Add($col12)
	
	$siteObjects | %{
		$siteObj = $_
		[xml]$xml = gc $siteObj.StepsPath
		$row = $dTable.NewRow()
		$row["City"] = $siteObj.city
		$row["Institution"] = $siteObj.Institution
		$row["DbName"] = $siteObj.Dbname
		$row["Version"] = $siteObj.CurrentVersion
		$row["Backup"] = $xml.data.BackupDb
		$row["RestoreDb"] = $xml.data.RestoreGoldDb
		$row["RunSqlPkg"] = $xml.data.RunSqlPackage
		$row["TagMap"] = $xml.data.TagMapRefresh
		$row["DataMig"] = $xml.data.DataMigration
		$row["SqlScr"] = $xml.data.SqlScripts
		$row["UpdSite"] = $xml.data.UpdateWebsite
		$row["UpdAdd"] = $xml.data.UpdateAdd
		$dTable.rows.Add($row)
	}
	
	$datagridview1.DataSource = $dtable
	for ($i = 0; $i -lt $datagridview1.Rows.count; $i++)
	{
		for ($j = 0; $j -lt $datagridview1.Rows[$i].Cells.Count; $j++)
		{
			$value = $dataGridView1.rows[$i].cells[$j].Value
			if ($dataGridView1.rows[$i].cells[$j].Value -eq '1')
			{
				$dataGridView1.rows[$i].cells[$j].Style.BackColor = 'LightGreen'
			}
		}
	}
	$a = @(4 .. (($datagridview1.Columns.Count - 1)))
	[int]$cw = $datagridview1.columns[5].HeaderCell.ContentBounds.Width * 0.10 +  $datagridview1.columns[5].HeaderCell.ContentBounds.Width
	$a | %{ $datagridview1.columns[$_].Width = $cw }
	$b = @(0 .. 3)
	#$b | %{ $datagridview1.columns[$_].Width = ($datagridview1.columns[$_].HeaderCell.ContentBounds.Width + 5) }
	$b | %{ $datagridview1.columns[$_].Width = (65) }
	
	$allColWidths = $datagridview1.columns[$_].Width | select -ExpandProperty width
	$allColWidths = 25
	$datagridview1.Columns | select -expandProperty width | %{ $allColWidths += $_ }
	if ($datagridview1.Width -lt $allColWidths) { $datagridview1.Width = $allColWidths }
	$allRowHeights = 50
	$datagridview1.Rows | select -expandProperty height | %{ $allRowHeights += $_ }
	if ($datagridview1.height -lt $allRowHeights) { $datagridview1.height = $allRowHeights }
	$panel1.Size.Width = $datagridview1.Size.width
	#$panel1.Size.height = [int]($datagridview1.Size.height * 0.1)
	$formHostedNew2.width = [int]($panel1.size.width * 0.1)
	Center-Cells
}

function Rest-SQLDatabase
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$SqlBackupFile,
		[string]$SqlInst,
		[Parameter(Mandatory = $true)]
		[string]$SqlDatabase,
		[string]$SqlServerLogin = 'Onboard',
		[string]$SqlServerLoginPassword ,
		[string]$SqlDatabaseUser = $SqlDatabase,
		[string]$SqlDatabaseUserDefaultSchema = "dbo"
	)
	Write-Host "[INFO] Start Rest-SQLDatabase"
	$returnObj = New-Object PSCustomObject -Property @{ [string] 'Status' = ''; [string] 'Logdata' = ''; }
	if (!(Test-Path $SqlBackupFile)) { Throw "$SqlBackupFile not found." }
	if ($SqlInst -ne 'Multibank') { $sqlServer = (Get-SqlInstance -ServerInstance $sqlInst).displayname.split(',')[0] }
	elseif ($sqlInst -eq 'Multibank') { $sqlServer = 'Multibank' }
	$sqlBackupDir = (Get-SqlInstance -ServerInstance $sqlInst).backupDirectory # Read SQL instance to get destination default backup folder.
	$sqlUncPath = "\\$sqlServer\$sqlBackupDir"
	$sqlUncPath = $sqlUncPath.Replace(':', '$')
	$sqlTstBnkBakPath = ("$sqlBackupDir\" + ($SqlBackupFile | Split-Path -Leaf))
	$sqlUncBackupDir = ("\\$sqlServer\$sqlBackupDir").replace(':', '$') # Path to destination SQL Backup folder.
	Copy-Item $SqlBackupFile -Destination $sqlUncBackupDir -force
	
	$currentLocation = Get-Location
	
	$richtextbox1.Text += "[INFO] Server: $SqlServer"
	$richtextbox1.Text += "[INFO] Database: $SqlDatabase"
	$richtextbox1.Text += "[INFO] Server Login: $SqlServerLogin"
	$richtextbox1.Text += "[INFO] Database User: $SqlDatabaseUser"
	$richtextbox1.Text += "[INFO] Backup: $SqlBackupFile"
	
	#Load SMO assemblies
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
	
	#Set restore configurations
	$server = New-Object -Type Microsoft.SqlServer.Management.Smo.Server -Argumentlist $Sqlinst
	$server.ConnectionContext.StatementTimeout = 0
	$smoRestore = New-Object -Type Microsoft.SqlServer.Management.Smo.Restore
	$backupDevice = New-Object -Type Microsoft.SqlServer.Management.Smo.BackupDeviceItem -Argumentlist $sqlTstBnkBakPath, "File"
	$smoRestore.Devices.Add($backupDevice)
	$smoRestore.NoRecovery = $false
	$smoRestore.ReplaceDatabase = $true
	$smoRestore.Action = "Database"
	$smoRestore.PercentCompleteNotification = 10
	$percentEventHandler = [Microsoft.SqlServer.Management.Smo.PercentCompleteEventHandler] { Write-Host "[INFO] Restoring $($_.Percent)%" }
	$completedEventHandler = [Microsoft.SqlServer.Management.Common.ServerMessageEventHandler] { $richtextbox1.Text += "[INFO] Restore of database $SqlDatabase with $SqlBackupFile completed" }
	$smoRestore.add_PercentComplete($percentEventHandler)
	$smoRestore.add_Complete($completedEventHandler)
	$smoRestoreDetails = $smoRestore.ReadBackupHeader($server)
	
	#Get data/logfile names from backupfile
	$DBLogicalNameDT = $smoRestore.ReadFileList($server)
	
	foreach ($row in $DBLogicalNameDT)
	{
		$FileType = $row["Type"].ToUpper()
		if ($FileType.Equals("D"))
		{
			$dBLogicalName = $row["LogicalName"]
		}
		elseif ($FileType.Equals("L"))
		{
			$logLogicalName = $row["LogicalName"]
		}
	}
	
	#Data- and logfile paths
	$dbDataFile = "$($server.Settings.DefaultFile)$($SqlDatabase).mdf"
	$dbLogFile = "$($server.Settings.DefaultLog)$($SqlDatabase)_log.ldf"
	$richtextbox1.Text += "[INFO] Data: $dbDataFile"
	$richtextbox1.Text += "[INFO] Log: $dbLogFile"
	
	#Set restore configurations
	$smoRestore.Database = $SqlDatabase
	
	$dbRestoreFile = New-Object -Type Microsoft.SqlServer.Management.Smo.RelocateFile
	$dbRestoreLog = New-Object -Type Microsoft.SqlServer.Management.Smo.RelocateFile
	
	$dbRestoreFile.LogicalFileName = $dBLogicalName
	$dbRestoreFile.PhysicalFileName = $dbDataFile
	$dbRestoreLog.LogicalFileName = $logLogicalName
	$dbRestoreLog.PhysicalFileName = $dbLogFile
	
	$smoRestore.RelocateFiles.Add($dbRestoreFile) | Out-Null
	$smoRestore.RelocateFiles.Add($dbRestoreLog) | Out-Null
	
	#Create database if it does not exist
	if (!($server.Databases[$SqlDatabase]))
	{
		$db = New-Object -Type Microsoft.SqlServer.Management.Smo.Database -Argumentlist $server, $SqlDatabase
		$db.Create()
		$richtextbox1.Text += "[INFO] Created database $($db.Name)"
	}
	
	#Drop SQL connections
	$killConnectionsSQL = @"
           ALTER DATABASE $SqlDatabase
           SET OFFLINE WITH ROLLBACK IMMEDIATE
           GO
           ALTER DATABASE $SqlDatabase
        Set Online
"@
	
	$masterDb = $server.Databases["master"]
	$masterDb.ExecuteNonQuery($killConnectionsSQL)
	$richtextbox1.Text += "[INFO] Dropped connections to $SqlDatabase"
	
	#Restore backup to db
	$richtextbox1.Text += "[INFO] Starting restore of $SqlDatabase"
	$smoRestore.SqlRestore($server)
	
	$db = $server.Databases[$SqlDatabase]
	
	#Re-create service broker
	$serviceBrokerSql = "ALTER DATABASE [$SqlDatabase] SET NEW_BROKER with rollback immediate"
	$db.ExecuteNonQuery($serviceBrokerSql)
	$richtextbox1.Text += "[INFO] Re-created service broker"
	
	#Rename log and datafile logical names
	if ($($db.FileGroups[0].Files[0].Name) -cne $SqlDatabase)
	{
		$db.FileGroups[0].Files[0].Rename($SqlDatabase)
		$richtextbox1.Text += "[INFO] Renamed datafile logical name to $SqlDatabase"
	}
	
	if ($($db.LogFiles[0].Name) -cne "$($SqlDatabase)_log")
	{
		$db.LogFiles[0].Rename("$($SqlDatabase)_log")
		$richtextbox1.Text += "[INFO] Renamed logfile logical name to $($SqlDatabase)_log"
	}
	
	#Shrink logfile (.ldf) to 0KB
	$db.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple
	$db.Alter()
	$db.LogFiles[0].Shrink(0, [Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
	$db.LogFiles.Refresh($true)
	$db.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Full
	$db.Alter()
	#$richtextbox1.Text += "[INFO] Logfile shrunk to $($db.LogFiles[0].Size/1KB) KB"
	
	#Create login if it does not exist
	if (!($server.Logins[$SqlServerLogin]))
	{
		$login = New-Object -Type Microsoft.SqlServer.Management.Smo.Login -Argumentlist $server, $SqlDatabase
		$login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
		$login.PasswordExpirationEnabled = $false
		$login.PasswordPolicyEnforced = $false
		$login.DefaultDatabase = $SqlDatabase
		$login.Create($SqlServerLoginPassword)
		$richtextbox1.Text += "[INFO] Created SQLServer login $($login.Name)"
	}
	
	#Re-create database user
	if ($db.Users[$SqlDatabaseUser])
	{
		#Remove brokerservices owned by user
		[System.Collections.ArrayList]$brokerServices = $db.ServiceBroker.Services
		
		foreach ($service in $brokerServices)
		{
			if ($service.Owner -like $SqlDatabaseUser)
			{
				$service.Drop()
				$richtextbox1.Text += "[INFO] Dropped $($service.Name)"
			}
		}
		#Drop user
		$db.Users[$SqlDatabaseUser].Drop()
	}
	
	$databaseUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User -ArgumentList $db, $SqlDatabaseUser
	$databaseUser.Login = $SqlServerLogin
	$databaseUser.DefaultSchema = $SqlDatabaseUserDefaultSchema
	$databaseUser.Create()
	
	#Assign database role for new user
	$databaserole = $db.Roles["db_owner"]
	$databaserole.AddMember($SqlDatabaseUser)
	$databaserole.Alter | Out-Null
	
	$richtextbox1.Text += "[INFO] Re-created database user $SqlDatabaseUser"
	
	Set-Location -Path $currentLocation
	
	Write-Host "[DONE]" -ForegroundColor White -BackgroundColor Green
	Write-Host ""
	Start-Sleep -Seconds 5
	$tstBnkLog = Get-DbRestoreLog -startTime (get-date).AddMinutes(-3) -endTime (get-date) -sqlInst $sqlInst -dbName $SqlDatabase
	$tstBnkLog = $tstBnkLog.replace("'", "''")
	$returnObj.status = 'Complete'
	$returnObj.logdata = "$tstBnkLog"
	Write-Log -LogData $tstBnkLog -LogFilePath "$updateFolderPath\$tstBankFileName.log"
	return $returnObj
}

function Set-BackColor
{
	param
	(
		$rowIndex,
		[string]$step,
		[bool]$clear,
		[bool]$green
	)
	$trnspColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
	$colIndex = $datagridview1.Columns.IndexOf($datagridview1.Columns[$step])
	$cellValue = $datagridview1.rows[$rowIndex].Cells[$colIndex].Value
	if ($clear -eq $true) { $dataGridView1.rows[$rowIndex].cells[$colIndex].Style.BackColor = $trnspColor }
	elseif ($green) { $dataGridView1.rows[$rowIndex].cells[$colIndex].Style.BackColor = 'LightGreen' }
	elseif ($cellValue -eq '0') { $dataGridView1.rows[$rowIndex].cells[$colIndex].Style.BackColor = $trnspColor }
	elseif ($cellValue -eq '1') { $dataGridView1.rows[$rowIndex].cells[$colIndex].Style.BackColor = 'LightGreen' }
}

function Show-Msg
{
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[string]$msgName,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$msgText,
		[Parameter(Position = 2)]
		[string]$msgType
	)
	
	Add-Type -AssemblyName PresentationCore, PresentationFramework
	If ($msgType -eq 'YesNo') { [System.Windows.MessageBox]::Show($msgText, $msgName, 'YesNo', 'Question') }
	Else { [System.Windows.MessageBox]::Show($msgText, $msgName) }
}

function Get-SqlFromCnnCfg($Path)
{
	
	$xml = New-Object -TypeName XML
	$xml.Load("$Path\connectionstrings.config")
	$node = $xml.SelectSingleNode("//connectionStrings/add")
	$Cnnstring = $node.connectionString
	$split = $Cnnstring.split("=")
	Write ($split[1].Split(";")[0])
}

function Query-Sql
{
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[string]$DataBase,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$Query,
		[Parameter(Mandatory = $true,
				   Position = 2)]
		[string]$SqlInstance
	)
	
	return (Invoke-Sqlcmd -Database $DataBase -ConnectionTimeout 30 -Query $Query -QueryTimeout 300 -ServerInstance $SqlInstance -OutputSqlErrors $true)
}

function Get-XmlData($Element, $Node, $XmlPath)
{
	[xml]$xml = gc $XmlPath
	If ($xml.$Node.$Element -eq 0) { return $false }
	ElseIf ($xml.$Node.$Element -eq 1) { return $true }
	Else { throw "Invalid data in Get-XmlData function" }
}

function Set-XmlData($Element, $XmlPath, $value)
{
	$Node = 'Data'
	[xml]$xml = gc $XmlPath
	$xml.$node.$Element = $value
	$xml.Save($xmlPath)
}

function Write-Log
{
	param
	(
		[Parameter(Mandatory = $false)]
		[string]$LogData,
		[Parameter(Mandatory = $true)]
		[string]$LogFilePath
	)
	if(!(Test-Path $LogFilePath)){New-Item -ItemType file -Path $LogFilePath}
	add-content (Get-Date -Format g).toString() -Path $LogFilePath
	add-content "$LogData `n--------------------------------------------------------------------------------------------------------------------------------" -Path $LogFilePath
}

#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------

if ($env:COMPUTERNAME -eq 'multibank') # Set path to update here when testing on Eden Multibank server.
{
	$global:updateFolderPath = "C:\DepositsUpdateHosted\2021.6.10.0"
	$global:updateVersion = "2021.6.10.0"
	$global:ScriptDirectory = "$updateFolderPath\UpdateCode" # Get path to dir that script is running from.
	$global:sitesStopped = $false
}
else #Used when not testing in Eden
{
	$global:updateFolderPath = (Get-ScriptDirectory) | Split-path -parent | Split-path -parent
	$global:updateversion = (Get-ScriptDirectory) | Split-Path -Parent | Split-Path -Parent | Split-Path -Leaf
	$global:ScriptDirectory = "$updateFolderPath\UpdateCode"
}

# Read registry
$script:sqlSvr = (Get-Item -Path HKLM:\software\Wow6432Node\OnboardDepositsHosted).getvalue('SqlInstance') # Sql instance
$global:regInfo = Get-Item -Path HKLM:\software\Wow6432Node\OnboardDepositsHosted # Read entire DepositsHosted Reg entry

<#Deposits Hosted reg entries.
"DbName" = "HostedUpdate" 
"DbPassword" = "0nBoard6"
"DbUser" = "Onboard"
"SqlInstance" = "MMOObdDb02,54281"
"MultiBank" = "1"
"UpdateFolder" = "c:\\depositsupdateHosted"
"Hosted" = "1" Not needed any longer.
"DocType" = "CSI" Not needed any longer.
"ServerName" = "MMOOBDWEB03" Not needed any longer.#>

$global:InfoObj = Import-Clixml -Path ((Split-Path $ScriptDirectory -Parent) + "\UpdInfo.xml")

<#InfoObj reads Ups InfoXML file created when update is created that contains update information.
<S N="BldParent">\\MMOONBGOLDAP1\BuildDeliveries\WK</S> 						Source parent folder				NOT necessary for update.
<S N="BakFileDate">May, 06, 2021 07:26:40</S> 									Date bak file was created			NOT necessary for update.
<S N="BakFileName">WKSupportSilverlake</S> 										Bak file name	
<S N="CoreType">Core Director</S> 												Obvious
<S N="ClientSrcDir">\\MMOONBGOLDAP1\BuildDeliveries\WK\2021.4.9.0\Client</S> 	Client Src Dir						NOT necessary for update.
<S N="DocType">WK</S> 															Doc type CSI or WKFS
<S N="DstPath">C:\Users\pamstutz\Desktop\UpdCrtTemp</S>							Destination when update was created NOT necessary for update.
<S N="PrevVersion">2021.3</S> 
<S N="PrimSrcDir">\\MMOONBGOLDAP1\BuildDeliveries\WK\2021.4.9.0</S> Full path to source dir.						NOT necessary for update.
<S N="HotFixSrcDir"></S> Only used when a hot fix is used to build update											NOT necessary for update.
<S N="UpdAdd">0</S> Update additions enabled.	
<S N="UpdType">New Update</S> New or New with hotfix.																NOT necessary for update.
<S N="UpdVersion">2021.4.9.0</S>																					NOT necessary for update.
#>

$script:rows = $null # Global variable that stores the rows variable for the datagrid view.
<#if ($regInfo.GetValue('DocType') -eq $null) PDA NOT USED ANYMORE
{
	if ($env:COMPUTERNAME -like "*WK*") { Set-ItemProperty -Path HKLM:\software\Wow6432Node\OnboardDepositsHosted -Name 'DocType' -Value 'WKFS' }
	else { Set-ItemProperty -Path HKLM:\software\Wow6432Node\OnboardDepositsHosted -Name 'DocType' -Value 'CSI' }
}#>
