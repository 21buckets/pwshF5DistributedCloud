
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


<#
    Helper Functions
#>

function Process-Object{
    Param(
        $object
    )
}

#//------- End Helper Functions


#Echo where the script is executing from to set working path
$working_path = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$output_path = $working_path + '\output'
If(!(test-path $output_path)) { New-Item -ItemType Directory -Force -Path $output_path > $null}

$time_stamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

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

    The following objects will be collected:
    * ('lbr_metadata','members_health','load_balanced_records','monitors','pools','virtual_servers','nameservers')

#>

$monitors = Get-XCDNSMonitors.items

















