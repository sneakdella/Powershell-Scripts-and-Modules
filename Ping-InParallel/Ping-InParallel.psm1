<#
######################################################################################################################
META:
Author: Jacob Yuhas
Date Written: May 23rd, 2022
Date Updated: May 28th, 2022
######################################################################################################################
//
######################################################################################################################
USAGE
1.) Import PSM Module: Import-Module .\Parallel-Ping.psm1
2.) Usage (Default): Ping-InParallel
3.) Usage (Custom Parameters): Ping-InParallel -IPListLocation "C:\temp\testpath.txt" -LogOutput "C:\temp\log.csv"
######################################################################################################################
//
######################################################################################################################
WHAT DOES THE SCRIPT DO?

Tl;dr: Pulls a text file of ip adresses that are listed on each line. Then uses Test-NetConnection on each IP address 
in parallel Returns results into terminal and you can optionally output the results to a CSV file with -LogOutput

Long Answer: 
1.) Script will pull from a text file of IP addresses. Then it will use Test-NetConnection in parallel on all 
the devices.
2.) Test-NetConnection results of each device are then passed back into $PingResults
3.) From $PingResults, it is then initiated as $Device object and put into a new list called $ResultsProper
4.) From there, the results are printed to the terminal
5.) Optional step, if LogOutput is specified, it will then export to CSV along with printing results in terminal.
######################################################################################################################
//
######################################################################################################################
PARAMETERS
1.) Both params are optional
2.) "-IPListLocation" - Define filepath of text file with IP addresses line by line.
3.) "-LogOutput" - If it is given a value, it will output the results to a CSV file of a path you choose. If you do 
not specify anything, it will not export any log file anywhere and you will just get the terminal result
######################################################################################################################
//
######################################################################################################################
NOTES
1.) "Out-Null" is used on some lines to supress the output of System.Collections.ArrayList returning the index of a 
newly added item to an Arraylist.
2.) 
######################################################################################################################
#>


function Ping-InParallel {

    param (
        # Define location of list of IPs that you wish to ping, default can be set
        # Define location of the log file output. Default is NoLog.
        
        [string]$IPListLocation = "C:\temp\ip_addresses.txt",
        [string]$LogOutput = "NoLog"
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
        $newDevice = [Device]::New()
        $newDevice.RemoteAddress = $_.RemoteAddress
        $newDevice.PingSucceeded = $_.PingSucceeded
        $ResultsProper.Add($newDevice) | Out-Null            #### Out-Null prevents random indexes from being returned to the terminal
    }


    # Prints out contents of $ResultsProper
    $ResultsProper | ForEach-Object {
        Write-Host $_.RemoteAddress $_.PingSucceeded
        if ($LogOutput -ne "NoLog") {
            $_.ToString() | Out-File -FilePath $LogOutput -Append
        }
    }

}
