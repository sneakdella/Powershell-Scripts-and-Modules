<#
Author: Jacob Yuhas
Date Written: May 23rd, 2022

Usage (Default): Ping-InParallel
Usage (Custom Parameters): Ping-InParallel -IPListLocation "C:\temp\testpath.txt" -LogOutput "C:\temp\log.csv"

Script will pull from a text file of IP addresses. Then it will use Test-NetConnection in parallel on all the devices.
Test-NetConnection results of each device are then passed back into $PingResults
From $PingResults, it is then initiated as $Device object and put into a new list called $ResultsProper
From there, the results are printed to the terminal and exported to a log CSV.

Note: "Out-Null" is used on some lines to supress the output of System.Collections.ArrayList returning the index of a newly added item to an Arraylist.
#>


function Ping-InParallel {

    param (
        # Define location of list of IPs that you wish to ping, default can be set
        # Define location of the log file. Default will be the root directory of where the Powershell Module is stored.
        
        [string]$IPListLocation = "C:\temp\posh\IP_addresses.txt",
        [string]$LogOutput = "$($PSScriptRoot)\log.csv"
    )

    # Generates the list of IP addresses. 
    $List = Get-Content $IPListLocation
    
    # Syncronized, parallel safe array
    $PingResults = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))

    # Test-NetConnection and then dump data to $PingResults
    $List | ForEach-Object -Parallel{
        $result = Test-NetConnection $_ -WarningAction Ignore
        $PingResults=$using:PingResults
        [void]$PingResults.Add($result) | Out-Null
    }

    # DeviceClass
    class Device {
        [string]$RemoteAddress
        [string]$PingSucceeded

        [string]ToString(){
            return ("{0},{1}" -f $this.RemoteAddress, $this.PingSucceeded)
        }

        [string]GetRemoteAddress() {
            return($this.RemoteAddress)
        }

        [string]GetPingSucceeded() {
            return($this.PingSucceeded)
        }
    }

    # Initiate ArrayList to collect new Devices in DeviceClass
    $ResultsProper = [System.Collections.ArrayList]@()

    # Create New Device Objects and add them to $ResultsProper Arraylist.

    $PingResults | ForEach-Object {
        #Write-Host "DEBUG: " $_.PingSucceeded $_.RemoteAddress         #####////DEBUG///
        $newDevice = [Device]::New()
        $newDevice.RemoteAddress = $_.RemoteAddress
        $newDevice.PingSucceeded = $_.PingSucceeded
        $ResultsProper.Add($newDevice) | Out-Null                       #### Out-Null prevents random indexes from being returned to the terminal
    }


    # Prints out contents of $ResultsProper
    $ResultsProper | ForEach-Object {
        Write-Host $_.RemoteAddress $_.PingSucceeded
        $_.ToString() | Out-File -FilePath $LogOutput -Append
    }

}

Ping-InParallel