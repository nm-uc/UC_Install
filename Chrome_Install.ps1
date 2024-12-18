#description: Installs WinGet application from parameter set 
#execution mode: System
#tags: 
<# 
Notes:
This script performs the following:
1. Creates log file
2. Checks for WinGet and writes out version
3. Installs applcation via WinGet 
4. Allows for additional commands to be run after the install (cleanup, setting preferences etc)
#>
<#
param(
        [Parameter(Mandatory)]
        [string]$appid
    )
#>

$appid = "Google.Chrome"

#Checks Log path and creates if needed
$CheckTempPath = Test-Path "C:\temp"
$CheckLogPath = Test-Path "C:\temp\logs"
if ($CheckTempPath -eq $false) {"Log directory temp does not exist!" | Out-File "$env:TEMP\NZTimeZoneNoFolder.log"
    New-Item -Path "C:\Temp" -ItemType Directory
    }
if ($CheckLogPath -eq $false) {"Log directory does not exist!" | Out-File "$env:TEMP\NZTimeZoneNoFolder.log" -Append
        New-Item -Path "C:\Temp\logs" -ItemType Directory
    }

#Create log file
$LogFileName="winget_$appid.log"
$LogFilePath="$env:systemdrive\temp\logs\"
$Log="$LogFilePath$LogFileName"
$u = "%a %d/%m/%Y %H:%M:%S"
"$(Get-Date -uformat $u) - Starting winget install of app $appid" | Out-File $Log -Append
Function Get-WingetCmd {

    $WingetCmd = $null

    #Get WinGet Path
    try {
        #Get Admin Context Winget Location
        $WingetInfo = (Get-Item "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe\winget.exe").VersionInfo | Sort-Object -Property FileVersionRaw
        #If multiple versions, pick most recent one
        $WingetCmd = $WingetInfo[-1].FileName
    }
    catch {
    }

    return $WingetCmd

}

$WinGetLocation = Get-WingetCmd
#Sets PowerShell directory to allow WinGet to run as system
#Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" | Select-Object -Last 1 | Set-Location
#Run winget to list apps and accept source agrements (necessary on first run)
& $WinGetLocation list --accept-source-agreements | Out-Null
#writes the winget version its currently using
$WinGetVersion = & $WinGetLocation -v
"$(Get-Date -uformat $u) - Using WinGet version: $WinGetVersion" | Out-File $Log -Append

$RunningAsSystem = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
Write-Output "$(Get-Date -uformat $u) - Is the script running as system: $RunningAsSystem "| Out-File $Log -Append

#Checks if appid is not filled out
if ($appid -eq ""){
    Write-Error "Appid is empty!" | Out-File $Log -Append
    exit 1
}

<# Custom Variables
##################################>
#You can uncomment this line and hardcode a appid if required
#$appid = "Example.Example"




Write-Output "started install block"
Write-Output "App being installed is: $appid"
((& $WinGetLocation install --exact --id $appid -h --accept-source-agreements --scope machine) | Out-String).Split([Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries) >> $log #Run this to accept agreements, doesn't work as one command for 'upgrade'

<##################################
Start any additional custom commands below
##################################>

Remove-Item -Path "C:\Users\Public\Desktop\Google Chrome.lnk" -Force

<##################################
End of additional custom commands below
##################################>
Write-Output "Script end" | Out-File $Log -Append
