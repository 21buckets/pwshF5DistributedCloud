# This function returns the count of advertise policies by namespace. Useful to track resource usage in an environment hitting thresholds.


Param(
    [Parameter(Mandatory=$true)]
    [String]$XCTenant,
    [Parameter(Mandatory=$true)]
    [String]$XCAPIKey,
    [ValidateScript({
        if(-Not ($_.directoryName | Test-Path) ){
            throw "File or folder does not exist" 
        }        
        if($_ -notmatch "(\.csv|\.txt)" ){
            throw "The File Path $_ argument must be a csv or txt file."
        }
        return $true
    })]
    [Parameter(Mandatory=$true)]
    [System.IO.FileInfo]$OutputFilePath
)


if(-not (Get-module -Name "pwshF5DistributedCloud")){
    throw "Module does not exist, please import using the 'Import-Module' command"
}


# Note: If the authentication does not work properly, no error is thrown. This needs to be fixed in the Set-XCConnectionDetails function with a validation step.
Set-XCConnectionDetails -tenant $XCTenant -apiToken $XCAPIKey
$namespaces = Get-XCNamespaces

if ( -not ($namespaces)){
    throw "No namespaces found with current connection details. Unable to continue"
}

$table = @()
foreach($namespace in $namespaces.items){
    $namespace_name = $namespace.name

    $advertise_policys = Get-XCAdvertisePolicys -namespace $namespace_name

    $row = [PSCustomObject]@{
        "namespace" = $namespace_name
        "num_adv_policys" = $advertise_policys.items.Count
    }

    Write-host "Name: $($namespace.name) Advertise Policys: '$($advertise_policys.items.Count)'"
    $table += $row
}


if ($table.Count -gt 0 ){
    $table | Convertto-csv | Out-file -Path $OutputFilePath
} else {
    Write-host "No entries to output."
}
