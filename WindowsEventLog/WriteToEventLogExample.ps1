<#
##########################################################
##########################################################
# VARIABLES
#
# NOTE: The name of your script is what becomes
#       the App and Log name in EventViewer.
#       If you do not want this, change $ScriptTrueName
#
##########################################################
##########################################################
#>

$ScriptFileName = Split-Path -Leaf $PSCommandPath
$ScriptTrueName = $ScriptFileName.Replace(".","_")

<#
##########################################################
##########################################################
# WINDOWS EVENT LOG SETUP
##########################################################
##########################################################
#>
if (!([System.Diagnostics.Eventlog]::Exists("$ScriptTrueName")) -and !([System.Diagnostics.EventLog]::SourceExists("$ScriptTrueName"))) {
    
    # Detect whether Windows Event Log has a location for this script to log to. If it doesnt, create it.
    
    try {
        New-EventLog -Source "$ScriptTrueName" -LogName $ScriptTrueName
    } catch {
        Write-Host "FAILED TO CREATE EVENTLOG. EXITING."
        exit
    }

    try {
        Write-EventLog -Source $ScriptTrueName -LogName $ScriptTrueName -EventID 3000 -EntryType Information -Message "Created new Source and Log name."
    } catch {
        Write-Host "FAILED TO WRITE TO EVENT LOG CREATED. EXITING."
        exit
    }

} else {
    Write-Host "True"
}



<#
##########################################################
##########################################################
# WINDOWS EVENT LOG WRITE FUNCTIONS
##########################################################
##########################################################
#>

function Write-LogInfo {
    param (
        $Message,
        $EventID = 3001
    )
    Write-EventLog -Source $ScriptTrueName -LogName $ScriptTrueName -EventID $EventID -EntryType Information -Message $Message
}

function Write-LogWarn {
    param (
        $Message,
        $EventID = 4001
    )
    Write-EventLog -Source $ScriptTrueName -LogName $ScriptTrueName -EventID $EventID -EntryType Warning -Message $Message
}

function Write-LogError {
    param (
        $Message,
        $EventID = 5001
    )
    Write-EventLog -Source $ScriptTrueName -LogName $ScriptTrueName -EventID $EventID -EntryType Error -Message $Message
}

<#
##########################################################
##########################################################
# BEGIN YOUR SCRIPT HERE
##########################################################
##########################################################
#>
