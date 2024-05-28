# "DeviceName,DeviceType,VMID,ServiceName,VirtualMachineID",

$somelist = @(
    "DUDEPRD01,VirtualMachine,vm-12345,EventViewer,xxxx-xxxx-xxxx-xxxx",
    "DUDEPRD02,VirtualMachine,vm-12345,IvantiEPM,xxxx-xxxx-xxxx-xxxx",
    "APPLEPRD01,VirtualMachine,vm-22222,EventViewer,xxxx-xxxx-xxxx-xxxx",
    "APPLEPRD01,VirtualMachine,vm-22222,IvantiEPM,xxxx-xxxx-xxxx-xxxx",
    "ORANGEPRD01,VirtualMachine,vm-33333,EventViewer,xxxx-xxxx-xxxx-xxxx",
    "ORANGEPRD01,VirtualMachine,vm-33333,IvantiEPM,xxxx-xxxx-xxxx-xxxx",
    "GREENPRD01,VirtualMachine,vm-44444,EventViewer,xxxx-xxxx-xxxx-xxxx",
    "REDPRD01,VirtualMachine,vm-55555,IvantiEPM,xxxx-xxxx-xxxx-xxxx",
    "SNACKSPRD01,VirtualMachine,vm-66666,EventViewer,xxxx-xxxx-xxxx-xxxx",
    "LEPRD01,VirtualMachine,vm-77777,IvantiEPM,xxxx-xxxx-xxxx-xxxx"
)


[System.Collections.ArrayList]$AllServices = @()

ForEach ($line in $somelist) {
    $linesplit = $line.split(",")
    Write-Host $linesplit

    $myObject = [PSCustomObject]@{
        DeviceName     = $linesplit[0]
        DeviceType = $linesplit[1]
        VMOR    = $linesplit[2]
        ServiceName = $linesplit[3]
        VMID = $linesplit[4]
    }

    $AllServices.Add($myObject) | Out-Null
}

$AllServices | Format-Table

$newHash = @{}
ForEach ($Service in $AllServices) {
    If ($newHash.ContainsKey($Service.DeviceName)) {
        Write-Host "Contains Key"
        $key = "$($Service.DeviceName)"
        $value = $newHash[$key]
        Write-Host $value
        $value.Services.Add($Service.ServiceName) | Out-Null
    } else {
        $myObject = [PSCustomObject]@{
            DeviceType = $Service.DeviceType
            VMOR    = $Service.VMOR
            ## Make this an ArrayList that stores a key/pair val.
            Services = [System.Collections.ArrayList]$DeviceServices = @()
            VMID = $Service.VMID
        }
        $myObject.Services.Add($Service.ServiceName) | Out-Null
        $newHash.add($Service.DeviceName,$myObject)
    }
}


$newHash.GetEnumerator() | ForEach-Object {
    ForEach ($s in $_.value.Services) {
        Write-Host $_.Key $s
    }
}


Write-Host $newHash.count
