# Filepath of IP Addresses to perform Test-NetConnection On
$List = Get-Content C:\IP_addresses.txt

# Syncronized, parallel safe array
$PingResults = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))

# Test-NetConnection and then dump data to $PingResults
$List | ForEach-Object -Parallel{
    $result = Test-NetConnection $_ -WarningAction Ignore
    $PingResults=$using:PingResults
    $PingResults.Add($result)
}

# DeviceClass
class Device {
    [string]$RemoteAddress
    [string]$PingSucceeded
}

# Initiate ArrayList to collect new Devices in DeviceClass
$ResultsProper = [System.Collections.ArrayList]@()

# Create New Device Objects and add them to $ResultsProper Arraylist.
$PingResults | ForEach-Object {
    #Write-Host "DEBUG: " $_.PingSucceeded $_.RemoteAddress         #####////DEBUG///
    $newDevice = [Device]::New()
    $newDevice.RemoteAddress = $_.RemoteAddress
    $newDevice.PingSucceeded = $_.PingSucceeded
    $ResultsProper.Add($newDevice)
}

# Prints out contents of $ResultsProper
$ResultsProper