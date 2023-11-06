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

$CurrentNode = $env:COMPUTERNAME
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


# Variables
$WindowsClusterGroup = Get-ClusterGroup -Name "Scripts-Clustered"
$OwnerNodeName = $WindowsClusterGroup.OwnerNode.Name
$NodeNameThisScriptIsRunningOn = $env:COMPUTERNAME
$TasksPath = Get-ScheduledTask -TaskPath "\HAScripts\*"

# Old style logging.
#"$CurrentNode - Hello World" | Out-File -FilePath $OutputLogFile -Append

# New style logging.
#Write-LogInfo "$CurrentNode - Hello World"
#Write-LogWarn "$CurrentNode - Hello Warning"
#Write-LogError "$CurrentNode - Hello Error"

# Actual output, if needed.
#$OutputPath = "\\TRUENAS\SCHDTASK-Cluster-ScriptOutput\TestScript"
#$OutputLogFile = "$($LogPath)\$($ScriptTrueName).log"


Write-LogInfo "############### Starting FollowRoleOwner.ps1 $($NodeNameThisScriptIsRunningOn) ###############"

if ($NodeNameThisScriptIsRunningOn -eq $OwnerNodeName) {
    Write-LogInfo "Node this script is running on: $($NodeNameThisScriptIsRunningOn) matches with the resource owner node from Windows Failover Cluster $($OwnerNodeName) . This is the active node and scripts should be enabled here."
    Write-LogInfo "Cluster Resource Name: $($WindowsClusterGroup) OwnerNode: $($OwnerNodeName)"
    Write-LogInfo "Checking if tasks are enabled..."

    $TasksPath | ForEach-Object {
        $ScheduledTaskState = $_.State
        $ScheduledTaskName = $_.TaskName
        $ScheduledTaskObject = $_
        If ($ScheduledTaskState -eq "Disabled") {
            Write-LogInfo "$($ScheduledTaskName) is set to $($ScheduledTaskState). Enabling since this current node $($NodeNameThisScriptIsRunningOn) has been detected as the role owner."
            try {
                $ScheduledTaskObject | Enable-ScheduledTask
            } catch {
                Write-LogError "ERROR: $($ScheduledTaskName) failed to be set to enabled!"
            }
            
        } else {
            Write-LogInfo "$($ScheduledTaskName) is set to $($ScheduledTaskState). No need to change it's state since this current node $($NodeNameThisScriptIsRunningOn) is the role owner."
        }
    }

} else {
    Write-LogInfo "Node this script is running on: $($NodeNameThisScriptIsRunningOn) does NOT MATCH the resource owner from Windows Failover Cluster $($OwnerNodeName) . This node is considered inactive and scheduled tasks should be set to disabled."
    Write-LogInfo "Cluster Resource Name: $($WindowsClusterGroup) OwnerNode: $($OwnerNodeName)"
    Write-LogInfo "Checking if tasks are DISABLED..."

    $TasksPath | ForEach-Object {
        $ScheduledTaskState = $_.State
        $ScheduledTaskName = $_.TaskName
        $ScheduledTaskObject = $_
        If ($ScheduledTaskState -ne "Disabled") {
            Write-LogInfo "$($ScheduledTaskName) is set to $($ScheduledTaskState). Disabling this scheduled task since this current node $($NodeNameThisScriptIsRunningOn) has been not been detected as the role owner."
            try {
                $ScheduledTaskObject | Disable-ScheduledTask
            } catch {
                Write-LogError "ERROR: Could not set $($ScheduledTaskName) to disabled."
            }
            
        } else {
            Write-LogInfo "$($ScheduledTaskName) is set to $($ScheduledTaskState). No changes to scheduled tasks states needed."
        }
    }
}

Write-LogInfo "############### ENDING FollowRoleOwner.ps1 $($NodeNameThisScriptIsRunningOn) ###############"
