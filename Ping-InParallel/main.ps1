Import-Module .\PSM\Parallel-Ping.psm1


$Switch = "0"

while ($Switch -lt "2") {
    Ping-InParallel
    Start-Sleep -Seconds 60
}


Remove-Module Parallel-Ping