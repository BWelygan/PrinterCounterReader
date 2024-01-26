# Version 1.3.1
# Jan 26 2024
# Brad Welygan
# Updated Data base Scheme, updated script to reflect changes.

# PrntTotals (2023 change)
# Add Unique ID to remove duplicate Printer SN issues, and keep history of Counts

#------------------------------
Remove-Variable -Name * -Force -ErrorAction SilentlyContinue

# Get current script location.
#$PSScriptRoot

$scriptLogFile = "\\clearwatercounty.ca\cc\Application Data\PrinterTools\GetCounts_"+ $(Get-Date -f dd-MM-yyyy) +".log"
if (!(Test-path -Path $scriptLogFile)) {
	New-Item -Path $scriptLogFile -ItemType File
}

<# TO-DO
	json file
		Support number parameters for scraping Support number off Printers
         - Support number provided by Supporting Company / Service Contract
         - Currenly manually entered on the printers SNMP Location field
         - might work better to have a Table that corralates Serial Number to Support Number
	Reconsile duplicates Printers
	function for writing to database (done)
	 - Update Printer values if changed Dymanic Update Statement?
	 - Check Online agains Serial number.
	 - Offline machines that have been retired.
#>

#---- Function to load json Files
function Get-jsonFile {
	<#
	.SYNOPSIS
		Loads json file content in to powershell CustomObject
	.PARAMETER filePath
		File path to json file
    .PARAMETER hashTable
        Output object as a hashtable
	.OUTPUTS
	powershell object with json content
	#>
	[CmdletBinding(DefaultParameterSetName='Default')]
	param (
		[Parameter(Mandatory=$true,
		ParameterSetName='Default',
		Position=0,
		ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
		HelpMessage="json File path")]
		[ValidateNotNullOrEmpty()]
		[Alias("Path")]
		[String]$filePath,
        [Parameter(ParameterSetName='Default',
        Position=2,
        HelpMessage="Output a Hashtable")]
        [Alias("ht")]
        [switch]$hashTable
	)
	begin{
		$jsonContent = ""
	}
	process{
		try{
            if($hashTable){
                if (Test-Path -PathType Leaf -Path $filePath) {
                    $jsonContent = Get-Content -Path $filePath | ConvertFrom-Json -AsHashtable
                }else{
                    throw "Error - file doesn't exsist at location $filePath"
                }
            }else{
                if (Test-Path -PathType Leaf -Path $filePath) {
                    $jsonContent = Get-Content -Path $filePath | ConvertFrom-Json
                }else{
                    throw "Error - file doesn't exsist at location $filePath"
                }
            }
		}catch{
			$_
		}
		
	}
	end{
		if ($null -eq $jsonContent){
			$null
		}else{
			$jsonContent
		}
	}
}

#-- Get Printers from the registry. Use the flags to choose location
function Get-CWPrinters {
	<#
	.SYNOPSIS
		Get Printers from the registry. Use the flags to choose location. Returns a Hash Array
	.PARAMETER CCRegistry
		Pull printer data from Clearwater County Registry area
	.PARAMETER Registry
		Pull printer data from Windows registry area
	.PARAMETER CCDefaultPrinter
		Pull Default Printer from the Clearwatre County registry Area
	.PARAMETER RegistryDefaultPrinter
		Pull Default Printer from the Windows registry Area
	.PARAMETER PrintServer
		Get all shared printer from Printer server in -PrintServerName
	.PARAMETER PrintServerName
		Name of the print Server to pull all shared printers from
	.OUTPUTS
		Hash table with Printers Share name and Server Name
	.EXAMPLE
		$container = getPrinter -PrintServer -PrintServerName cw-r-coreprnt02.clearwatercounty.ca
		$container = getPrinter -ccRegistry
	#>
	[CmdletBinding(DefaultParameterSetName='Default')]
	param (
		[Parameter(Mandatory=$false,
		ParameterSetName="Default",
		HelpMessage="Get printers from the Clearwater County Registry area.")]
		[Alias("CC")]
		[ValidateNotNullOrEmpty()]
		[SWITCH]$CCRegistry,
		[Parameter(Mandatory=$false,
		ParameterSetName="Default",
		HelpMessage="Get printers from Windows Registry.")]
		[Alias("Windows")]
		[ValidateNotNullOrEmpty()]
		[SWITCH]$Registry,
		[Parameter(Mandatory=$false,
		ParameterSetName="Default",
		HelpMessage="Get Default printer from Clearewater County Registry.")]
		[Alias("CCDefault")]
		[ValidateNotNullOrEmpty()]
		[SWITCH]$CCDefaultPrinter,
		[Parameter(Mandatory=$false,
		ParameterSetName="Default",
		HelpMessage="Get Default Printer from Windows Registry.")]
		[Alias("WinDefault")]
		[ValidateNotNullOrEmpty()]
		[SWITCH]$RegistryDefaultPrinter,
		[Parameter(Mandatory=$true,
		ParameterSetName="PrintServer",
		HelpMessage="Set Flag to get Printers from Print Server.")]
		[Alias("PS")]
		[ValidateNotNullOrEmpty()]
		[SWITCH]$PrintServer,
		[Parameter(Mandatory=$true,
		ParameterSetName="PrintServer",
		HelpMessage="Print Server to get printers from")]
		[ValidateNotNullOrEmpty()]
		[STRING]$PrintServerName
	)
	Begin{
		# KEY Sharename VALUE Print Server
		$printerContainer = @()
		$RegistryLocation = $null
		if($CCRegistry){
			$RegistryLocation = $CurUserRegPath + $ccRegistryPrinters 
		}
		if($Registry){
			$RegistryLocation = $CurUserRegPath + $curUserRegInstalledPrinters
		}
		if($CCDefaultPrinter){
			$RegistryLocation = $CurUserRegPath + $ccRegistryPrinterSettings
		}
		if ($RegistryDefaultPrinter) {
			$RegistryLocation = $CurUserRegPath + $curUserRegDefaultPrinter
		}
		if ($null -ne $RegistryLocation -and !$PrintServer) {
			$RegistryDump = $(Get-Item ($RegistryLocation))	
		}elseIf(!$PrintServer){
			Throw "No FLAG set. Please run again specifying a flag"
			return
		}
		if (!(Test-Connection $PrintServerName)) {
			Throw "Print Server is down, or doens't exsist."
			return
		}
		
	}
	Process{
		if($PrintServer){
			foreach ($item in $(Get-Printer -ComputerName $PrintServerName)) {
				$printerContainer += [PSCustomObject]@{
					"Name" = $item.Name
					"Server" = $item.ComputerName
					"IP" = $item.PortName
					"DriverName" = $item.DriverName
					"Shared" = $item.Shared
				}
				#$printerContainer | Add-Member -MemberType NoteProperty -Name $Item.Name -Value $item.ComputerName
				#$printerContainer | Add-Member -MemberType NoteProperty -Name "IP" -Value $item.PortName
			}
		}else{
			ForEach ($item in $RegistryDump.Property ){
				If($Registry){
					$printerContainer += @{$item.Split('\')[3] = $item.split('\')[2]}
					#$printerContainer | Add-Member -MemberType NoteProperty -Name $item.Split('\')[3] -Value $item.split('\')[2]
				}
				if ($CCRegistry) {
					$printerContainer += @{$item = $RegistryDump.GetValue{$Item}}
					#$printerContainer | Add-Member -MemberType NoteProperty -Name $item -Value $RegistryDump.GetValue{$Item}
				}
				if ($RegistryDefaultPritner -and $item -eq 'Device') {
					$printerContainer += @{$RegistryDump.GetValue($item).Split(',')[0].Split('\')[3] = $RegistryDump.GetValue("$item").Split(',')[0].Split('\')[2]}
					#$printerContainer | Add-Member -MemberType NoteProperty -Name ($RegistryDump.GetValue($item).Split(',')[0].Split('\')[3]) -Value $RegistryDump.GetValue("$item").Split(',')[0].Split('\')[2]
				}
				if($CCDefaultPrinter -and $item -eq 'DefaultPrinter'){
					$printerContainer += @{$RegistryDump.GetValue($item).Split('\')[3] = $RegistryDump.GetValue($item).Split('\')[2]}
					#$printerContainer | Add-Member -MemberType NoteProperty -Name ($RegistryDump.GetValue($item).Split('\')[3]) -Value $RegistryDump.GetValue($item).Split('\')[2]
				}
			}
		}
		
	}
	end{
		$printerContainer
	}
}
#-- Write Printer information to the Database.
function Set-CWITPrinter {
	<#
	.SYNOPSIS
		Write a Printer Array to a Database
	.PARAMETER Printer
		Type PSCustomObject. Printer object array
	.PARAMETER sqlCommands
		Type PSCustomObject. Contains the sql required to add the printer to the database
	.PARAMETER connectionString
		Type String. Connection string to connect to Database
	.OUTPUTS
		Status Successfully add data to Database or error(s)
	.EXAMPLE
		Set-CWITPrinter -Printer $printer
	#>
	[CmdletBinding(DefaultParameterSetName='Default')]
	param (
		[Parameter(Mandatory=$true,
		ParameterSetName="Default",
		HelpMessage = "Printer Details Array. Containing; Name, ShareName, Location, Manufacturer, Serial Number, IP, Online Status, 
		list of Function(s), Total Page count, Total Black and White, Total Colour, Alert Level, Alert Description, Alert Time (ticks)",
		Position=0,
		ValueFromPipeline=$true)]
		[Alias("Printer")]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$fctPrinter,
		[Parameter(Mandatory=$true,
		ParameterSetName="Default",
		HelpMessage = "SQL statements for adding the printer objects to the database",
		ValueFromPipeline=$true)]
		[Alias("sqlcmds")]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$sqlCommands,
		[Parameter(Mandatory=$true,
		ParameterSetName="Default",
		HelpMessage = "Connection string for System.Data.SqlClient.SqlConnection",
		ValueFromPipeline=$true)]
		[Alias("connString")]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$connectionString
	)
	
	begin {
		function Get-PrinterFunction {
			[CmdletBinding(DefaultParameterSetName='FunctionID')]
			param (
				[Parameter(Mandatory="true",
				ParameterSetName="FunctionID",
				HelpMessage = "Flag to return Function Name")]
				[Alias("ReturnName")]
				[switch]$getName,
				[Parameter(Mandatory="true",
				ParameterSetName="FunctionID",
				HelpMessage = "Get the Function Name from the database by Function ID")]
				[string]$functionID,
				[Parameter(Mandatory="true",
				ParameterSetName="FunctionName",
				HelpMessage = "Flag to return Function ID")]
				[Alias("ReturnID")]
				[switch]$getID,
				[Parameter(Mandatory=$true,
				ParameterSetName="FunctionID",
				HelpMessage = "SQL statements for adding the printer objects to the database",
				ValueFromPipeline=$true)]
				[Parameter(ParameterSetName="FunctionName")]
				[Alias("sqlStatements")]
				[ValidateNotNullOrEmpty()]
				[PSCustomObject]$sqlCommands,
				[Parameter(Mandatory="true",
				ParameterSetName="FunctionName",
				HelpMessage = "Get the Function ID from the database by Function Name")]
				[string]$functionName,
				[Parameter(Mandatory=$true,
				ParameterSetName="FunctionID",
				HelpMessage = "System.Data.SqlClient.SqlCommand with connection open.",
				ValueFromPipeline=$true)]
				[Parameter(ParameterSetName="FunctionName",
				HelpMessage = "System.Data.SqlClient.SqlCommand with connection open.")]
				[Alias("sqlCmd")]
				[ValidateNotNullOrEmpty()]
				[System.Data.SqlClient.SqlCommand]$sqlClient<#,
				[Parameter(Mandatory="true",
					ParameterSetName="FunctionID",
					HelpMessage = "Printer object containing supply information to update/insert into database")]
				[Parameter(Mandatory="true",
					ParameterSetName="FunctionName",
					HelpMessage = "Printer object containing supply information to update/insert into database")]
				[Alias("printer")]
				[PSCustomObject]$printer#>
			)
			begin{
				$DS = New-Object System.Data.DataSet
				$DA = New-Object System.Data.SqlClient.SqlDataAdapter
				#$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
				#$dbConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
				#$sqlCmd.Connection = $dbConnection 
				#$sqlCmd.Connection.Open()
				#Get the Function ID
				if($getID){
					$sqlClient.CommandText = $sqlCommands.Select.functionByName -f $functionName
				}
				if($getName){
					$sqlClient.CommandText = $sqlCommands.Select.functionById -f $functionID
				}
				$DA.SelectCommand = $sqlClient
				$functionCount = $DA.Fill($DS)
				#$printerFunction = [PSCustomObject][ordered] @{}
				#$functionName = $null
				#$functionID = $null
			}
			process{
				#Get the function ID from the prtFunction table
				if ($functionCount -eq 1){
					if($getName){
						#$printerFunciton | Add-Member -MemberType NoteProperty -Name $($DS.Tables[0].Select("prtFunction = $ID").functionID.Guid) -Value $($DS.Tables[0].Select("prtFunction = $ID").prtFunction)
						try {
							$functionName = $DS.Tables[0].prtFunction.Name
						}
						catch {
							$DS.Clear()
							$DA.Dispose()
							#$sqlCmd.Dispose()
							#$dbConnection.Close()
							$_.ErrorDetails
						}
						
					}
					if($getID){
						try {
							$functionID = $DS.Tables[0].fID.GUID
						}
						catch {
							$DS.Clear()
							$DA.Dispose()
							#$sqlCmd.Dispose()
							#$dbConnection.Close()
							$_.ErrorDetails
						}
					}
					
				}else{
					try {
						#if we are getting 0 records, the Function isn't in the table.
						$sqlClient.CommandText = $sqlCommands.Insert.function -f $functionName
						$ErrorGlove += $sqlClient.ExecuteNonQuery()
						$functionID = Get-PrinterFunction -getID -functionName $functionName -sqlCommands $sqlCommands -sqlClient $sqlClient
					}
					catch {
						$DS.Clear()
						$DA.Dispose()
						#$sqlCmd.Dispose()
						#$dbConnection.Close()
						$_.ErrorDetails
					}
				}
			}
			end{
				$DS.Clear()
				$DA.Dispose()
				#$sqlCmd.Dispose()
				#$dbConnection.Close()
				if($getName){
					$functionName
				}
				if($getID){
					$functionID
				}
			}
		}

		function Get-PrinterAlert {
			[CmdletBinding(DefaultParameterSetName='AlertDesc')]
			param (
				[Parameter(Mandatory="true",
				ParameterSetName="AlertDesc",
				HelpMessage = "Flag to return Alert Description from DB")]
				[switch]$Descirption,
				[Parameter(Mandatory="true",
				ParameterSetName="AlertDesc",
				HelpMessage = "Get the Alert Description ID from the database by Alert Description")]
				[Alias("aDescription")]
				[string]$alertDesciption,
				[Parameter(Mandatory="true",
				ParameterSetName="AlertLevel",
				HelpMessage = "Flag to return the Alert Level from DB")]
				[switch]$Level,
				[Parameter(Mandatory="true",
				ParameterSetName="AlertLevel",
				HelpMessage = "Get the Alert Level ID from the database by Alert level")]
				[Alias("aLevel")]
				[string]$alertLevel,
				[Parameter(Mandatory=$true,
				ParameterSetName="AlertDesc",
				HelpMessage = "SQL statements for adding the printer objects to the database",
				ValueFromPipeline=$true)]
				[Parameter(Mandatory=$true,
				ParameterSetName="AlertLevel",
				HelpMessage = "SQL statements for adding the printer objects to the database")]
				[Alias("sqlstatements")]
				[ValidateNotNullOrEmpty()]
				[PSCustomObject]$sqlCommands,
				[Parameter(Mandatory=$true,
				ParameterSetName="AlertLevel",
				HelpMessage = "System.Data.SqlClient.SqlCommand with connection open.",
				ValueFromPipeline=$true)]
				[Parameter(ParameterSetName="AlertDesc",
				HelpMessage = "System.Data.SqlClient.SqlCommand with connection open.")]
				[Alias("sqlcmd")]
				[ValidateNotNullOrEmpty()]
				[System.Data.SqlClient.SqlCommand]$sqlClient
			)
			begin{
				$DS = New-Object System.Data.DataSet
				$DA = New-Object System.Data.SqlClient.SqlDataAdapter
				#$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
				#$dbConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
				#$sqlCmd.Connection = $dbConnection
				#$sqlCmd.Connection.Open()
				#Get the alert IDs
				if($Descirption){
					$sqlClient.CommandText = $sqlCommands.Select.alertDescByDesc -f $alertDesciption
				}
				if($Level){
					$sqlClient.CommandText = $sqlCommands.Select.alertLevelByLevel -f $alertLevel
				}
				$DA.SelectCommand = $sqlClient
				$AlertCount = $DA.Fill($DS)

			}
			process{
				#Get the Alert IDs from the alert table
				if ($AlertCount -eq 1){
					if($Descirption){
						try {
							$adID = $DS.Tables[0].adID.Guid
						}
						catch {
							$DS.Clear()
							$DA.Dispose()
							#$sqlCmd.Dispose()
							#$dbConnection.Close()
							$_.ErrorDetails
						}
					}
					if($Level){
						try {
							$alID = $DS.Tables[0].alID.Guid
						}
						catch {
							$DS.Clear()
							$DA.Dispose()
							#$sqlCmd.Dispose()
							#$dbConnection.Close()
							$_.ErrorDetails
						}
					}
					
				}else{
					try {
						if ($Descirption) {
							#if we are getting 0 records, the alert description isn't in the table.
							$sqlClient.CommandText = $sqlCommands.Insert.alertDescription -f $alertDesciption
							$ErrorGlove += $sqlClient.ExecuteNonQuery()
							$DS.Clear()
							$DA.Dispose()
							#$sqlCmd.Dispose()
							#$dbConnection.Close()
							$adID = Get-PrinterAlert -Descirption -alertDesciption $alertDesciption -sqlClient $sqlClient -sqlCommands $sqlCommands
						}
						if ($Level) {
							#if we are getting 0 records, the alert level isn't in the table.
							$sqlClient.CommandText = $sqlCommands.Insert.alertLevel -f $alertLevel
							$ErrorGlove += $sqlClient.ExecuteNonQuery()
							$DS.Clear()
							$DA.Dispose()
							#$sqlCmd.Dispose()
							#$dbConnection.Close()
							$alID = Get-PrinterAlert -Level -alertLevel $alertLevel -sqlClient $sqlClient -sqlCommands $sqlCommands
						}
					}
					catch {
						$DS.Clear()
						$DA.Dispose()
						#$sqlCmd.Dispose()
						#$dbConnection.Close()
						$_.ErrorDetails
					}
				}
			}
			end{
				if ($alertCount -eq 1){
					$DS.Clear()
					$DA.Dispose()
					#$sqlCmd.Dispose()
					#$dbConnection.Close()
				}
				if($Descirption){
					$adID
				}
				if($Level){
					$alID
				}
			}
		}

		function Get-PrinterSupplies {
			[CmdletBinding(DefaultParameterSetName='Supply')]
			param (
				[Parameter(Mandatory="true",
					ParameterSetName="Supply",
					HelpMessage = "Get the Alert Description ID from the database by Alert Description")]
				[Alias("sDescription")]
				[string]$supplyDescription,
				[Parameter(Mandatory=$true,
				ParameterSetName="Supply",
				HelpMessage = "SQL statements for adding the printer objects to the database",
				ValueFromPipeline=$true)]
				[Alias("sqlStatements")]
				[ValidateNotNullOrEmpty()]
				[PSCustomObject]$sqlCommands,
				[Parameter(Mandatory="true",
					ParameterSetName="Supply",
					HelpMessage = "Printer object containing supply information to update/insert into database")]
				[Alias("printerObject")]
				[PSCustomObject]$printer,
				[Parameter(ParameterSetName="Supply",
					Mandatory="true",
					HelpMessage = "Supply ID for the printer object")]
				[Alias("prtSID")]
				[string]$prtSupplyID,
				[Parameter(Mandatory=$true,
				ParameterSetName="Supply",
				HelpMessage = "System.Data.SqlClient.SqlCommand with connection open.",
				ValueFromPipeline=$true)]
				[Alias("sqlcmd")]
				[ValidateNotNullOrEmpty()]
				[System.Data.SqlClient.SqlCommand]$sqlClient
			)
			
			begin {
				$DS = New-Object System.Data.DataSet
				$DA = New-Object System.Data.SqlClient.SqlDataAdapter
				#$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
				$sqlClient.CommandText = $sqlCommands.Select.suppliesByDesc -f $supplyDescription
				#$dbConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
				#$sqlCmd.Connection = $dbConnection
				#$sqlCmd.Connection.Open()
				$DA.SelectCommand = $sqlClient
				$SupplyCount = $DA.Fill($DS)
			}
			
			process {
				if ($SupplyCount -eq 1) {
					$supplyID = $DS.Tables[0].Rows[0].supplyID.Guid
				}else{
					#returned no records -- Add the new Supply into the Table and return the new SupplyID
					# Insert Supplies (sClass, sDescription, sUnit, sMaxCapacity, sType, sColourantValue, sPartNumber)
					try {
						if ($printer.Manufacturer -like "*Canon*") {
							$sqlClient.CommandText = $sqlCommands.Insert.supplies -f $printer."supplyClass$prtSupplyID", $printer."supplyDescription$prtSupplyID", $printer."supplyUnit$prtSupplyID", `
								$printer."supplyMaxCapacity$prtSupplyID", $printer."supplyType$prtSupplyID", $printer."colourantValue$prtSupplyID", $null
							$ErrorGlove += $sqlClient.ExecuteNonQuery()
							$supplyID = Get-PrinterSupplies -supplyDescription $printer."supplyDescription$prtSupplyID" -sqlCommands $sqlCommands -printer $printer -prtSupplyID $prtSupplyID -sqlClient $sqlClient
							
						}elseIf ($printer.Manufacturer -like "*Lexmark*") {
							#INSERT INTO [cwPrtSupplies] (sClass, sDescription, sUnit, sMaxCapacity, sType, sColourantValue, sPartNumber)
							$sqlClient.CommandText = $sqlCommands.Insert.supplies -f $printer."lexmarkSupplyClass$prtSupplyID", $printer."supplyDescription$prtSupplyID", `
								$printer."lexmarkSupplyCapacityUnit$prtSupplyID", $printer."lexmarkSupplyMaxCapacity$prtSupplyID", $printer."supplyType$prtSupplyID", `
								$printer."lexmarkSupplyColorantValue$prtSupplyID", $printer."lexmarkSupplyPartNumber$prtSupplyID"
							$ErrorGlove += $sqlClient.ExecuteNonQuery()
							$supplyID = Get-PrinterSupplies -supplyDescription $printer."supplyDescription$prtSupplyID" -sqlCommands $sqlCommands -printer $printer -prtSupplyID $prtSupplyID -sqlClient $sqlClient
						}
					}
					catch {
						$_.ErrorDetails.Message
						$DS.Clear()
						$DA.Dispose()
						#$sqlCmd.Dispose()
						#$dbConnection.Close()
					}
				}
			}
			
			end {
				$DS.Clear()
				$DA.Dispose()
				#$sqlCmd.Dispose()
				#$dbConnection.Close()

				$supplyID
			}
		}

		function Set-PrinterSupplies {
			[CmdletBinding(DefaultParameterSetName="Supply")]
			param (
				#SuppliesID [rowID] to update the level of the supply
				[Parameter(ParameterSetName="Supply",
					Mandatory="true",
					HelpMessage = "Supply ID for the SupplyBridge Table")]
				[Alias("sID")]
				[string]$dbSupplyID,
				[Parameter(ParameterSetName="Supply",
					Mandatory="true",
					HelpMessage = "Current Printer Supply number 'supplyLevel(supplyID)'")]
				[Alias("Dataset")]
				[int]$prtSupplyID,
				[Parameter(ParameterSetName="Supply",
					Mandatory="true",
					HelpMessage="Installed date time for update.")]
				[Alias("Installed")]
				[datetime]$installDateTime,
				[Parameter(ParameterSetName="Canon")]
				[Parameter(ParameterSetName="Supply")]
				[Alias("C")]
				[switch]$Canon,
				[Parameter(ParameterSetName="Lexmark")]
				[Parameter(ParameterSetName="Supply")]
				[Alias("L")]
				[switch]$Lexmark,
				[Parameter(Mandatory=$true,
				ParameterSetName="Supply",
				HelpMessage = "SQL statements for adding the printer objects to the database",
				ValueFromPipeline=$true)]
				[Alias("sqlStatements")]
				[ValidateNotNullOrEmpty()]
				[PSCustomObject]$sqlCommands,
				[Parameter(Mandatory="true",
					ParameterSetName="Supply",
					HelpMessage = "Printer object containing supply information to update/insert into database")]
				[Alias("printerObject")]
				[PSCustomObject]$printer,
				[Parameter(ParameterSetName="Supply",
				HelpMessage = "System.Data.SqlClient.SqlCommand with connection open.")]
				[Alias("sqlcmd")]
				[ValidateNotNullOrEmpty()]
				[System.Data.SqlClient.SqlCommand]$sqlClient
			)
			
			begin {
				#$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
				#$dbConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
				#$sqlCmd.Connection = $dbConnection
				#$sqlCmd.Connection.Open()
			}
			
			process {
				if ($canon) {
					#prtSN, supplyID, sInstallDate, sLevel, sReplaceDate
					$sqlClient.CommandText = $sqlCommands.Insert.supplyBridgeCanon -f $printer.SerialNumber, $sID, $installDateTime, `
						$printer."supplyLevel$prtSupplyID"
				}
				If ($Lexmark) {
					#prtSN '{0}', supplyID '{1}', sInstallDate '{2}', sLevel {3}, sReplaceDate '{4}',
					#sSerialNumber '{5}', sCartridgeType '{6}', sPageCountAtInstall {7},
					#sSupplyStatus '{8}', sFirstKnownLevel {9}, sUsage {10},
					#sCalibrations {11}, sCoverage {12}, sDaysRemaining {13}
					if ('NULL' -notlike $printer."lexmarkSupplyInstallDate$prtSupplyID") {
						$sqlClient.CommandText = $sqlCommands.Insert.supplyBriLexNoReplDate -f `
							$printer.SerialNumber, $sID, $printer."lexmarkSupplyInstallDate$prtSupplyID", $printer."supplyLevel$prtSupplyID", `
							$printer."lexmarkSupplySerialNumber$prtSupplyID", $printer."lexmarkCartridgeType$prtSupplyID", $printer."lexmarkSupplyPageCountAtInstall$prtSupplyID", `
							$printer."lexmarkSupplyCurrentStatus$prtSupplyID", $printer."lexmarkSupplyFirstKnownLevel$prtSupplyID", $printer."lexmarkSupplyUsage$prtSupplyID", `
							$printer."lexmarkSupplyCalibrations$prtSupplyID", $printer."lexmarkSupplyCoverage$prtSupplyID", $printer."lexmarkSupplyDaysRemaining$prtSupplyID"
					}else{ # ('NULL' $printer."lexmarkSupplyInstallDate$prtSupplyID")
						$sqlClient.CommandText = $sqlCommands.Insert.supplyBridgeLexNullDate -f `
							$printer.SerialNumber, $sID, $printer."supplyLevel$prtSupplyID", $printer."lexmarkSupplySerialNumber$prtSupplyID", `
							$printer."lexmarkCartridgeType$prtSupplyID", $printer."lexmarkSupplyPageCountAtInstall$prtSupplyID", `
							$printer."lexmarkSupplyCurrentStatus$prtSupplyID", $printer."lexmarkSupplyFirstKnownLevel$prtSupplyID", $printer."lexmarkSupplyUsage$prtSupplyID", `
							$printer."lexmarkSupplyCalibrations$prtSupplyID", $printer."lexmarkSupplyCoverage$prtSupplyID", $printer."lexmarkSupplyDaysRemaining$prtSupplyID"
					}
				}
			}
			
			end {
				try {
					$sqlClient.ExecuteNonQuery()	
				}
				catch {
					$_.ErrorDetails.Message
				}
				#$sqlCmd.Dispose()
				#$dbConnection.Close()
			}
		}

		function Update-PrinterDataSet {
			[CmdletBinding()]
			param (
				[System.Data.SqlClient.SqlDataAdapter][ref]$printerDataAdapter,
				[System.Data.DataSet][ref]$printerDataSet
			)
			
			begin {
				$errors = ""
			}
			
			process {
				$errors += $printerDataAdapter.Fill($printerDataSet)
			}
			
			end {
				$errors
			}
		}
		function Get-snmpTicksToDate {
			param (
				[int]$ticks
			)
			get-date([long]((Get-Date).Ticks - ($ticks*100000))) -Format g
		}
		function Update-PrinterAlerts {
			[CmdletBinding(DefaultParameterSetName="Default")]
			param (
				[Parameter(Mandatory=$true,
				ParameterSetName="Default")]
				[string]$alertLevelID,
				[Parameter(Mandatory=$true,
				ParameterSetName="Default")]
				[string]$alertDescriptionID,
				[Parameter(ParameterSetName="Default",
				HelpMessage = "System.Data.SqlClient.SqlCommand with connection open.")]
				[Alias("sqlcmd")]
				[ValidateNotNullOrEmpty()]
				[System.Data.SqlClient.SqlCommand]$sqlClient,
				[Parameter(Mandatory=$true,
				ParameterSetName="Default")]
				[System.Data.DataSet][ref]$alertDataSet,
				[Parameter(Mandatory=$true,
				ParameterSetName="Default",
				HelpMessage = "SQL statements for adding the printer objects to the database",
				ValueFromPipeline=$true)]
				[Alias("sqlStatements")]
				[ValidateNotNullOrEmpty()]
				[PSCustomObject]$sqlCommands,
				[Parameter(Mandatory=$true,
				ParameterSetName="Default")]
				[PSCustomObject][ref]$printerCollection,
				[Parameter(Mandatory=$true,
				ParameterSetName="Default")]
				[Int64]$counter
			)
			
			begin {
				$updateDatabase = $false
				#$removeAlert = $true
				$dsFillError = $null
			}
			
			process {
				for ($i = 0; $i -le $alertDataSet[0].Tables[4].Rows.Count; $i++){
					if (($alertDataSet[0].Tables[4].Rows[$i].adID.Guid -like $alertDescriptionID) -AND ($alertDataSet[0].Tables[4].Rows[$i].alID.Guid -like $alertLevelID)){
						#update
						$updateDatabase = $true
						#$removeAlert = $false
						#snmpTicks'{1}' prtAlBrId'{0}'
						$sqlClient.CommandText = $sqlCommands.Update.alertTicks -f $alertDataSet[0].Tables[4].Rows[$i].prtAlBrId, $printerCollection.$("Alert$counter").Time
						try {
							$dsFillError += $sqlClient.ExecuteNonQuery()
						}
						catch {
							$dsFillError += "`nUpdate Alert Table Error: " + $_.ErrorDetails + "`n" + $_.Exception.Message + "`n" + $sqlClient.CommandText
						}
						$alertDataSet[0].Tables[4].Rows[$i].Delete()
						$alertDataSet[0].Tables[4].AcceptChanges()
						$printerCollection.PSObject.Properties.Remove($("Alert$counter"))
					}
				}
				if (!($updateDatabase)){
					#Add alert
					#(prtSN,alID,adID,snmpTicks,alertDate,clearDate(NULL))
					$sqlClient.CommandText = $sqlCommands.Insert.alertBridge -f $printerCollection.SerialNumber, $alertLevelID, $alertDescriptionID, $printerCollection.$("Alert$counter").Time, $(Get-snmpTicksToDate -ticks $printerCollection.$("Alert$counter").Time)
					try {
						$dsFillError += $sqlClient.ExecuteNonQuery()
					}
					catch {
						$dsFillError += "`nInsert Alert Table Error: " + $_.ErrorDetails + "`n" + $_.Exception.Message + "`n" + $sqlClient.CommandText
					}
					#$dsFillError += Update-PrinterDataSet -printerDataAdapter [ref] $ -printerDataSet [ref] $alertDataSet
				}
			}
			
			end {
				if ($null -ne $dsFillError) {
					#$cwDataset[0].Tables[4].Rows.Clear()
					$dsFillError
				}
			}
		}
		
		#Current Date Time
		$currentDateTime = [DateTime]$(Get-Date -Format g)

		$prtPropertyCount = ($fctPrinter[0] |  Measure-Object -Property * ).Count
		#$prtPropertyRank = $fctPrinter.Rank
		$Online = $fctPrinter.Online
		$prtErrorGlove = $null
		if ($prtPropertyCount -le 1){
			Throw "ERROR not enough Printer Information.`n" + $fctPrinter
			return
		}
		if($Online -and ($null -eq $fctPrinter.SerialNumber -or "Error" -like $fctPrinter.SerialNumber -and ("Not a Canon or Lexmark Printer" -notlike $fctPrinter.Error || $null -ne $fctPrinter.Error))){
			Throw "ERROR no serial number for device or SNMP get error.`n" + $fctPrinter
			return
		}

		#SQL Server details
		#Connect to SQL
		#$connectionString = '...'
		#Connection Obj Init
		$myConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
		# Data Set
		$cwDataSet = New-Object "System.Data.DataSet" "CWIT"
		$prtFunctionDataSet = New-Object "System.Data.DataSet" "CWIT"
		
		<#Setup a SQL Command #>
		$sqlCmd = $myConnection.CreateCommand()
		#Open the Connection
		$prtErrorGlove = $myConnection.Open()
	}
	
	process {
		if ($Online) {
			<#Data Adapter
			#>
			$cwDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($($sqlCommands.Select.All -f $fctPrinter.SerialNumber),$myConnection)
			#$prtErrorGlove += $cwDataAdapter.Fill($cwDataSet)
			$prtErrorGlove += Update-PrinterDataSet -printerDataAdapter ([ref]$cwDataAdapter) -printerDataSet ([ref]$cwDataSet)
			
			#If printer does not exsists Insert new Record
			<# Based on the Master Select 
			Table0 = Printer
			Table1 = PrtShares
			Table2 = PrtFunctBridge
			Table3 = PrtSupplyBridge
			Table4 = PrtAlertBridge
			To pull specific Data $DataSet.Table[0].sAMAccountName OR $DataSet.Table[3].FreeSpace
			#>
			# cwPrinter Table
			if ($cwDataset[0].Tables[0].Rows.Count -le 0) {
				#Insert new Record
				#(SN, SupportNumber, Location, Name, IPAddress, Model, UpTime, pOnine)
				try {
					$sqlCmd.CommandText = $sqlCommands.Insert.printer -f $fctPrinter.SerialNumber, $fctPrinter.supportNumber, $fctPrinter.Location, $fctPrinter.Name, $fctPrinter.IP, $fctPrinter.Model, $fctPrinter.SysUpTime, [int]$fctPrinter.Online
					$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
				}
				catch {
					$prtErrorGlove += "Printer Table--Insert New`n" + $sqlCmd.CommandText + "`n" + $_.Exception.Message +"`n"+ $_.ScriptStackTrace
				}
				try {
					#Insert ShareName
					#(prtSN,ShareName,HostingServer,Decommissioned)
					$sqlCmd.CommandText = $sqlCommands.Insert.prtShares -f $fctPrinter.SerialNumber, $fctPrinter.ShareName, $fctPrinter.ServerName, [int]0
					$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
				}
				catch {
					$prtErrorGlove += "Printer Table--Insert Sharename`n"+ $sqlCmd.CommandText +"`n"+ $_.Exception.Message +"`n"+ $_.ScriptStackTrace
				}
			}else{
				if ($fctPrinter.supportNumber -notlike $cwDataSet[0].Tables[0].SupportNumber) {
					try {
						#update Printer RD
						$sqlCmd.CommandText = $sqlCommands.Update.rdNumber -f $fctPrinter.SerialNumber, $fctPrinter.supportNumber
						$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
					}
					catch {
						$prtErrorGlove += "Printer Table--Update Printer RD`n"+ $sqlCmd.CommandText +"`n"+ $_.Exception.Message +"`n"+ $_.ScriptStackTrace
					}
				}
				if ($fctPrinter.ShareName -notlike $cwDataSet[0].Tables[1].ShareName){
					try {
						#Update ShareName
						$sqlCmd.CommandText = $sqlCommands.Update.shareName -f $fctPrinter.SerialNumber, $fctPrinter.ShareName, $fctPrinter.ServerName
						$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
					}
					catch {
						$prtErrorGlove += "Printer Table--Update Sharename`n"+ $sqlCmd.CommandText +"`n"+ $_.Exception.Message +"`n"+ $_.ScriptStackTrace
					}
				}
				if ($fctPrinter.Location -notlike $cwDataSet[0].Tables[0].Location){
					try {
						#Udpate location
						$sqlCmd.CommandText = $sqlCommands.Update.location -f $fctPrinter.SerialNumber, $fctPrinter.Location
						$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
					}
					catch {
						$prtErrorGlove += "Printer Table--Update Location`n"+ $sqlCmd.CommandText +"`n"+ $_.Exception.Message +"`n"+ $_.ScriptStackTrace
					}
				}
				if ($fctPrinter.IP -notlike $cwDataSet[0].Tables[0].IPAddress){
					try {
						#update IpAddress
						$sqlCmd.CommandText = $sqlCommands.Update.ipAddr -f $fctPrinter.SerialNumber, $fctPrinter.IP
						$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
					}
					catch {
						$prtErrorGlove += "Printer Table--Update IpAddress`n"+ $sqlCmd.CommandText +"`n"+ $_.Exception.Message +"`n"+ $_.ScriptStackTrace
					}
				}
			}
			# cwPrtTotals

			#Update Totals
			#$sqlCmd.CommandText = $prtUpdateprtTotals -f $fctPrinter.SerialNumber, [int]$fctPrinter.Total, [int]$fctPrinter.TotalBW, [int]$fctPrinter.TotalColour, $currentDateTime
			if ($fctPrinter.Manufacturer -notlike '*Canon*') {
				$sqlCmd.CommandText = $sqlCommands.Insert.totals -f $fctPrinter.SerialNumber, [int]$fctPrinter.Total, [int]$fctPrinter.TotalBW, [int]$fctPrinter.TotalColour, $currentDateTime
				try {
					$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
				}
				catch {
					$prtErrorGlove += "Printer Table--Insert Totals`n"+ $sqlCmd.CommandText +"`n"+ $_.Exception.Message +"`n"+ $_.ScriptStackTrace
				}
			}else{
				#([prtSN],[Total],[TotalBW],
				#[TotalColour],[total1],[total2],[totalLarge],[totalSmall],[totalBlack1],[totalSingleColorLarge],[totalSingleColorSmall],[totalBlackLarge],
				#[totalBlackSmall],[total1_2Sided],[totalSingleColor1],[totalFullColorSingleColorLarge],[totalFullColorSingleColorSmall],[totalA2],
				#[totalABlack2],[totalAFullColorSingleColor2],[copyTotal1],[copyTotal2],[copyLarge],[copyBlack2],[copyFullColorSingleColorLarge],
				#[copyFullColorSingleColorSmall],[copyFullColorSingleColor2],[copyFullColorSingleColor1],[printTotal1],[printFullColorSingleColorLarge],
				#[printFullColorSingleColorSmall],[printFullColorSingleColor1],[copyPrintFullColorLarge],[copyPrintFullColorSmall],[scanTotal1],
				#[receivePrintTotal1],[receivePrintTotal2],[receivePrintFullColorLarge],[receivePrintFullColorSmall],[receivePrintBlackLarge],
				#[receivePrintBlackSmall],[receivePrintBlackLarge2Sided],[receivePrintBlackSmall2Sided],[Date])
				$sqlCmd.CommandText = $sqlCommands.Insert.canonTotals -f $fctPrinter.SerialNumber, [Int32]$fctPrinter.bTotal1, [Int32]$fctPrinter.bTotalBW1, `
					[Int32]$fctPrinter.bTotalColour, [Int32]$fctPrinter.total1, [Int32]$fctPrinter.total2, [Int32]$fctPrinter.totalLarge, `
					[Int32]$fctPrinter.totalSmall, [Int32]$fctPrinter.totalBlack1, [Int32]$fctPrinter.totalSingleColorLarge, [Int32]$fctPrinter.totalSingleColorSmall, `
					[Int32]$fctPrinter.totalBlackLarge, [Int32]$fctPrinter.totalBlackSmall, [Int32]$fctPrinter.total1_2Sided, [Int32]$fctPrinter.totalSingleColor1, `
					[Int32]$fctPrinter.totalFullColorSingleColorLarge, [Int32]$fctPrinter.totalFullColorSingleColorSmall, [Int32]$fctPrinter.totalA2, `
					[Int32]$fctPrinter.totalABlack2, [Int32]$fctPrinter.totalAFullColorSingleColor2, [Int32]$fctPrinter.copyTotal1, [Int32]$fctPrinter.copyTotal2, `
					[Int32]$fctPrinter.copyLarge, [Int32]$fctPrinter.copyBlack2, [Int32]$fctPrinter.copyFullColorSingleColorLarge, [Int32]$fctPrinter.copyFullColorSingleColorSmall, `
					[Int32]$fctPrinter.copyFullColorSingleColor2, [Int32]$fctPrinter.copyFullColorSingleColor1, [Int32]$fctPrinter.printTotal1, `
					[Int32]$fctPrinter.printFullColorSingleColorLarge, [Int32]$fctPrinter.printFullColorSingleColorSmall, [Int32]$fctPrinter.printFullColorSingleColor1, `
					[Int32]$fctPrinter.copyPrintFullColorLarge, [Int32]$fctPrinter.copyPrintFullColorSmall, [Int32]$fctPrinter.scanTotal1, [Int32]$fctPrinter.receivePrintTotal1, `
					[Int32]$fctPrinter.receivePrintTotal2, [Int32]$fctPrinter.receivePrintFullColorLarge, [Int32]$fctPrinter.receivePrintFullColorSmall, `
					[Int32]$fctPrinter.receivePrintBlackLarge, [Int32]$fctPrinter.receivePrintBlackSmall, [Int32]$fctPrinter.receivePrintBlackLarge2Sided, `
					[Int32]$fctPrinter.receivePrintBlackSmall2Sided,$currentDateTime
				try {
					$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
				}
				catch {
					$prtErrorGlove += "Insert Totals`n"+ $sqlCmd.CommandText +"`n"+ $_.Exception.Message +"`n"+ $_.ScriptStackTrace
				}
			}

			# cwPrtFunction
			if ($cwDataset[0].Tables[2].Rows.Count -le 0) {
				#Insert new Record
				for ($i = 1; $i -le $fctPrinter.FunctionCount; $i++) {
					try {
						#Generate the variable name
						$prtFnct = "Function$i"
						#Get the Function ID
						$functionID = Get-PrinterFunction -getID -functionName $($fctPrinter.$prtFnct) -sqlCommands $sqlCommands -sqlClient $sqlCmd
						#Insert the printers functions
						$sqlCmd.CommandText = $sqlCommands.Insert.functBridge -f $fctPrinter.SerialNumber, $functionID
						$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
						<#}else{
							$sqlCmd.CommandText = $sqlCommands.Insert.functBridge -f $fctPrinter.SerialNumber, $prtFunctionDataSet.Tables[0].functionID
							$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
						}#>
						
					}
					catch {
						$prtErrorGlove += "Insert Function`n"+ $sqlCmd.CommandText +"`n"+ $_.Exception.Message +"`n"+ $_.ScriptStackTrace
					}
				} 
			}Else{
				# Functions Table[2]
				if ($cwDataSet[0].Tables[2].Rows.Count -ne $fctPrinter.FunctionCount){
					for ($i = 1; $i -le $fctPrinter.FunctionCount; $i++) {
						try {
							$prtFnct = "Function$i"
							$functionID = Get-PrinterFunction -getID -functionName -sqlCommands $sqlCommands -sqlClient $sqlCmd
							# if the prtFunctBridge doesn't have the function assosiated with the printer SN Add it to the functionBridge table
							if ($null -eq ($cwDataSet[0].Tables[2].Select("fID = '$functionID'").fID.GUID)){
								#Get the Function ID
								#$functionID = Get-PrinterFunction -getID -functionName $($fctPrinter.$prtFnct) -sqlCommands $sqlCommands -sqlClient $sqlCmd
								$sqlCmd.CommandText = $sqlCommands.Update.functBridge -f $fctPrinter.SerialNumber, $functionID
								$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
							}
						}
						catch {
							$prtErrorGlove += "Functions `n"+ $sqlCmd.CommandText +"`n"+ $_.Exception.Message +"`n"+ $_.ScriptStackTrace
						}
					}
				}
			}
			
			# cwPrtAlerts Table[4]
			# Does the printer have alerts?
			if (0 -lt $fctPrinter.AlertCount){
				for ($i = 0; $i -lt $fctPrinter.AlertCount; $i++) {
					#Get the DB ID's for the printers alerts.
					# Alert Level ID
					$alertLevelID = Get-PrinterAlert -Level -alertLevel $fctPrinter.$("Alert$i").Level -sqlCommands $sqlCommands -sqlClient $sqlCmd
					# Alert Desc ID
					$alertDescID = Get-PrinterAlert -Descirption -alertDesciption $fctPrinter.$("Alert$i").Description -sqlCommands $sqlCommands -sqlClient $sqlCmd
					# Does the DB have any alerts registered?
					If ($cwDataSet[0].Tables[4].Rows.Count -le 0) {
						# Add alert(s) into database
						$alertStartDate = Get-snmpTicksToDate -ticks $fctPrinter.$("Alert$i").Time
						$sqlCmd.CommandText = $sqlCommands.Insert.alertBridge -f $fctPrinter.SerialNumber, $alertLevelID, $alertDescID, $fctPrinter.$("Alert$i").Time, $alertStartDate
						try {
							$prtErrorGlove += $sqlCmd.ExecuteNonQuery() #TryCatch
						}
						catch {
							$prtErrorGlove += "`nAlert table error: " + $_.ErrorDetails + "`n" + $sqlCmd.CommandText
						}
					}else{
						# Database has open alerts for this printer.
						# Do we have more in the DB than the printer
						$prtErrorGlove += Update-PrinterAlerts -alertLevelID $alertLevelID -alertDescriptionID $alertDescID -sqlClient $sqlCmd -sqlCommands $sqlCommands -alertDataSet ([ref] $cwDataSet) -printerCollection ([ref] $fctPrinter) -counter $i
					}
				}
			}
			# We have process all the printers alerts
			# Check so see how many the DataSet has left, and close them.
			if (0 -lt $cwDataSet[0].Tables[4].Rows.Count) {
				for ($i = 0; $i -lt $cwDataSet[0].Tables[4].Rows.Count; $i++) {
					$sqlCmd.CommandText = $sqlCommands.Delete.clearAlert -f $cwDataSet[0].Tables[4].Rows[$i].prtAlBrId, $currentDateTime
					try {
						$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
					}
					catch {
						$prtErrorGlove += "`nClearing Alerts error: " + $_.ErrorDetails + "`n" + $sqlCmd.CommandText
					}
					$cwDataSet[0].Tables[4].Rows[$i].Delete()
					$cwDataSet[0].Tables[4].AcceptChanges()
				}
			}

			<# Supplies Table[3] #>
			if ($cwDataset[0].Tables[3].Rows.Count -le 0) {
				<# no entried in the table, Add a new row
				# Supply Table (sClass, sDescription, sUnit, sMaxCapacity, sType, sColourantValue, sPartNumber)
				# Supplies Table [cwPrtSupplyBridge]
				#	Canon INSERT supplyBridge (prtSN, supplyID, sInstallDate, sLevel, sReplaceDate) 
				#	Lexmark INSERT supplyBridgeLexmark (prtSN, supplyID, sInstallDate, sLevel, sReplaceDate, sSerialNumber, sCartridgeType, sPageCountAtInstall, 
				#			sSupplyStatus, sFirstKnownLevel, sCurrentLevel, sUsage, sCalibrations, sCoverage, sDaysRemaining)
				#>
				try {
					for ($i = 1; $i -le $fctPrinter.supplyCount; $i++) { # Supplies for the printer
						#Get Supply ID
						$sID = Get-PrinterSupplies -supplyDescription $fctPrinter."supplyDescription$i" -sqlCommands $sqlCommands -printer $fctPrinter -prtSupplyID $i -sqlClient $sqlCmd
						if ($fctPrinter.Manufacturer -like "*Canon*") {
							$ErrorGlove += Set-PrinterSupplies -Canon -dbSupplyID $sID -prtSupplyID $i -installDateTime $currentDateTime -sqlCommands $sqlCommands -printer $fctPrinter -sqlClient $sqlCmd
						}elseif ($fctPrinter.Manufacturer -like "*Lexmark*") {
							$ErrorGlove += Set-PrinterSupplies -Lexmark -dbSupplyID $sID -prtSupplyID $i -installDateTime $currentDateTime -sqlCommands $sqlCommands -printer $fctPrinter -sqlClient $sqlCmd
						} else {
							$ErrorGlove += "Manufacturer not configured: " + $fctPrinter.Manufacturer
						}
					}
				}
				catch {
					$prtErrorGlove += "Add New Supplies`nSQL: "+ $sqlCmd.CommandText +"`nError: "+ $_.Exception.Message +"`nStack trace:"+ $_.ScriptStackTrace
				}
			}else{ # We have records in the supply Bridge. We will need to update the Levels, and if higher then last update, change the installed date, and removaldate.
				try {
					for ($i = 1; $i -le $fctPrinter.supplyCount; $i++) { # Supplies for the printer
						#Get Supply ID
						$sID = Get-PrinterSupplies -supplyDescription $fctPrinter."supplyDescription$i" -sqlCommands $sqlCommands -printer $fctPrinter -prtSupplyID $i -sqlClient $sqlCmd
						for ($y = 0; $y -lt $cwDataset[0].Tables[3].Rows.Count; $y++) { #Supplies in the DB for printer
							if ($cwDataset[0].Tables[3].Rows[$y].supplyID -like $sID) {
								#Get the Database Supply Level
								$supplyLevel = [Int32]$cwDataset[0].Tables[3].Select("supplyID = '$sID'").sLevel
								#Is the Database Supply level less then the current supply level, New Supply
								if($supplyLevel -lt $fctPrinter."supplyLevel$i"){ 
									if ($fctPrinter.Manufacturer -like "*Canon*") {
										#Canon update sLevel = {2}, sReplaceDate = {3} WHERE prtSN LIKE '{0}' AND suppliesID = {1}
										# update old supply entry.
										$sqlCmd.CommandText = $sqlCommands.Update.supplyBridge -f $fctPrinter.SerialNumber, $sID, $supplyLevel, "'$currentDateTime'"
										try {
											$ErrorGlove += $sqlCmd.ExecuteNonQuery()
										}
										catch {
											$ErrorGlove += "Supplies Bridge update error: " + $sqlCmd.CommandText + "`n" + $_.ErrorDetails + "`n" + $_.Exception.Message
										}
										#Create new entry for the new supply
										$ErrorGlove += Set-PrinterSupplies -Canon -dbSupplyID $sID -prtSupplyID $i -installDateTime $currentDateTime -sqlCommands $sqlCommands -sqlClient $sqlCmd
									}elseif ($fctPrinter.Manufacturer -like "*Lexmark*") {
										#Lexmark
										#sLevel = {2}, sReplaceDate = '{3}', sSupplyStatus = '{4}', sUsage = {5}, sCalibrations = {6}, sDaysRemaining = {7}
										# WHERE prtSN LIKE '{0}' AND suppliesID = {1}
										$sqlCmd.CommandText = $sqlCommands.Update.supplyBridgeLexmark -f $fctPrinter.SerialNumber, $sID, $supplyLevel, $currentDateTime, `
											$fctPrinter."lexmarkSupplyCurrentStatus$i", $fctPrinter."lexmarkSupplyUsage$i", $fctPrinter."lexmarkSupplyCalibrations$i", `
											$fctPrinter."lexmarkSupplyDaysRemaining$i"
										try {
											$ErrorGlove += $sqlCmd.ExecuteNonQuery()
										}
										catch {
											$ErrorGlove += "Supplies Bridge Lexmark update error: " + $sqlCmd.CommandText + "`n" + $_.ErrorDetails + "`n" + $_.Exception.Message
										}
										#Add the new Supply to the table
										$ErrorGlove += Set-PrinterSupplies -Lexmark -dbSupplyID $sID -prtSuppyID $i -installDateTime $currentDateTime -sqlCommands $sqlCommands -sqlClient $sqlCmd
									}
								} else { #The supply is not new, adjust the level
									if ($fctPrinter.Manufacturer -like "*Canon*") {
										$sqlCmd.CommandText = $sqlCommands.Update.supplyBridge -f $fctPrinter.SerialNumber, $sID, $fctPrinter."supplyLevel$i", 'NULL'
										try {
											$ErrorGlove += $sqlCmd.ExecuteNonQuery()
										}
										catch {
											$ErrorGlove += "Supplies Bridge Canon update error: " + $sqlCmd.CommandText + "`n" + $_.ErrorDetails + "`n" + $_.Exception.Message
										}
									}
									if ($fctPrinter.Manufacturer -like "*Lexmark*") {
										#sLevel = {2}, sReplaceDate = '{3}', sSupplyStatus = '{4}', sUsage = {5}, sCalibrations = {6}, sDaysRemaining = {7}
										#WHERE prtSN LIKE '{0}' AND supplyID = {1} AND sReplaceDate IS NULL
										$sqlCmd.CommandText = $sqlCommands.Update.supplyBridgeLexNoReplDate -f $fctPrinter.SerialNumber, $sID, $fctPrinter."supplyLevel$i", "NULL", `
											$fctPrinter."lexmarkSupplyCurrentStatus$i", $fctPrinter."lexmarkSupplyUsage$i", $fctPrinter."lexmarkSupplyCalibrations$i", `
											$fctPrinter."lexmarkSupplyDaysRemaining$i"
										try {
											$ErrorGlove += $sqlCmd.ExecuteNonQuery()
										}
										catch {
											$ErrorGlove += "Supplies Bridge Lexmark NoReplaceDate update error: " + $sqlCmd.CommandText + "`n" + $_.ErrorDetails + "`n" + $_.Exception.Message
										}
									}
								}
							}
						}
					}
				}
				catch {
					$prtErrorGlove += "Update Supplies`nSQL: "+ $sqlCmd.CommandText +"`nError: "+ $_.Exception.Message +"`nStack trace:"+ $_.ScriptStackTrace
				}
			}
		}else{
			#------------ Printer is Offline -------------------
			<#Data Adapter
			#>
			
			try {
				$cwDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($($sqlCommands.Select.printerOffline -f $fctPrinter.IP, $fctPrinter.SerialNumber),$myConnection)
				#$prtErrorGlove += $cwDataAdapter.Fill($cwDataSet)
				$prtErrorGlove += Update-PrinterDataSet -printerDataAdapter ([ref] $cwDataAdapter) -printerDataSet ([ref] $cwDataSet)
			}
			catch {
				$prtErrorGlove += "Data Adapter fill: " + $($sqlCommands.Select.printerOffline -f $fctPrinter.IP, $fctPrinter.SerialNumber) +"`n"+ $_.Exception.Message + "`n" + $_.ScriptStackTrace
			}
			
			try {
				#Update Printer, if Online status has changed
				#Run Check our Select ONLINE Where IP = $printer.ip, Less then 1 row or 0.
				if ($cwDataSet[0].Tables[0].Rows.Count -lt 1){
					try {
						#Insert printer to be Offline in printer table
						#(SN, SupportNumber, Location, Name, IPAddress, Model, UpTime, pOnline)
						$sqlCmd.CommandText = $sqlCommands.Insert.printer -f $fctPrinter.SerialNumber, $fctPrinter.supportNumber, $fctPrinter.Location, $fctPrinter.Name, $fctPrinter.IP, $fctPrinter.Model, $fctPrinter.SysUpTime, [int]$fctPrinter.Online
						$prtErrorGlove += $sqlCmd.ExecuteNonQuery()

						#update Share Table
						#(prtSN,ShareName,HostingServer,Decommissioned)
						$sqlCmd.CommandText = $sqlCommands.Insert.prtShares -f $fctPrinter.SerialNumber, $fctPrinter.ShareName,$fctPrinter.ServerName, 0
						$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
					}
					catch {
						$prtErrorGlove += "Insert Printer if Online/Offline: " + $sqlCmd.CommandText +"`n"+ $_.Exception.Message + "`n" + $_.ScriptStackTrace
					}
				# More that 1 row returned.
				# check ONLINE state in Database to $printer Object
				# if the printer is ONINE in database, update to OFFLINE
				}elseif($cwDataset[0].Tables[0].pOnline -ne $fctPrinter.Online) {
					try {
						$sqlCmd.CommandText = $sqlCommands.Update.Online -f $fctPrinter.SerialNumber, [int]$fctPrinter.Online
						$prtErrorGlove += $sqlCmd.ExecuteNonQuery()
					}
					catch {
						$prtErrorGlove += "Update Printer if Online/Offline: " + $sqlCmd.CommandText +"`n"+ $_.Exception.Message + "`n" + $_.ScriptStackTrace
					}
				}
			}
			catch {
				$prtErrorGlove += $_.Exception.Message + "`n" + $_.ScriptStackTrace + "`n" + $sqlCmd.CommandText
				$myConnection.Close()
			}
		}
	}
	
	end {
		$cwDataSet.Clear()
		$prtFunctionDataSet.Clear()
		$myConnection.Close()
		if ($null -ne $prtErrorGlove){
			"Function Set-CWITPrinter: " + $fctPrinter.Name + " - Error Glove: " + $prtErrorGlove
		}
	}
}
# -- Function Get Printer information via SNMP
function Get-PrinterSNMP{
	<#
	.SYNOPSIS
		Get Printer information from the network via SNMP.
	.PARAMETER snmpCommunityName
		Type: String. Default: public. This is the community string used for SNMP.
	.PARAMETER printerObject
		Type: PSCustomObject. Object returned from the function Get-cwPrinters
		Properties: Name, Server, IP
	.PARAMETER logFile
		Type: String. the location of the log file to log to.
	.PARAMETER OIDObject
		Type: PSCustomObject. contains the OID name and the oid path.
		i.e. json format = "Name":"system.sysName.0"
		i.e. ps format $OIDArray.General.Name, $OIDArray.Lexmark.snmpGet.Total, $OIDArray.Lexmark.snmpGetTree.Functions (Index)
		GetTree are index fields in MIBS, they can be used to then GET the list thier index.
		I.E. Gives the index to look up for the following entries in prtAlertEntry
		.iso.org.dod.internet.mgmt.mib-2.printmib.prtAlert.prtAlertTable.prtAlertEntry.prtAlertIndex.1
		Example 1,29,408
		AlertSeverityLevel.1.[indexNumber]
		$snmpResults[0,1] = OID [string] i.e. printmib.prtAlert.prtAlertTable.prtAlertEntry.prtAlertIndex.1.29
		$snmpResults[1,1] = Index Number [int] i.e. 29
	.OUTPUTS
		Printer Report, Type: PSCustomObject [Orderd], Contains all the details gathered about the printer.
	.EXAMPLE
		$myPrinterReport = Get-PrinterSNMP -snmpCommunityName "printers" -logFile "C:\Temp\LogMe.txt" -printerObject $printerObject
	#>
	[CmdletBinding(DefaultParameterSetName='Default')]
	param (
		[Parameter(Mandatory=$false,
		ParameterSetName="Default",
		HelpMessage="SNMP Community Name. Default 'public'")]
		[Alias("commName")]
		[ValidateNotNullOrEmpty()]
		[string]$snmpCommunityName = "public",
		[Parameter(Mandatory=$false,
		ParameterSetName="Default",
		HelpMessage="Printer object from Get-cwPrinters. PSCustomObject")]
		[Alias("Printer")]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$printerObject,
		[Parameter(Mandatory=$false,
		ParameterSetName="Default",
		HelpMessage="OID object from a json file converted to PSCustomObject")]
		[Alias("OID")]
		[ValidateNotNullOrEmpty()]
		[PSCustomObject]$OIDArray,
		[Parameter(Mandatory=$false,
		ParameterSetName="Default",
		HelpMessage="Log file.")]
		[Alias("log")]
		[ValidateNotNullOrEmpty()]
		[string]$logFile
	)
	Begin{
		#SNMP object
		$snmp = New-Object -ComObject olePrn.OleSNMP
		#$snmp.open(IP/hostname,SNMPName,Retrys,Timeout)
		#Example $snmp.open('xxx.xxx.xxx.xxx','public',2,1000)
		<#
		$SNMP = New-Object -ComObject olePrn.OleSNMP
		$snmp.open(‘host’,’community string’,attempts#,timeout(ms))
		$snmp.get(‘an oid’)
		#>
		
		function Get-snmpDateAndTime {
			[CmdletBinding(DefaultParameterSetName='Default')]
			param (
				[Parameter(Mandatory=$true,
				ParameterSetName='Default',
				HelpMessage="Character array / String returned by SNMP")]
				[string]$snmpDateAndTime
			)
			
			begin {
				#Generate a Hex array from the Character Array
				try {
					$hexArray = [System.BitConverter]::ToString($snmpDateAndTime.ToCharArray() )
					# remove the '-' from the returned output
					$hexArray = $hexArray.Split('-')
				}
				catch {
					$_.ErrorDetails.Message
				}
				if ($hexArray.Count -eq 7){
					$year = [Int32]("0x" + $hexArray[0] + $hexArray[1])
					$month = [Int32]("0x"+$hexArray[2])
					$day = [Int32]("0x"+$hexArray[3])
					$hours = [Int32]("0x"+$hexArray[4])
					$minutes = [Int32]("0x"+$hexArray[5])
					$seconds = [Int32]("0x"+$hexArray[6])
					$milSec = [Int32]("0x"+$hexArray[7])
				}
				$formatedDate = ''
			}
			
			process {
				#Get-Date($([Int32]("0x" + $test[0] + $test[1])).ToSTring() + "-" + $([Int32]("0x"+$test[2])).Tostring() + "-" + $([Int32]("0x"+$test[3])).Tostring() + ","
				# + $([Int32]("0x"+$test[4])).Tostring() + ":" + $([Int32]("0x"+$test[5])).Tostring() + ":" + $([Int32]("0x"+$test[6])).Tostring() + "." + $([Int32]("0x"+$test[7])).Tostring())
				try {
					$formatedDate = Get-Date($year.ToString() + "-" + $month.ToString() + "-" + $day.ToString() + ","`
						 + $hours.ToString() + ":" + $minutes.ToString() + ":" + $seconds.ToString() +"."+ $milSec.ToString())
				}
				catch {
					$_.ErrorDetails.Message
				}
			}
			
			end {
				$formatedDate
			}
		}
		function Get-SupportNumber {
			[CmdletBinding(DefaultParameterSetName='Default')]
			param (
				# Parameter help description
				[Parameter(Mandatory=$true,
				ParameterSetName='Default',
				HelpMessage="String to check for support number")]
				#[ValidateNotNull]
				[string][ref]$checkString
			)
			
			begin {
				$printerSupportNumber = $null
				#[string] $remains = ''
			}
			
			process {
			#Check if we had an RD number (Support Number) for this printer
			#($fctPrinter.Name.Split('RD')).Count -gt 1
            # TODO -------- Read support number in from JSON file --------
				if ($checkString -match "RD\d{5,}") {
					$printerSupportNumber = $Matches.0
					#$prtSupportNumber = "RD" + $fctPrinter.Name.Split('RD')[1]
					$checkString = $checkString.Split('RD')[0].Trim()
				}else{
					#if not mark it as ITHELP managed
					$printerSupportNumber = $null
					#$remains = $checkString
				}
			}
			
			end {
				return $printerSupportNumber
			}
		}
		<#
		Get-SNMPProperty -snmpGetTree [flag] -IndexOID $supplyIndexOID [hashtable] -OIDGroup $supplyGroupOID [Hashtable] -ErrorLog $logfile [filepath] -CollectionObject [REF] $printerObjectCollection [PSCustomObject/Hashtable]
		Get-SNMPProperty -snmpGet [flag] -OIDGroup $printerGeneralOID -ErrorLog $logfile [filepath] -CollectionObject $printerCollection [PSCustomObject/Hashtable]
		#>
		function Get-snmpProperty {
			<#
			.SYNOPSIS
				Used to get the value from an OID and if there is an error, log it.
			.PARAMETER oid
				The oid to retrieve. User either number or name, exept if in the private tree.
			.PARAMETER logFile
				Log file PATH to log any errors
			.PARAMETER oidOnError
				If the first OID throws an error, because it doesn't exsits, try this OID
			.PARAMETER ErrorOID
				On recieving an error on retrieving the first OID retrieve this OID
			.PARAMETER getTree
				Use to walk a mib tree, index property. Send an OID with a . at the end
			.OUTPUTS
				Returns an array retrieved from the OID. Process results as you see fit.
			#>
			[CmdletBinding(DefaultParameterSetName='Default')]
			param (
				# OID to retrieve
				[Parameter(Mandatory=$true,
				ParameterSetName='Default',
				HelpMessage="OID to get from open SNMP connection")]
				[Parameter(Mandatory=$true,
				ParameterSetName='oidError',
				HelpMessage="Log file path for errors")]
				[Alias('oidstring')]
				[string]$oid,
				[Parameter(Mandatory=$true,
				ParameterSetName='Default',
				HelpMessage="Log file path for errors")]
				[Parameter(Mandatory=$true,
				ParameterSetName='oidError',
				HelpMessage="Log file path for errors")]
				[Alias('Log')]
				[string]$logFile,
				[Parameter(Mandatory=$true,
				ParameterSetName='oidError',
				HelpMessage="OID to use if the first OID throws and error.")]
				[Alias('OIDErrorFlag')]
				[switch]$oidOnError,
				[Parameter(Mandatory=$true,
				ParameterSetName='oidError',
				HelpMessage="Log file path for errors")]
				[Alias('ErrorOIDString')]
				[string]$ErrorOID,
				[Parameter(ParameterSetName='Default',
				HelpMessage="snmp Get Tree or Walk the OID. This will return an Index array, Count it to find how many OID attributes are in the group.")]
				[Parameter(ParameterSetName='oidError',
				HelpMessage="snmp Get Tree or Walk the OID. This will return an Index array, Count it to find how many OID attributes are in the group.")]
				[Alias('snmpGetTree')]
				[switch]$getTree
			)
			
			begin {
				
			}
			
			process {
				Try{
					if (!$getTree) {
						#Trim all OID information to remove any unexpected spaces.
						$results = ($snmp.Get( ([string] $oid).Trim() ))
						if ($results.GetType().Name -like '*String*') {
							$results = $results.Trim()
						}
						#[System.Management.Automation.MethodException]
						#[System.Runtime.InteropServices.COMException]
					}else{
						$results = ($snmp.GetTree(([string] $oid).Trim() ))
					}
				}Catch {
					if ($oidOnError -AND !$getTree) {
						$results = Get-snmpProperty -oid $ErrorOID -logFile $logFile
					}elseif ($oidOnError -AND $getTree) {
						$results = Get-snmpProperty -oid $ErrorOID -logFile $logFile -getTree
					}else{
						$_.Exception.Message + "`n" + $_.ScriptStackTrace | Add-Content $logFile
						$results = "ERROR"
					}
				}
			}
			
			end {
				if ($getTree) {
					#https://stackoverflow.com/questions/7833317/powershell-multidimensional-array-as-return-value-of-function/7834213#7834213?newreg=ae1957fb2a22414280fc0f70a7f015a3
					#https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.3
					, $results
				}else{
					$results
				}
			}
		}
		#Generate Print report Variable
		$printerReport = [PSCustomObject][ordered] @{}
		
		# Enumerators for SNMP
		enum generalSupplyClass {
			other = 1
			supplyThatIsConsumed = 3
			receptacleThatIsFilled = 4
		}
		enum generalCanonSupplyType {
			adfMaintenance = 1
			toner = 3
			wasteToner = 4
			drumUnit = 9
			fuserUnit = 15
			cToner = 21
		}
		enum generalLexmarkSupplyType {
			imagingUnit = 1
			toner = 3
			maintenanceKit = 15
		}
		enum lexmarkSupplyType {
			unknown = 1
			other = 2
			inkCartridge = 3
			inkBottle = 4
			inkPrinthead = 5
			toner = 6
			photoconductor = 7
			transferModule = 8
			fuser = 9
			wastetonerBox = 10
			staples = 11
			holepunchBox = 12
			tonerMicr = 13
			photoconductorMicr = 14
		}
		enum lexmarkSupplyUnit {
			unknown = 1
			other = 2
			items = 3
			sides = 4
			sheets = 5
			millimeters = 16
			centimeters = 17
			meters = 18
			inches = 19
			feet = 20
			grams = 21
			ounces = 22
			nanoseconds = 32
			microseconds = 33
			milliseconds = 34
			seconds = 35
			minutes = 36
			hours = 37
			days = 38
			weeks = 39
			months = 40
			years = 41
			tenthsOfOtherUnits = 42
		}
		enum lexmarkSupplyStatus {
			other = 1
			unknown = 2
			ok = 3
			low = 4
			empty = 5
			invalid = 6
		}
		enum lexmarkCartridgeType {
			unknown = 1
			other = 2
			invalid = 3
			shipWith = 4
			standard = 5
			highYieldStandard = 6
			extraHighYieldStandard = 7
			otherGenuine = 8
			standardGenuine = 9
			otherNonGenuine = 10
			standardNonGenuine = 11
			returnProgram = 21
			highYieldReturnProgram = 22
			extraHighYieldReturnProgram = 23
			standardReturnProgramGenuine = 24
			otherReturnProgramGenuine = 25
			standardNonReturnProgram = 26
			otherNonReturnProgram = 27
			refilledStandard = 37
			refilledHighYieldStandard = 38
			refilledExtraHighYieldStandard = 39
			refilledReturnProgram = 53
			refilledHighYieldReturnProgram = 54
			refilledExtraHighYieldReturnProgram = 55
		}
		enum lexmarkSupplyClass {
			filled = 1
			consumed = 2
		}
		enum generalSupplyUnit {
			other = 1
			unknown = 2
			tenThousandthsOfInches = 3
			micrometers = 4
			impressions = 7
			sheets = 8
			hours = 11
			thousandthsOfOunces =  2
			tenthsOfGrams = 13
			hundrethsOfFluidOunces = 14
			tenthsOfMilliliters = 15
			feet = 16
			meters = 17
			items = 18
			percent = 19
		}
		enum generalAlerts {
			other = 1
			critical = 3
			warning = 4
			warningBinaryChangeEvent = 5
		}
		enum hrPrinterStatus {
			other = 1
			unknonw = 2
			idle = 3
			printing = 4
			warmup = 5
		}
		enum hrErrorState {
			lowPaper = 0
			noPaper = 1
			lowToner = 2
			noToner = 3
			doorOpen = 4
			jammed = 5
			offline = 6
			serviceRequested = 7
			inputTrayMissing = 8
			outputTrayMissing = 9
			markerSupplyMissing = 10
			outputNearFull = 11
			outputFull = 12
			inputTrayEmpty = 13
			overduePreventMaint = 14
		}
		enum canonCounters {
			total1 = 101
			total2 = 102
			totalLarge = 103
			totalSmall = 104
			totalBlack1 = 108
			TotalBW = 109
			totalSingleColorLarge = 110
			totalSingleColorSmall = 111
			totalBlackLarge = 112
			totalBlackSmall = 113
			total1_2Sided = 114
			totalSingleColor1 = 118
			totalFullColorSingleColorLarge = 122
			totalFullColorSingleColorSmall = 123
			TotalColour = 124
			totalA2 = 127
			totalABlack2 = 133
			totalAFullColorSingleColor2 = 148
			copyTotal1 = 201
			copyTotal2 = 202
			copyLarge = 203
			copyBlack2 = 222
			copyFullColorSingleColorLarge = 229
			copyFullColorSingleColorSmall = 230
			copyFullColorSingleColor2 = 231
			copyFullColorSingleColor1 = 232
			printTotal1 = 301
			printFullColorSingleColorLarge = 321
			printFullColorSingleColorSmall = 322
			printFullColorSingleColor1 = 324
			copyPrintFullColorLarge = 401
			copyPrintFullColorSmall = 402
			scanTotal1 = 501
			receivePrintTotal1 = 701
			receivePrintTotal2 = 702
			receivePrintFullColorLarge = 711
			receivePrintFullColorSmall = 712
			receivePrintBlackLarge = 715
			receivePrintBlackSmall = 716
			receivePrintBlackLarge2Sided = 725
			receivePrintBlackSmall2Sided = 726
		}
		enum canonBasicCounters {
			bTotal1 = 101
			bTotal2 = 102
			bTotalBW1 = 108
			bTotalBW2 = 109
			bTotalColour = 124
		}

	}
	Process{
		Try{
			# Test printer to see if it is ONLINE, if not we will have to mark as OFFLINE in the database
			$printerOnline = Test-Connection $printerObject.IP -Count 1 -Quiet -ErrorAction Stop
		}
		Catch [System.Management.Automation.ActionPreferenceStopException]{
			($_.Exception.Message).split(':')[1] | Add-Content $logFile
		}
		Try{
			if ($printerOnline) {
				#Open SNMP connection
				Try{
					$snmp.Open($printerObject.IP,$snmpCommunityName,2,1000)
				}#[System.Management.Automation.MethodException]
				Catch {
					$printerObject | Add-Content $logFile
					$_.Exception.Message | Add-Content $logFile
				}	
				#Get Printer Details
				$printerName = Get-snmpProperty -oid $OIDArray.General.snmpGet.Name -logFile $logFile
				$printerLocation = Get-snmpProperty -oid $OIDArray.General.snmpGet.Location -logFile $logFile
				if ($null -eq $printerLocation) {
					$printerLocation = "Unknown"
					"`n" + $printerName + " has no location set. Please visit https://" + $printerObject.IP + " and set the device location." | Add-Content $logFile
				}
				$printerSupportNumber = Get-SupportNumber -checkString ([ref] $printerName)
				if ($null -eq $printerSupportNumber) {
					$printerSupportNumber = Get-SupportNumber -checkString ([ref] $printerLocation)
				}
				$printerReport | Add-Member -MemberType NoteProperty -Name "Name" -Value $printerName
				$printerReport | Add-Member -MemberType NoteProperty -Name "ShareName" -Value $printerObject.Name
				$printerReport | Add-Member -MemberType NoteProperty -Name "ServerName" -Value $printerObject.Server
				$printerReport | Add-Member -MemberType NoteProperty -Name "Location" -Value $printerLocation
				if ($null -ne $printerSupportNumber) {
					$printerReport | Add-Member -MemberType NoteProperty -Name "supportNumber" -Value $printerSupportNumber
				}else {
					$printerReport | Add-Member -MemberType NoteProperty -Name "supportNumber" -Value "ITHelps"
				}
				$printerReport | Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value $(
					Get-snmpProperty -oid $OIDArray.General.snmpGet.SystemDescr -logFile $logFile)
				$printerReport | Add-Member -MemberType NoteProperty -Name "SerialNumber" -Value $(
					Get-snmpProperty -oid $OIDArray.General.snmpGet.SerialNumber -logFile $logFile)
				$printerReport | Add-Member -MemberType NoteProperty -Name "IP" -Value $printerObject.IP
				$printerReport | Add-Member -MemberType NoteProperty -Name "Online" -Value $printerOnline
				$printerReport | Add-Member -MemberType NoteProperty -Name "SysUpTime" -Value $(
					Get-snmpProperty -oid $OIDArray.General.snmpGet.SysUpTime -logFile $logFile)
				$printerReport | Add-Member -MemberType NoteProperty -Name "Model" -Value $(
					Get-snmpProperty -oid $OIDArray.General.snmpGet.Model -logFile $logFile)
				
				#Get Functions / Counts based on Manufacturer
				# --- GetTree for all functions.
				if ($printerReport.Manufacturer -like '*Canon*') {
					#Features / Functions
					$FeatureCount = Get-snmpProperty -oid $OIDArray.Canon.snmpGetTree.Functions -logFile $logFile -getTree
					# Due to the return being a 2-d Array, we need to divid the array count by the Rank to get exactly
					#	how many items there are.
					$FeatureCount = $FeatureCount.Count / $FeatureCount.Rank
					$printerReport | Add-Member -MemberType NoteProperty -Name "FunctionCount" -Value $FeatureCount
					for ($i = 1; $i -le $FeatureCount; $i++) {
						$printerReport | Add-Member -MemberType NoteProperty -Name "Function$i" -Value $(
							Get-snmpProperty -oid($OIDArray.Canon.snmpGet.Functions + $i.ToString()) -logFile $logFile)
					}
					#Counts
					#Total prints
					$colourIndex = Get-snmpProperty -oid $OIDArray.Canon.snmpGetTree.colourFull -oidOnError -ErrorOID $OIDArray.Canon.snmpGetTree.colourFull2 -logFile $logFile -getTree
					$colourCount = $colourIndex.Count / $colourIndex.Rank
					for ($i = 0; $i -lt $colourCount; $i++) {
						$name = [canonCounters].GetEnumName( $([Int32] $colourIndex[1,$i].Trim()) )

						$printerReport | Add-Member -MemberType NoteProperty -Name $name -Value $(
							Get-snmpProperty -oid ($OIDArray.Canon.snmpGet.colourFullCounter + $colourIndex[1,$i].ToString().Trim()) `
							-oidOnError -ErrorOID ($OIDArray.Canon.snmpGet.colourFull2Counter + $colourIndex[1,$i].ToString().Trim()) -logFile $logFile
						)
					}

					$colourIndex = Get-snmpProperty -oid $OIDArray.Canon.snmpGetTree.colourBasic -oidOnError -ErrorOID $OIDArray.Canon.snmpGetTree.colourBasic2 -logFile $logFile -getTree
					$colourCount = $colourIndex.Count / $colourIndex.Rank
					for ($i = 0; $i -lt $colourCount; $i++){
						$name = [canonBasicCounters].GetEnumName( $([Int32] $colourIndex[1,$i].Trim()) )
						if ($null -eq $name) {
							"`nCanon Basic Colour counter name Error. Counter number: " +  $([Int32] $colourIndex[1,$i].Trim()) | Add-Content $logFile
							"`nChecking Full Counter name list: " +  [canonCounters].GetEnumName( $([Int32] $colourIndex[1,$i].Trim()) ) + "`n`n" | Add-Content $logFile
								$name = "bTotalColour"
						}
						
						$printerReport | Add-Member -MemberType NoteProperty -Name $name -Value $(
							Get-snmpProperty -oid ($OIDArray.Canon.snmpGet.colourBasicCounter + $colourIndex[1,$i].ToString().Trim()) `
							-oidOnError -ErrorOID ($OIDArray.Canon.snmpGet.colourBasic2Counter + $colourIndex[1,$i].ToString().Trim()) -logFile $logFile
						)
					}
					<#
					$printerReport | Add-Member -MemberType NoteProperty -Name "Total" -Value $(
						Get-snmpProperty -oid $OIDArray.Canon.snmpGet.aTotal2 -oidOnError -ErrorOID $OIDArray.Canon.snmpGet.bTotal2 -logFile $logFile)
					#Total Black and Whtie
					$printerReport | Add-Member -MemberType NoteProperty -Name "TotalBW" -Value $(
						Get-snmpProperty -oid OIDArray.Canon.snmpGet.aTotalBW -oidOnError -ErrorOID $OIDArray.Canon.snmpGet.bTotalBW -logFile $logFile)
					#Total colour
					$printerReport | Add-Member -MemberType NoteProperty -Name "TotalColour" -Value $(
						Get-snmpProperty -oid $OIDArray.Canon.snmpGet.aTotalColour -oidOnError -ErrorOID $OIDArray.Canon.snmpGet.bTotalColour -logFile $logFile)
					#>
				}elseif($printerReport.Manufacturer -like '*Lexmark*'){
					#Features / Functions
					$FeatureCount = Get-snmpProperty -oid $OIDArray.Lexmark.snmpGetTree.Functions -logFile $logFile -getTree
					#Divide the count by the rank to get the number of features
					$FeatureCount = $FeatureCount.Count / $FeatureCount.Rank
					$printerReport | Add-Member -MemberType NoteProperty -Name "FunctionCount" -Value $FeatureCount
					for ($i = 1; $i -le $FeatureCount; $i++) {
						$printerReport | Add-Member -MemberType NoteProperty -Name "Function$i" -Value $(
							Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.Functions + $i.ToString()) -logFile $logFile)
					}
					#Counts
					$ColourCount = Get-snmpProperty -oid $OIDArray.Lexmark.snmpGetTree.Colours -logFile $logFile -getTree
					#Divide the count by the rank to get the number of colours
					$ColourCount = $ColourCount.Count / $ColourCount.Rank
					$printerReport | Add-Member -MemberType NoteProperty -Name "ColourCount" -Value $ColourCount
					#Total Prints - Colour or BW Machine
					$printerReport | Add-Member -MemberType NoteProperty -Name "Total" -Value $(
						Get-snmpProperty -oid $OIDArray.Lexmark.snmpGet.Total -logFile $logFile)
					
					#Total BW and Colour on Colour machines
					if ($ColourCount -gt 1) {
						$printerReport | Add-Member -MemberType NoteProperty -Name "TotalBW" -Value $(
							Get-snmpProperty -oid $OIDArray.Lexmark.snmpGet.TotalBW -logFile $logFile)
						$printerReport | Add-Member -MemberType NoteProperty -Name "TotalColour" -Value $(
							Get-snmpProperty -oid $OIDArray.Lexmark.snmpGet.TotalColour -logFile $logFile)
					}
				<#}elseIf($printerReport.Manufacturer -like '*Brother*'){
					$printerReport | Add-Member -MemberType NoteProperty -Name "serialNumber" -Value $(
							Try{
								$snmp.Get( ([string] $OIDArray.Lexmark.snmpGet.Functions).Trim() + $i.ToString() )
							}Catch {$_.Exception.Message + "`n" + $_.ScriptStackTrace | Add-Content $logFile})#>
				}Else{
					$printerReport | Add-Member -MemberType NoteProperty -Name "Error" -Value "Not a Canon or Lexmark Printer"
				}
				# Get all alerts from prtAlertTable
				# Alarms
				# Alerts on Canon index at more that 1 digit. i.e. 430
				# This means that AlertIndex will contain the index number like 430
				try {
					# Get the alarm Index
					$AlarmIndex = Get-snmpProperty -oid $OIDArray.Alerts.snmpGetTree.prtAlertIndex -logFile $logFile -getTree
										
					if (($AlarmIndex[1,0] -ne 1611) -and ($AlarmIndex.Length -gt 0)) {
						# Set alarm Count even if 0
						$printerReport | Add-Member -MemberType NoteProperty -Name "AlertCount" -Value $($AlarmIndex.Count/2)
						# Seeming we are running and 2D array with $i we start at 0 and $i < Array.Count
						for ($i = 0; $i -lt $($AlarmIndex.Count/2); $i++) {
							# Use $i as index for the second dimension on the array
							$Alarms = [PSCustomObject][ordered]@{}
							$index = $AlarmIndex[1,$i]
							$Alarms | Add-Member -MemberType NoteProperty -Name $("Level") -Value $(
								[generalAlerts].GetEnumName([Int32] (Get-snmpProperty -oid ($OIDArray.Alerts.snmpGet.prtAlertSeverityLevel + $index) -logFile $logFile)))
							$Alarms | Add-Member -MemberType NoteProperty -Name $("Description") -Value $(
								Get-snmpProperty -oid ($OIDArray.Alerts.snmpGet.prtAlertDescription + $index) -logFile $logFile)
							$Alarms | Add-Member -MemberType NoteProperty -Name $("Time") -Value $(
								Get-snmpProperty -oid ($OIDArray.Alerts.snmpGet.prtAlertTime + $index) -logFile $logFile)

							#ALERTDATE  = get-date([long]($(Get-Date).Ticks - $((AlertTime$i)*100000))) -Format g (format g = SmallDateTime SQL)
							$printerReport | Add-Member -MemberType NoteProperty -Name $("Alert$i") -Value $Alarms
						}
					}else{
						# No alerts to add to report
						$printerReport | Add-Member -MemberType NoteProperty -Name "AlertCount" -Value 0
					}
				}
				catch {
					"Alarm section error: " + $printerObject.Name + " -- " + $_.Exception.Message + "`n" + $_.ScriptStackTrace | Add-Content $logFile
				}
				
				##--------- General Supplies
				try {
					$supplyIndex = Get-snmpProperty -oid $OIDArray.General.snmpGetTree.suppliesIndex -logFile $logFile -getTree
					$supplyIndex = $supplyIndex.count / $supplyIndex.Rank
					$colourantIndex = Get-snmpProperty -oid $OIDArray.General.snmpGetTree.markerColorantMarkerIndex -logFile $logFile -getTree
					$colourantIndex = $colourantIndex.count / $colourantIndex.Rank
					$LexmarksupplyIndex = Get-snmpProperty -oid $OIDArray.Lexmark.snmpGetTree.currentSupplyInventoryIndex -logFile $logFile -getTree
					$LexmarksupplyIndex = $LexmarksupplyIndex.count / $LexmarksupplyIndex.Rank

					if (($supplyIndex -ne $LexmarksupplyIndex) -and ($printerReport.Manufacturer -like '*Lexmark*')){
						"ERROR: Supply Count mismatch. General: " + $supplyIndex.ToString() + " Lexmark: " + $LexmarksupplyIndex.ToString() + "\n" | Add-Content $logFile
					}
					$printerReport | Add-Member -MemberType NoteProperty -Name "supplyCount" -Value $supplyIndex
					for ($i = 1; $i -le $supplyIndex; $i++) {
						$printerReport | Add-Member -MemberType NoteProperty -Name "supplyClass$i" -Value $(
							[generalSupplyClass].GetEnumName([Int32](Get-snmpProperty -oid ($OIDArray.General.snmpGet.markerSuppliesClass + $i.ToString()) -logFile $logFile)))
						$printerReport | Add-Member -MemberType NoteProperty -Name "supplyDescription$i" -Value $(
							Get-snmpProperty -oid ($OIDArray.General.snmpGet.markerSuppliesDescription + $i.ToString()) -logFile $logFile)
						$printerReport | Add-Member -MemberType NoteProperty -Name "supplyUnit$i" -Value $(
							[generalSupplyUnit].GetEnumName([Int32](Get-snmpProperty -oid ($OIDArray.General.snmpGet.markerSuppliesUnit + $i.ToString()) -logFile $logFile)))
						$printerReport | Add-Member -MemberType NoteProperty -Name "supplyMaxCapacity$i" -Value $(
							Get-snmpProperty -oid ($OIDArray.General.snmpGet.markerSuppliesMaxCapacity + $i.ToString()) -logFile $logFile)
						
						if($printerReport.Manufacturer -like '*Canon*') {
							
							$printerReport | Add-Member -MemberType NoteProperty -Name "supplyType$i" -Value $(
								[generalCanonSupplyType].GetEnumName([Int32] (Get-snmpProperty -oid ($OIDArray.General.snmpGet.markerSuppliesType + $i.ToString()) -logFile $logFile)))
							$printerReport | Add-Member -MemberType NoteProperty -Name "supplyLevel$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.General.snmpGet.markerSuppliesLevel + $i.ToString()) -logFile $logFile)
							if ($i -le $colourantIndex) {
                                # Canon Toner T12 doesn't specify the colourant
								#Pull Colourant Value, check Description for Colourant value, if not there append it to Description
								$printerReport | Add-Member -MemberType NoteProperty -Name "colourantValue$i" -Value $(
									Get-snmpProperty -oid ($OIDArray.General.snmpGet.markerColorantValue + $i.ToString()) -logFile $logFile)
							}
					# Fix Toner description to contain colourant
							if($printerReport."supplyDescription$i" -notcontains $printerReport."colourantValue$i" ) {
								$printerReport."supplyDescription$i" += " " + $printerReport."colourantValue$i"
							}

						}elseif ($printerReport.Manufacturer -like '*Lexmark*') {
							# Lexmark Private MIB has better detail for this
							<#$printerReport | Add-Member -MemberType NoteProperty -Name "supplyType$i" -Value $(
								[generalLexmarkSupplyType].GetEnumName([Int32](Get-snmpProperty -oid ($OIDArray.General.snmpGet.markerSuppliesType + $i.ToString()) -logfile $logfile)))#>
							$printerReport | Add-Member -MemberType NoteProperty -Name "supplyLevel$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.General.snmpGet.markerSuppliesLevel + $i.ToString()) -logFile $logFile)
							$printerReport | Add-Member -MemberType NoteProperty -Name "supplyType$i" -Value $(
								[lexmarkSupplyType].GetEnumName([Int32](Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyType + $i.ToString()) -logFile $logFile)) )
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyColorantValue$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyColorantValue + $i.ToString()) -logfile $logFile)
							# ----Same as General Supply Description.
							<#$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyDescription$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyDescription + $i.ToString()) -logFile $logFile)#>
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplySerialNumber$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplySerialNumber + $i.ToString()) -logFile $logFile)
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyPartNumber$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyPartNumber + $i.ToString()) -logFile $logFile)
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyClass$i" -Value $(
								[lexmarkSupplyClass].GetEnumName([Int32](Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyClass + $i.ToString()) -logFile $logFile)))
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyCartridgeType$i" -Value $(
								[lexmarkCartridgeType].GetEnumName([Int32](Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyCartridgeType + $i.ToString()) -logFile $logFile )))
							$snmpDateTime = Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyInstallDate + $i.ToString()) -logFile $logFile
							if ("" -ne $snmpDateTime){
								$supplyInstallDate = Get-snmpDateAndTime -snmpDateAndTime $snmpDateTime
							}else{
								$supplyInstallDate = 'NULL'
							}
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyInstallDate$i" -Value $supplyInstallDate
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyPageCountAtInstall$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyPageCountAtInstall + $i.ToString()) -logFile $logFile)
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyCurrentStatus$i" -Value $(
								[lexmarkSupplyStatus].GetEnumName([Int32](Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyCurrentStatus + $i.ToString()) -logFile $logFile)))
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyCapacityUnit$i" -Value $(
								[lexmarkSupplyUnit].GetEnumName([Int32](Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyCapacityUnit + $i.ToString()) -logFile $logFile)))
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyMaxCapacity$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyCapacity + $i.ToString()) -logFile $logFile)
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyFirstKnownLevel$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyFirstKnownLevel + $i.ToString()) -logFile $logFile)
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyUsage$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyUsage + $i.ToString()) -logFile $logFile)
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyCalibrations$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyCalibrations + $i.ToString()) -logFile $logFile)
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyCoverage$i" -Value $(
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyCoverage + $i.ToString()) -logFile $logFile)
							<# Doesn't look like this is implemented here.
								Get-snmpProperty -oid ($OIDArray.Lexmark.snmpGet.currentSupplyDaysRemaining + $i.ToString()) -logfile $logFile}#>
							$printerReport | Add-Member -MemberType NoteProperty -Name "lexmarkSupplyDaysRemaining$i" -Value 0
						}else{
							"Supply section error (Supply Type by manufacturer): " + $printerObject.Name + " -- " + $printerReport.Manufacturer + ": Not configured." | Add-Content $logFile
						}
					}
				}
				catch {
					"Supply section error: " + $printerObject.Name + " -- " + $_.Exception.Message + "`n" + $_.ScriptStackTrace | Add-Content $logFile
				}

				#Set-CWITPrinter -Printer $printerReport | Add-Content $logFile
				$snmp.Close()
				#Pause
			}else{
				#Printer(SN, SupportNumber, Location, Name, IPAddress, Model, UpTime, pOnline)
				#prtShares(prtSN,ShareName,HostingServer,Decommissioned)
				$printerReport | Add-Member -MemberType NoteProperty -Name "SerialNumber" -Value $("NA-" + $printerObject.Name)
				$printerReport | Add-Member -MemberType NoteProperty -Name "ShareName" -Value $printerObject.Name
				$printerReport | Add-Member -MemberType NoteProperty -Name "ServerName" -Value $printerObject.Server
				$printerReport | Add-Member -MemberType NoteProperty -Name "IP" -Value $printerObject.IP
				$printerReport | Add-Member -MemberType NoteProperty -Name "Online" -Value $printerObjectOnline
				$printerReport | Add-Member -MemberType NoteProperty -Name "Location" -Value "NA"
				$printerReport | Add-Member -MemberType NoteProperty -Name "Name" -Value $printerObject.Name
				$printerReport | Add-Member -MemberType NoteProperty -Name "Model" -Value "NA"
				$printerReport | Add-Member -MemberType NoteProperty -Name "SysUpTime" -Value "0"
				
				#Set-CWITPrinter -Printer @{"SerialNumber" = $("NA-" + $printerObject.Name);"ShareName" = $printerObject.Name; "ServerName" = $printerObject.Server; "IP" = $printerObject.IP;"Online" = $printerObjectOnline; "Location" = "NA"; "Name" = "NA"} -Offline
			}
		}Catch{
			$snmp.Close()
			"Main Section Error: " + $printerObject.Name +  " -- " + $_.Exception.Message + " -- " + $_.ErrorDetails + "`n" + $_.ScriptStackTrace | Add-Content $logFile 
		}
	}
	End{
		$printerReport
	}
}
# -- Function to validate IP address
function Confirm-IPAddress {
	<#
	.SYNOPSIS
		Validate IP Address
	.PARAMETER IpAddress
		Type: String. Ip address 1-255.1-255.1-255.1-255
	.OUTPUTS
		Ip address if valid, if not FALSE
	.EXAMPLE
		$ipAddress = Confirm-IpAddress -IpAddress "10.0.0.10"
		$ipAddress -> 10.0.0.10
		$ipAddress = Confirm-IpAddress -IpAddress "265.2.2.1"
		$ipAddress -> "26.2.2.1"
		$ipAddress = Confirm-IpAddress -IpAddress "foo"
		$ipAddress -> $false
	#>
	[CmdletBinding(DefaultParameterSetName='Default')]
	param (
		[Parameter(Mandatory=$true,
		ParameterSetName="Default",
		HelpMessage="Does the string contain a valid IP address")]
		[string]$IpAddress
	)
	process {
		#[ValidatePattern('(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}')]
		$checkedIP = Select-String -Pattern "(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}" -InputObject $IpAddress
	}
	end {
		if ($checkedIP.Matches.Success){
			return $checkedIP.Matches.Value
		}elseif($null -ne $checkedIP){
			return $IpAddress
		}else{
			return $false
		}
		
	}
}

#Load OIDs for snmp crawl
try {
	$OidCollection = Get-jsonFile -filePath ($PSScriptRoot + "\json\OID.json")
	if($null -eq $OidCollection){
		throw "OID json file not location wrong. $PSScriptRoot\json\OID.json"
	}
}
catch {
	$_.Exception.Message + "`n" + $_.ScriptStackTrace | Add-Content $scriptLogFile
}

# Load the Connection String
try {
	$dbConnection = Get-jsonFile -filePath ($PSScriptRoot + "\json\DBConnection.json")
	if($null -eq $dbConnection){
		throw "Database Connection json file not location wrong. $PSScriptRoot\json\DBConnection.json"
	}
}
catch {
	$_.Exception.Message + "`n" + $_.ScriptStackTrace | Add-Content $scriptLogFile
}
#Load hosting servers for print
try {
	$HostingServers = Get-jsonFile -filePath ($PSScriptRoot + "\json\prtServers.json")
	if($null -eq $HostingServers){
		throw "Host json file not location wrong. PSScriptRoot\json\prtServers.json"
	}
}
catch {
	$_.Exception.Message + "`n" + $_.ScriptStackTrace | Add-Content $scriptLogFile
}
# load SQL statements from json
try {
	$sqlCommands = Get-jsonFile -filePath ($PSScriptRoot + "\json\cwit_sql.json")
	if($null -eq $sqlCommands){
		throw "SQL statement json file not location wrong. PSScriptRoot\json\cwit_sql.json"
	}
}
catch {
	$_.Exception.Message + "`n" + $_.ScriptStackTrace | Add-Content $scriptLogFile
}

#PrinterList
#$printers = Get-CWPrinters -PS -PrintServerName "[SERVER FQDN]"
#We will also pull the snmp community name from this json file
$snmpCommunityName = ""
foreach($hostSrv in $HostingServers){
	if($hostSrv.Status -like "Active"){
		$Printers = Get-CWPrinters -PS -PrintServerName $hostSrv.HostingServer
		$snmpCommunityName = $hostSrv.snmpCommNameV2
		foreach($printer in $Printers){
			$printerIP = Confirm-IPAddress -IpAddress $printer.IP
            # Printer IP/Port name for Zebra Card printer
			If ($printer.IP -like "ZXP7001:"){
				$printer.IP = '###.###.###.###'
			}elseif (($null -eq $printerIP) -or ("" -eq $printerIP)) {
				$printer.IP = '0.0.0.0'
			}else{
				$printer.IP = $printerIP
			}
		}
	}
}

foreach ($printer in $Printers){
	"Starting: " + $printer.Name + " " + $printer.IP + " " + $printer.Server | Add-Content $scriptLogFile
	if ($printer.DriverName -like '*Brother*') {
		$snmpCommunityName = $OidCollection.Brother.snmpString.public
	}else{
		$snmpCommunityName = $OidCollection.Canon.snmpString.public
	}
	$printerReport = Get-PrinterSNMP -snmpCommunityName $snmpCommunityName -logFile $scriptLogFile -printerObject $printer -OID $OidCollection
	ConvertTo-Json -InputObject $printerReport -Depth 15 | Out-File -FilePath ($PSScriptRoot + "\printerReports\" + $printerReport.ShareName + ".json")

	if (0 -ne $printerReport.Length) {
		Set-CWITPrinter -Printer $printerReport -sqlCommands $sqlCommands -connectionString $dbConnection.connectionString | Add-Content $scriptLogFile
	}else{
		"`nError Printer report empty.`n ---`t" + $printer + "`t ---`n" | Add-Content $scriptLogFile
	}
}
"--Ending Processing--" | Add-Content $scriptLogFile