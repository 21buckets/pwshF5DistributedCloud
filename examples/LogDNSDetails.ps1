#Requires -Modules pwshF5DistributedCloud


Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if ( -Not ($_ | Test-Path -PathType leaf)){
            throw "credentialFilePath: $_ must be a file, not a folder and must exist"
        }
        return $true
    })]
    [System.IO.FileInfo]$credentialFilePath,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$tokenName,

    [Parameter(Mandatory=$false)]
    [string]$tenant
)





#Echo where the script is executing from to set working path
$working_path = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$output_path = $working_path + '\output'
If(!(test-path $output_path)) { New-Item -ItemType Directory -Force -Path $output_path > $null}



<# 
    Get credentials from file

    If the credential file does not exist, run the command 'Store-XCEncryptedAPITokenDetails' 
#>
$api_credentials = Get-XCEncryptedAPITokenDetails -apiTokenName $tokenName -credentialFilePath $credentialFilePath
$api_token_plaintext = $api_credentials.token | ConvertFrom-SecureString -AsPlainText

# Set credential global variable
Set-XCConnectionDetails -tenant $tenant -apiToken $api_token_plaintext 

#Validate API Token is working
# Will renew token by 30 days if there is less than 20 days remaining
$renew_results = Validate-XCAccessToken -credentialName $api_credentials.tokenName -renew -renewIfLessThanDays 20 -renewDays 30
if($renew_results -eq $false){
    throw "Issue renewing token $($api_credentials.tokenName)"
}


<#
    Collect info from API for each object required. The output will end up in $output_path and look something like this:

    --- Add log line here --
    {"tenant":"volterra-******","get_spec":{"http_health_check":{"send":"HEAD / HTTP/1.0\r\n\r\n","receive":"HTTP/1.","health_check_port":443},"dns_lb_pools":[{"tenant":"volterra-******","namespace":"system","name":"test-dns-pool"}]},"system_metadata":{"modification_timestamp":null,"creation_timestamp":"2023-02-13T22:53:31.338872789Z","creator_id":"*********"},"name":"mon-dns","event_collect_timestamp":"2023-02-23T11:59:38","description":"","uid":"**************"}
    The following objects will be collected:
    * ('lbr_metadata','members_health','load_balanced_records','monitors','pools','virtual_servers','nameservers')

    One might question why i havent added the below loops to a function to clean up the code. At the time of writing this I don't know which bits of config I want to collect from each object type, so 
    am keeping it separate for the time being.

#>

$time_stamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$health_checks = (Get-XCDNSHealthChecks -reportFields @("spec")).items

foreach($hc in $health_checks){
    [PSCustomObject]$splunk_data = [ordered]@{
        "event_collect_timestamp" = $time_stamp
        "tenant" = $hc.tenant
        "name" = $hc.name
        "uid" = $hc.uid
        "description" = $hc.description
        "system_metadata" = @{
            "creation_timestamp" = $hc.system_metadata.creation_timestamp
            "modification_timestamp" = $hc.system_metadata.modification_timestamp
            "creator_id" = $hc.system_metadata.creator_id
        }
        "get_spec"=$hc.get_spec
    } | ConvertTo-Json -Depth 10  -Compress | Out-File -Append -Encoding ascii -FilePath $working_path\monitor_configuration.txt
}


$load_balancers = (Get-XCDNSLoadBalancers -reportFields @("spec")).items

foreach($lb in $load_balancers){
    [PSCustomObject]$splunk_data = [ordered]@{
        "event_collect_timestamp" = $time_stamp
        "tenant" = $lb.tenant
        "name" = $lb.name
        "uid" = $lb.uid
        "description" = $lb.description
        "system_metadata" = @{
            "creation_timestamp" = $lb.system_metadata.creation_timestamp
            "modification_timestamp" = $lb.system_metadata.modification_timestamp
            "creator_id" = $lb.system_metadata.creator_id
        }
        "get_spec"=$lb.get_spec
    } | ConvertTo-Json -Depth 10  -Compress | Out-File -Append -Encoding ascii -FilePath $working_path\loadbalancer_configuration.txt
}
















