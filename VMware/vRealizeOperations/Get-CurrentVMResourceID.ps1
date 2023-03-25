######## HEADER FOR API CALLS ##############
$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$Headers.Add("Content-Type", "application/json")
$Headers.Add("Accept", "application/json")
$accesstoken = ''
######## END HEADER FOR API CALLS ##########

$RemoteCollector = "PUTYOURREMOTECOLLECTORHERE"
$Credential = Get-Credential -Message "Please provide your vROps Credentials"
$AuthSource = Read-Host "Enter the auth source of the account. [Enter LOCAL if it's just local]: "

If ($AuthSource -eq "") {
    $AuthSource = "LOCAL"
}

function Get-vROpsAccessToken {
    param (
        [Parameter(Mandatory=$true)]$RemoteCollector,
        [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory=$false)]$AuthSource="LOCAL",
        [Parameter(Mandatory=$false)]$Refresh=$false,
        [Parameter(Mandatory=$false)]$FunctionDebug=$false
    )

    $jsonBody = @{
        "username"=$Credential.UserName;
        "authSource"=$AuthSource;
        "password"=$Credential.GetNetworkCredential().Password;
    } | ConvertTo-JSON
    
    If ($Refresh -eq $false) {
        $global:accesstoken = Invoke-RestMethod "https://$RemoteCollector/suite-api/api/auth/token/acquire?_no_links=true" -Method 'POST' -Headers $Headers -Body $jsonBody -SkipCertificateCheck
    } elseif ($Refresh -eq $true) {
        $global:Headers.Remove("Authorization")
        $global:accesstoken = Invoke-RestMethod "https://$RemoteCollector/suite-api/api/auth/token/acquire?_no_links=true" -Method 'POST' -Headers $Headers -Body $jsonBody -SkipCertificateCheck
    }

    # Clear authentication from memory
    $jsonBody = ""
    
    # DEBUG: Show $accesstoken
    If ($FunctionDebug -eq $true){
        Write-Host "function Get-vROpsAccessToken | `$accesstoken DEBUG:" $accesstoken
    }
    
    $global:Headers.Add("Authorization", "vRealizeOpsToken " +$global:accesstoken.token)
}


function Get-VirtualMachines {
    param (
        [Parameter(Mandatory=$true)]$RemoteCollector,
        [Parameter(Mandatory=$true)]$Headers,
        [Parameter(Mandatory=$false)]$FunctionDebug=$false
    )

    $VirtualMachines = Invoke-RestMethod "https://$RemoteCollector/suite-api/api/resources?page=1&pageSize=-1&propertyName=summary%7CsmbiosUUID&resourceKind=VirtualMachine&_no_links=true" -Method 'GET' -Headers $Headers -SkipCertificateCheck

    return $VirtualMachines
}

function Search-ForSelf {
    param (
        [Parameter(Mandatory=$true)]$RemoteCollector,
        [Parameter(Mandatory=$true)]$VirtualMachines,
        [Parameter(Mandatory=$false)]$Headers,
        [Parameter(Mandatory=$false)]$FunctionDebug=$false   
    )

    # Grab current virtual machine's Serial number and remove "VMware-", "-" and whitespace
    [string]$SerialNumber = (Get-WmiObject win32_bios | Select-Object Serialnumber).Serialnumber
    $SerialNumber = $SerialNumber.TrimStart("VMware-")
    $SerialNumber = $SerialNumber.Replace(" ","")
    $SerialNumber = $SerialNumber.Replace("-","")

    # Debug
    If ($FunctionDebug -eq $true) {
        Write-Host $SerialNumber
    }

    # Gather resource IDs for the Virtual Machines, put them into an Array list
    $resourceIds = [System.Collections.ArrayList]::new()

    # Yup, add some funky escaped double quotes because JSON.
    ForEach ($VM in $VirtualMachines.resourceList){
        [void]$resourceIds.Add("`""+$VM.identifier+"`",")
    }

    # Take away final comma in $resourceIds so JSON doesn't get messed up.
    $resourceIds[-1] = $resourceIds[-1].Replace(",","")
    
    
    <#///////////////////////////
    # Example of a single resource being queried
    #$jsonBody = "{ `"resourceIds`": [ `"991cac91-72bd-414f-b6e4-104eb0e1c4a0`"], `"propertyKeys`": [`"summary|smbiosUUID`"], `"instanced`": false}"
    # Two resources
    #$jsonBody = "{ `"resourceIds`": [ `"991cac91-72bd-414f-b6e4-104eb0e1c4a0`", `"1e810802-473e-4bbc-ba65-b6b007e65204`"], `"propertyKeys`": [`"summary|smbiosUUID`"], `"instanced`": false}"
    /////////////////////////////#>
    
    # DO NOT CHANGE FOR GOD SAKES THIS IS SO DAMN TOUCHY
    $jsonBody = "{ `"resourceIds`": [ $resourceIds], `"propertyKeys`": [`"summary|smbiosUUID`"], `"instanced`": false}"

    If ($FunctionDebug -eq $true){
        $jsonBody
    }

    $response = Invoke-RestMethod "https://$RemoteCollector/suite-api/api/resources/properties/latest/query?_no_links=true" -Method 'POST' -Headers $Headers -Body $jsonBody -SkipCertificateCheck

    $resourceId = ""
    ForEach ($VM in $response.values) {
        
        # Annoying debug, just uncomment if you are going to use.
        #Write-Host $VM."property-contents"."property-content" $VM."property-contents"."property-content"."statKey" $VM."property-contents"."property-content"."values"

        $VM_serialFromvROps = ($VM."property-contents"."property-content"."values").replace("-","")
        
        If ($VM."property-contents"."property-content"."statKey" -eq "summary|smbiosUUID") {
            If ($VM_serialFromvROps -eq $SerialNumber) {
                If ($FunctionDebug -eq $true){
                    Write-Host "function Search-ForSelf DEBUG: Matched this current host using SMBIOS UUID"
                    Write-Host "function Search-ForSelf DEBUG: Current VM Serial Number: $SerialNumber"
                    Write-Host "function Search-ForSelf DEBUG:`$VM.resourceId:$($VM.resourceId)"
                }
                Write-Host "Matched with Virtual Machine object resource:"$VM.resourceId"that has SMBIOS UUID of:"$VM_serialFromvROps
                $resourceId = $VM.resourceId
                break
            }
        }
    }

    If ($FunctionDebug -eq $true){
        Write-Host "function Search-ForSelf DEBUG:`$resourceID:$resourceId"
    }
    
    return $resourceId
}

function Get-AutoServices {
    
    param (
        [Parameter(Mandatory=$false)]$FunctionDebug=$false   
    )

    $ErrorActionPreference = 'SilentlyContinue'

    $AllAutoServices = Get-Service | Select-Object -Property Name,DisplayName,Status,StartType | Where-Object {$_.Status -eq "Running" -and $_.StartType -eq "Automatic"}

    $AutomaticServicesNoDelay = [System.Collections.ArrayList]::new()

    # Remove delayed start
    ForEach ($service in $AllAutoServices) {
        If (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($service.Name)" | Where-Object {$_.Start -eq 2 -and $_.DelayedAutoStart -ne 1}) {
            [void]$AutomaticServicesNoDelay.Add($service.Name)
        }
    }

    # Debug
    If ($FunctionDebug -eq $true) {
        Write-Host "function Get-AutoServices DEBUG: Count of All automatic serivces (delayed too): "$AllAutoServices.Count
        Write-Host "function Get-AutoServices DEBUG: Count of Automatic Services only (no delayed): "$AutomaticServicesNoDelay.Count
    }
    

    $FinalAutomaticServices = Get-Service -Name $AutomaticServicesNoDelay | Select-Object -Property Name,DisplayName,Status
    return $FinalAutomaticServices
}

function Invoke-NewServices {
    param (
        [Parameter(Mandatory=$true)]$RemoteCollector,
        [Parameter(Mandatory=$true)]$AutomaticServices,
        [Parameter(Mandatory=$true)]$CurrentVM,
        [Parameter(Mandatory=$true)]$Headers,
        [Parameter(Mandatory=$false)]$FunctionDebug=$false
    )

    #$FirstAutoService = $AutomaticServices[0]
    #$jsonBody = "{ `"services`": [ { `"serviceName`": `"serviceavailability`", `"configurations`": [ {`"configName`": `"$($FirstAutoService.DisplayName)`",`"isActivated`": true,`"parameters`":[{`"key`":`"FILTER_VALUE`",`"value`":`"$($FirstAutoService.Name)`"}]}]}]}"
    
    
    ForEach ($service in $AutomaticServices){

        $jsonBody = "{ `"services`": [ { `"serviceName`": `"serviceavailability`", `"configurations`": [ {`"configName`": `"$($service.DisplayName)`",`"isActivated`": true,`"parameters`":[{`"key`":`"FILTER_VALUE`",`"value`":`"$($service.Name)`"}]}]}]}"

        If ($FunctionDebug -eq $true){
            Write-Host "function Invoke-NewServices DEBUG: `$jsonBody contents: "$jsonBody
        }

        try {
            Invoke-RestMethod "https://$RemoteCollector/suite-api/api/applications/agents/$CurrentVM/services?_no_links=true" -Method 'POST' -Headers $Headers -Body $jsonBody -SkipCertificateCheck    
        }
        catch {
            Write-Host "function Invoke-NewServices ERROR: Service: $($service.DisplayName) with exec name $($service.Name) either exists already or Invoke-RestMethod failed due to JSON formatting."
        }
        
    }
}

Get-vROpsAccessToken -RemoteCollector $RemoteCollector -Credential $Credential -AuthSource $AuthSource
$VirtualMachines = Get-VirtualMachines -RemoteCollector $RemoteCollector -Headers $Headers
$CurrentVM = Search-ForSelf -RemoteCollector $RemoteCollector -VirtualMachines $VirtualMachines -Headers $Headers
$AutomaticServices = Get-AutoServices
Invoke-NewServices -RemoteCollector $RemoteCollector -AutomaticServices $AutomaticServices -CurrentVM $CurrentVM -Headers $Headers
