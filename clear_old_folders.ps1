Clear-Host
$rootPath = "e:\VCSA-BACKUP\vCenter" # Full path to where the backup folders are stored
$MaxFolderCount = 5 # Number of backup folders to keep for each vCenter instance found
$reportOnly = $true # Set to $false to remove old backup folders
$sendMail = $false # When set to $true provide from, to and smtp information
$mailFrom = "VCSA.Cleanup@My.org"
$mailTo = "users@My.org"
$smtpServer = "smtp.my.org"
$reportTitle = "VCSA Backup Folder Cleanup"
# ---------------------------------------------------------------------------------------
$Version = "2022.08.01.001"
$ScriptName = $MyInvocation.MyCommand.Name
$scriptPath = Split-Path $MyInvocation.MyCommand.Path
$CompName = (Get-Content env:computername).ToUpper()
$userName = ($env:UserName).ToUpper()
$userDomain = ($env:UserDomain).ToUpper()
$Date = Get-Date -Format g
$logsfolder = Join-Path -Path $scriptPath -ChildPath "Logs"
$traceFile = Join-Path -Path $logsfolder -ChildPath "$ScriptName.log"
$reportFile = Join-Path -Path $logsfolder -ChildPath "$ScriptName.html"
Start-Transcript -Force -LiteralPath $traceFile
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
Write-Host ("="*80) -ForegroundColor DarkGreen
Write-Host ""
Write-Host `t`t"$scriptName v$Version"
Write-Host `t`t"Started $Date"
Write-Host `t`t"Max Backups to Keep: $MaxFolderCount"
Write-Host `t`t"Checking Path: $rootPath"
Write-Host `t`t"Report Only: $reportOnly"
Write-Host ""
Write-Host ("="*80) -ForegroundColor DarkGreen
Write-Host ""
if(!(Test-Path $logsfolder)){New-Item -Path $logsfolder -ItemType Directory|Out-Null}
$CleanupReport = @()
$vCenterFolders = $rootPath|Get-ChildItem -Directory
$vCenterFolders | ForEach-Object { 
	$parentFolderName = $_.Name
	$backupFolders = Get-ChildItem $_.PSPath -Directory | Sort-Object CreationTime
	Write-Host "Found $($backupFolders.count) subfolder(s) for $parentFolderName"
	if ($backupFolders.Count -gt $MaxFolderCount) {
		Write-Host "Excess Backups Found, trimming..." -ForegroundColor Red -BackgroundColor Black
		$selectionCount = $backupFolders.Count - $MaxFolderCount
		Write-Host "Oldest $selectionCount folder(s) will be removed" -ForegroundColor Yellow
		$removeFolders = $backupFolders | Select-Object -First $selectionCount
		$removeFolders | ForEach-Object {
			$row = "" | Select-Object Name, CreationTime, Parent, FullName, Removed
			$row.Name = $_.Name
			$row.CreationTime = $_.CreationTime
			$row.Parent = $_.Parent
			$row.FullName = $_.FullName
			if ($reportOnly) {
				$row.Removed = $false
				$CleanupReport += $row
			}
			else{
				Write-Host "Removing folder: $($_.Name)"
				Remove-Item $_.FullName -Recurse -Force
				if(Test-Path $_.FullName){
					Write-Host "Removal Failed" -ForegroundColor Red -BackgroundColor Black
					$row.Removed = $false
				}
				else{
					Write-Host "Removal Succeeded" -ForegroundColor Green
					$row.Removed = $true
				}
				$CleanupReport += $row
			}
		}
	}
	else {
		Write-Host "Backup count within accepted range ( 0 - $MaxFileCount )" -ForegroundColor Green
	}
}
if($CleanupReport.Count -lt 1){
	$row = ""|Select-Object Summary
	$row.Summary = "No clean up actions performed"
	$CleanupReport += $row
}	
$headCSS='<style type="text/css">body{font-family:calibri;font-size:10pt;font-weight:normal;color:black;}th{text-align:center; text-shadow: 1px 1px black; background-color:#00417c; color:#FFFFFF; font-weight:bold; font-size:12px;}td{background-color:#F5F5F5; font-weight:normal; font-size:10px; padding: 3px 10px 3px 10px;}</style>'
[string]$reportHTML = $CleanupReport|ConvertTo-Html -Head $headCSS -body "<h4>$reportTitle</h4>" -PostContent "<hr><span style=""background-color:White; font-weight:normal; font-size:10px;color:Orange;align:right""><blockquote>v$Version - $CompName : $userName @ $userDomain - $Date</blockquote></span>"
$reportHTML = $reportHTML.Replace("False","<span style=""font-weight:bold;color:Red"">False</span>")
$reportHTML = $reportHTML.Replace("True","<span style=""font-weight:bold;color:Green"">True</span>")
$reportHTML|Out-File $reportFile
if($sendMail){
	Write-Host "Emailing Report..."
	Send-MailMessage -Subject $reportTitle -From $mailFrom -To $mailTo -Body $reportHTML -BodyAsHtml -SmtpServer $smtpServer
}

$stopwatch.Stop()
$Elapsed = [math]::Round(($stopwatch.elapsedmilliseconds)/1000,1)
Write-Host ("-"*80) -ForegroundColor DarkGreen
Write-Host ("="*80) -ForegroundColor DarkGreen
Write-Host ""
Write-Host "Script Completed in $Elapsed second(s)"
Write-Host ""
Write-Host ("="*80) -ForegroundColor DarkGreen
Stop-Transcript
