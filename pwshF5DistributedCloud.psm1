<#
    .SYSNOPSIS
        pwshF5DistributedCloud.psm1

    .DESCRIPTION
        A REST-based module for interacting with the F5 Distributed Cloud API

    .NOTES
        Created by: Chris Triner, with code based off Cale Robertson's amazing pwshF5 module


#>


function Store-XCEncryptedAPIToken {

    # Saves APIToken information to a file as an encrypted string

    Param(
        [Parameter(Mandatory=$true)]
        $apiTokenName,

        [Parameter(Mandatory=$true,
            ParameterSetName="notprompt")]
        [ValidateNotNullOrEmpty()]
        [SecureString]$apiToken,

        [Parameter(Mandatory=$true,
            ParameterSetName="prompt")]
        [switch]$promptForToken,

        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if ( ($_ | Test-Path -PathType leaf)){
                throw "outputFilePath: $_ must be a folder, not a file and must exist"
            }
            return $true
        })]
        [System.IO.FileInfo]$outputFolderPath,

        [Parameter(Mandatory=$true)]
        [string]$outputFileName
    )

    #Get the token from direct input, or prompting the user
    if ($promptForToken){
        $api_token = Read-Host "Enter API Token" -AsSecureString
    }else{
        $api_token = $apiToken
    }

    # Converts to an encrypted string so it can be saved to a file
    $api_token = ConvertFrom-SecureString $api_token


    #If the file already exists for storing the credential, throw an error.
    if(test-path $outputFolderPath/$outputFileName){
        throw 'Credential output location "${outputFolderPath}/${outputFileName} already exists. Please delete it before trying again."'
    }

    $outputContent = @{
        "tokenName" = $apiTokenName
        "token" = $api_token
    } 
    
   
    $outputContent | Convertto-Json | Out-File $outputFolderPath/$outputFileName


}


function Get-XCEncryptedAPITokenDetails {

    # retrieves encrypted API token and converts it to a SecureString to use in subsequent API calls
    # Output format is a PSCustomObject:
    # {
    #    "tokenName" = "String"
    #    "token" = "System.Secure.String"
    # }
    
       

    Param(
        [Parameter(Mandatory=$true)]
        $apiTokenName,


        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if ( -Not ($_ | Test-Path -PathType leaf)){
                throw "credentialFilePath: $_ must be a file, not a folder and must exist"
            }
            return $true
        })]
        [System.IO.FileInfo]$credentialFilePath
    )

    $stored_creds = Get-Content $credentialFilePath | ConvertFrom-Json
    
    if($apiTokenName -ne $stored_creds.tokenName){
        throw "No credential matching name ${apiTokenName} exists in ${credentialFilePath}" 
    }

    $token_secure_string = $stored_creds.token | ConvertTo-SecureString

    return [PSCustomObject]@{
        "tokenName" = $stored_creds.tokenName
        "token" = $token_secure_string
    }



}



function Set-XCConnectionDetails {
    param(
        [Parameter(Mandatory = $false)]
        $tenant,

        [Parameter(Mandatory = $true)]
        $apiToken
    )


     $global:XCConnection = @{
        url               = set-XCUrl $tenant
        api_token         = $apiToken
    }

}

function set-XCUrl {
    param(
        [Parameter(Mandatory = $false)]
        $tenant
    )

    $default_url = "console.ves.volterra.io"
    if($tenant){
        $url = "https://${tenant}.${default_url}"
    }else{
        $url = "https://${default_url}"
    }

    return $url
}

function Get-XCVirtualSites{

    param(
        [Parameter(Mandatory=$true)]
        [string]$namespace,

        [Parameter(Mandatory=$false)]
        [string]$label_filter,

        [Parameter(Mandatory=$false)]
        [string]$report_fields,

        [Parameter(Mandatory=$false)]
        [string]$report_staus_fields

    )
    $uri_path = "/api/config/namespaces/${namespace}/virtual_sites"
    $xc_connection = $global:XCConnection

    $query_params = @{ }

    if($report_fields.Length -gt 0){
        $query_params["report_fields"]=$report_fields
    }

    if($report_status_fields.Length -gt 0){
        $query_params["report_status_fields"]=$report_status_fields
    }

    if($label_filter){
        $query_params["label_filter"]=$label_filter
    }

    $query_params_uri = ""
    foreach($key in $query_params.keys){
        if($query_params_uri -eq ""){
            $query_params_uri = "?"
        }else{
            $query_params_uri += "&"
        }

        $query_params_uri += $key+"="+($($query_params[$key]) -join ",")
    }

      
    $req = @{
        Uri         = $xc_connection.url + $uri_path + $query_params_uri
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return (Invoke-RestMethod @req) | ConvertPSObjectToHashtable
}

function new-XCVirtualSite{
    param(
        [Parameter(Mandatory=$true)]
        [string]$name,

        [Parameter(Mandatory=$true)]
        [string]$namespace,

        [Parameter(Mandatory=$false)]
        [string]$description,

        [Parameter(Mandatory=$false)]
        [Hashtable]$annotations,

        [Parameter(Mandatory=$false)]
        [switch]$disabled,

        [Parameter(Mandatory=$false)]
        [Hashtable]$labels = @{},

        [Parameter(Mandatory=$false)]
        [Hashtable]$site_selector = @{},

        [Parameter(Mandatory=$false)]
        [ValidateSet("INVALID","REGIONAL_EDGE","CUSTOMER_EDGE")]
        [string]$site_type
    )
  
    $uri_path = "/api/config/namespaces/${namespace}/virtual_sites"
    $xc_connection = $global:XCConnection





    #Initial Object creation
    $body = @{
        "metadata" = @{
            "name" = $name.ToLower()
            "labels" = $labels
            "namespace" = $name
        }
        "spec" = @{}
    }

    if($description){$body.metadata.description = $description}
    if($annotations){$body.metadata.annotations = $annotations}
    #disabled property doesnt seem to do anything
    if($disabled.IsPresent -eq $true){$body.metadata.disable = $true}


    

    $body_json = ConvertTo-json $body -depth 100
    Write-host $body_json


    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'POST'
        Body     = $body_json     
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
            "Accept" = "*/*"
            
            
        }
    }

    #Write-host $req.uri

    return Invoke-RestMethod @req

}



function Get-XCNamespaces {
    
    $uri_path = "/api/web/namespaces"
    $xc_connection = $global:XCConnection

      
    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return (Invoke-RestMethod @req) | ConvertPSObjectToHashtable
}

function Get-XCNamespace {

    param(
        [Parameter(Mandatory=$true)]
        [string]$name
    )

    #Namespaces must be all lowercase
    $name = $name.toLower()
    
    $uri_path = "/api/web/namespaces/$name"
    $xc_connection = $global:XCConnection

      
    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    $response = Invoke-RestMethod @req

    if ( -not $? ){
        $msg = $Error[0].ErrorDetails.Message
        #Write-Host $msg
    }

    return $response
}

function New-XCNamespace {

    <#
        Creates a namespace in an XC tenancy, provided the namespace does not already exist.

        Does not support assigning users and explicit roles

    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$name,

        [Parameter(Mandatory=$false)]
        [string]$description,

        [Parameter(Mandatory=$false)]
        [PSCustomObject]$annotations,

        [Parameter(Mandatory=$false)]
        [switch]$disabled,

        [Parameter(Mandatory=$false)]
        [PSCustomObject]$labels = @{}

    
    )
  
    $uri_path = "/api/web/namespaces"
    $xc_connection = $global:XCConnection





    #Initial Object creation
    [PSCustomObject]$body = @{
        "metadata" = @{
            "name" = $name.ToLower()
            "labels" = $labels
            #"namespace" = $name
        }
        "spec" = @{}
    }

    if($description){$body.metadata.description = $description}
    if($annotations){$body.metadata.annotations = $annotations}
    #disabled property doesnt seem to do anything
    if($disabled.IsPresent -eq $true){$body.metadata.disable = $true}


    

    $body_json = ConvertTo-json $body -depth 100
    Write-host $body_json


    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'POST'
        Body     = $body_json     
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
            "Accept" = "*/*"
            
            
        }
    }

    #Write-host $req.uri

    return Invoke-RestMethod @req
}

function Set-XCNamespace {

    <#
        Creates a namespace in an XC tenancy, provided the namespace does not already exist.

        Does not support assigning users and explicit roles

    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$name,

        [Parameter(Mandatory=$false)]
        [string]$description,

        [Parameter(Mandatory=$false)]
        [PSCustomObject]$annotations,

        [Parameter(Mandatory=$false)]
        [switch]$disabled,

        [Parameter(Mandatory=$false)]
        [PSCustomObject]$labels = @{}

    
    )

    $name = $name.ToLower()
  
    $uri_path = "/api/web/namespaces/${name}"
    $xc_connection = $global:XCConnection





    #Initial Object creation
    [PSCustomObject]$body = @{
        "metadata" = @{
            "name" = $name.ToLower()
            "labels" = $labels
            #"namespace" = $name
        }
        "spec" = @{}
    }

    if($description){$body.metadata.description = $description}
    if($annotations){$body.metadata.annotations = $annotations}
    #disabled property doesnt seem to do anything
    if($disabled.IsPresent -eq $true){$body.metadata.disable = $true}


    

    $body_json = ConvertTo-json $body -depth 100
    Write-host $body_json


    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'PUT'
        Body     = $body_json     
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
            "Accept" = "*/*"
            
            
        }
    }

    #Write-host $req.uri

    return Invoke-RestMethod @req
}

function Get-XCCredentials {
    
    $uri_path = "/api/web/namespaces/system/api_credentials"
    $xc_connection = $global:XCConnection

      
    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req
}

function Get-XCCredential {
    Param(
        [Parameter(Mandatory=$true)]
        $name
    )
    
    $uri_path = "/api/web/namespaces/system/api_credentials/${name}"
    $xc_connection = $global:XCConnection

      
    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req
}

function Get-XCUsers {
   
    $uri_path = "/api/web/custom/namespaces/system/user_roles"
    $xc_connection = $global:XCConnection

      
    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    $response = Invoke-RestMethod @req

    if ( -not $? ){
        $msg = $Error[0].ErrorDetails.Message
        #Write-Host $msg
    }

    return $response | ConvertPSObjectToHashtable
}
function New-XCUser {

    <#
        Creates a user in F5 XC

    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$email,

        [Parameter(Mandatory=$true)]
        [string]$firstName,
        [Parameter(Mandatory=$true)]
        [string]$lastName,

        [Parameter(Mandatory=$false)]
        [string[]]$groupNames,

        [Parameter(Mandatory=$false)]
        [ValidateSet("SSO","VOLTERRA_MANAGED","UNDEFINED")]
        [string]$idmType="SSO",

        [Parameter(Mandatory=$false)]
        [string]$namespaceRolesJson='',

        [Parameter(Mandatory=$false)]
        [ValidateSet("USER","SERVICE","DEBUG")]
        [string]$type="USER"

        

    
    )
  
    $uri_path = "/api/web/custom/namespaces/system/user_roles"
    $xc_connection = $global:XCConnection



    $namespace_roles = $namespaceRolesJson | convertfrom-json

    #Initial Object creation

    $body = @{
        "namespace" = "system"
        "email" = $email
        "first_name" = $firstName
        "last_name" = $lastName
        "idm_type" = $idmType
        "type" = $type
        "namespace_roles" = $namespace_roles


    }

    if($groupNames){$body.group_names = $groupNames}
    if($namespaceRoles){$body.namespace_roles = $namespaceRoles}
    

    $body_json = ConvertTo-json $body -depth 100
    Write-host $body_json

    
    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'POST'
        Body     = $body_json     
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
            "Accept" = "*/*"
            
            
        }
    }

    #Write-host $req.uri

    return Invoke-RestMethod @req
}

function Set-XCUser {

    <#
        Creates a user in F5 XC

    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$email,

        [Parameter(Mandatory=$true)]
        [string]$first_name,
        [Parameter(Mandatory=$true)]
        [string]$last_name,

        [Parameter(Mandatory=$false)]
        [string[]]$group_names,

        [Parameter(Mandatory=$false)]
        [ValidateSet("SSO","VOLTERRA_MANAGED","UNDEFINED")]
        [string]$idm_type="SSO",

        [Parameter(Mandatory=$false)]
        [hashtable[]]$namespace_roles,

        [Parameter(Mandatory=$false)]
        [ValidateSet("USER","SERVICE","DEBUG")]
        [string]$type="USER"

        

    
    )
  
    $uri_path = "/api/web/custom/namespaces/system/user_roles"
    $xc_connection = $global:XCConnection



    #$namespace_roles = $namespaceRolesJson | convertfrom-json

    #Initial Object creation

    $body = @{
        "namespace" = "system"
        "email" = $email
        "first_name" = $first_name
        "last_name" = $last_name
        "idm_type" = $idm_type
        "type" = $type
        "namespace_roles" = $namespace_roles
        "group_names" = $group_names


    }

    if($groupNames){$body.group_names = $groupNames}
    if($namespaceRoles){$body.namespace_roles = $namespaceRoles}
    

    $body_json = ConvertTo-json $body -depth 100
    Write-host $body_json

    
    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'PUT'
        Body     = $body_json     
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
            "Accept" = "*/*"
            
            
        }
    }

    #Write-host $req.uri

    return Invoke-RestMethod @req
}


function Renew-XCCredential {
    Param (
        [Parameter(Mandatory=$true)]
        $name,

        [Parameter(Mandatory=$true)]
        [Int]$renewDays
    )

    $uri_path = "/api/web/namespaces/system/renew/api_credentials"
    $xc_connection = $global:XCConnection

        $body = @{
            "expiration_days"=$renewDays
            "name"=$name
            "namespace"="system"

        }
      
    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'POST'      
        ContentType = 'application/json'
        Body = $body | convertto-json
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req

}

Function Validate-XCAccessToken {
    #TODO: Add better error handling for renewing etc... right now it kinda fails forward..
    param(
        [Parameter(Mandatory=$true)]
        $credentialName,

        [Parameter(ParameterSetName="renew")]
        [switch]$renew,

        [Parameter(ParameterSetName="renew")]
        [int]$renewDays=30,

        [Parameter(ParameterSetName="renew")]
        [int]$renewIfLessThanDays
    )

    if(!(Test-path variable:\global:XCConnection)){
         throw "Must provide global pre-set variables using Set-XCConnectionDetails"
    }
    


    # Validate API credentials by listing them   
    try{
        $xc_credential = Get-XCCredential -name $credentialName
    }catch{
        $message = $_
        if($message -contains "api credential entries: object not found"){
            Write-Error $message
        }
        
        throw "Credential with name $credentialName not found. Make sure to check the GUI for credential name information, as XC will suffix the name with a randomised string"
    }

    $credential_expiry = $xc_credential.object.spec.gc_spec.expiration_timestamp
    $expiry_date = get-date -Date $credential_expiry
    $date_now = Get-Date

    $span = new-timespan -start $date_now -end $credential_expiry
    Write-Host "There are $($span.days) days, $($span.hours) hours, $($span.minutes), and $($span.seconds) seconds until this API tokene expires"

    if($renew){
        #Only renew by set number of days if the token is close to expiry
        if($renewIfLessThanDays){
            if($($span.days) -lt $renewIfLessThanDays){
                $renew_result = Renew-XCCredential -name $credentialName -renewDays $renewDays
            }
        }else{
            #Renew the token by set number of days
            $renew_result = Renew-XCCredential -name $credentialName -renewDays $renewDays
        }

        #Get Credential again to make sure it is valid.
        $xc_credential = Get-XCCredential -name $credentialName
        $credential_expiry = $xc_credential.object.spec.gc_spec.expiration_timestamp
        $expiry_date = get-date -Date $credential_expiry
    }

    #Return true if new expiry date is in the future
    if($expiry_date.ticks -lt $date_now.ticks){
        return $false
    }else{
        return $true
    }
    


}



function Get-XCHttpLoadbalancers {
    param(
        [Parameter(Mandatory = $true)]
        $namespace

    )

    $uri_path = "/api/config/namespaces/${namespace}/http_loadbalancers"
    $xc_connection = $global:XCConnection

    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req
}

function Get-XCHttpLoadbalancer {
    param(
        [Parameter(Mandatory = $true)]
        $namespace,
        [Parameter(Mandatory = $true)]
        $name

    )

    $uri_path = "/api/config/namespaces/${namespace}/http_loadbalancers/${name}"
    $xc_connection = $global:XCConnection

    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req
}


function Get-XCRoutes {
    param(
        [Parameter(Mandatory = $true)]
        $namespace
      

    )

    $uri_path = "/api/config/namespaces/${namespace}/routes"
    $xc_connection = $global:XCConnection

    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req
}


function Get-XCDNSDomains {
    
    $uri_path = "/api/config/namespaces/system/dns_domains"
    $xc_connection = $global:XCConnection

    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req
}

function Get-XCDNSDomain {

    param(
        [Parameter(Mandatory=$true)]
        $name,

        [Parameter(Mandatory=$false)]
        $namespace = 'system'


    )
    
    $uri_path = "/api/config/namespaces/${namespace}/dns_domains/${name}"
    $xc_connection = $global:XCConnection

    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req
}



function New-XCDNSDomain {

    param(
        [Parameter(Mandatory=$true)]
        [string]$name,

        [Parameter(Mandatory=$false)]
        [string]$description,

        [Parameter(Mandatory=$false)]
        [PSCustomObject]$labels,

        [Parameter(Mandatory=$false)]
        [Switch]$dnssecEnable,

        [Parameter(Mandatory=$false)]
        $namespace = 'system'


    )
    
    $uri_path = "/api/config/namespaces/${namespace}/dns_domains"
    $xc_connection = $global:XCConnection

    if ($dnssecEnable -eq $true){
      dnssec_mode = "DNSSEC_ENABLE"
    }else{
        $dnssec_mode = "DNSSEC_DISABLE"
    }


   #$dnssec_mode = $dnssecEnable ? "DNSSEC_ENABLE" : "DNSSEC_DISABLE"
    

    [PSCustomObject]$body = @{
        "metadata" = @{
            "name" = $name
            "description" = $description
            "labels" = $labels
            "namespace" = $namespace
        }
        "spec" = @{
            "dnssec_mode" = $dnssec_mode
            "volterra_managed" = @{}
        }

    }

    $body_json = ConvertTo-Json $body -depth 100


    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'POST'
        Body     = $body_json      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }

    return Invoke-RestMethod @req -debug
}


function Start-XCDNSDomainVerify {

    param(
        [Parameter(Mandatory=$true)]
        $name,

        [Parameter(Mandatory=$false)]
        $namespace = 'system'


    )
    
    $uri_path = "/api/config/namespaces/${namespace}/dns_domain/${name}/verify"
    $xc_connection = $global:XCConnection

    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'POST'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req
}



function Get-XCDNSZones {
    param(
        [Parameter(Mandatory=$false)]
        $namespace = 'system'
    )


    $uri_path = "/api/config/dns/namespaces/${namespace}/dns_zones"
    $xc_connection = $global:XCConnection

    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req

}

function Get-XCDNSZone {
    param(
        [Parameter(Mandatory=$true)]
        $name,
        [Parameter(Mandatory=$false)]
        $namespace = 'system'
    )


    $uri_path = "/api/config/dns/namespaces/${namespace}/dns_zones/${name}"
    $xc_connection = $global:XCConnection

    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req

}


function Remove-XCDNSZone {
    param(
        [Parameter(Mandatory=$true)]
        $name,
        [Parameter(Mandatory=$false)]
        $namespace = 'system'
    )


    $uri_path = "/api/config/dns/namespaces/${namespace}/dns_zones/${name}"
    $xc_connection = $global:XCConnection

    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'DELETE'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }


    return Invoke-RestMethod @req

}


function New-XCDNSZone {

    <#
        Currently only supports Primary DNS Zones

    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$name,

        [Parameter(Mandatory=$false)]
        [string]$description,

        [Parameter(Mandatory=$false)]
        [PSCustomObject]$annotations,

        [Parameter(Mandatory=$false)]
        [switch]$disabled,

        [Parameter(Mandatory=$false)]
        [PSCustomObject]$labels = @{},

        [Parameter(Mandatory=$false)]
        [ValidateSet("primary","secondary")]
        [string]$zoneType = "primary",

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [string]$admin,

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [switch]$dnssecEnabled,

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [switch]$useCustomSOAParameters,

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [PSCustomObject]$customSOAParameters,

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [Array]$defaultRRSetGroup,

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [Array]$RRSetGroup,

        [Parameter(Mandatory=$false)]
        $namespace = 'system'
    )

  

    
    $uri_path = "/api/config/dns/namespaces/${namespace}/dns_zones"
    $xc_connection = $global:XCConnection

    

    #Initial Object creation
    [PSCustomObject]$body = @{
        "metadata" = @{
            "name" = $name
            "labels" = $labels
            "namespace" = $namespace
        }
        "spec" = @{}
    }

    if($description){$body.metadata.description = $description}
    if($annotations){$body.metadata.annotations = $annotations}
    #disabled property doesnt seem to do anything
    if($disabled.IsPresent -eq $true){$body.metadata.disable = $true}
    if($domain){$body.spec.domain = $domain}

    
    if($zoneType -eq "primary"){
        Write-host "Primary parameter set"

        #Create initial primary spec object
        $primary_spec = @{}

        #admin property does not appear to set anything....
        if($admin){$primary_spec.admin = $admin}

        #if not using custom SOA parameters, use default, otherwise add in custom
        if($useCustomSOAParameters -eq $false){
            $primary_spec["default_soa_parameters"] = $null
        }else{
            $primary_spec["soa_parameters"] = $customSOAParameters
        }

        #Add in default rr set
        if($defaultRRSetGroup.count -gt 0){
            $primary_spec["default_rr_set_group"] = $defaultRRSetGroup
        }

        #Add in additional record sets
        if($RRSetGroup.count -gt 0){
            $primary_spec["rr_set_group"] = $RRSetGroup
        }

        #Add DNS Security Mode
        if($dnssecEnabled.IsPresent){
            $dnssec_mode = @{"enable"= @{}}
           
        }else{
            $dnssec_mode = @{"disable"= @{}}
        }
        $primary_spec.dnssec_mode = $dnssec_mode

        $body.spec["primary"] = $primary_spec

    }elseif($zoneType -eq "secondary"){
        Write-host "secondary parameter set"
    }

    $body_json = ConvertTo-json $body -depth 100
    Write-host $body_json


    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'POST'
        Body     = $body_json     
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
            "Accept" = "*/*"
            
            
        }
    }

    Write-host $req.uri

    return Invoke-RestMethod @req
}


function Set-XCDNSZone {
    <#
        Currently only supports Primary DNS Zones

    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$name,

        [Parameter(Mandatory=$false)]
        [string]$description,

        [Parameter(Mandatory=$false)]
        [PSCustomObject]$annotations,

        [Parameter(Mandatory=$false)]
        [switch]$disabled,

        [Parameter(Mandatory=$false)]
        [PSCustomObject]$labels = @{},

        [Parameter(Mandatory=$false)]
        [ValidateSet("primary","secondary")]
        [string]$zoneType = "primary",

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [string]$admin,

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [switch]$dnssecEnabled,

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [switch]$useCustomSOAParameters,

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [PSCustomObject]$customSOAParameters,

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [Array]$defaultRRSetGroup,

        [Parameter(Mandatory=$false,
            ParameterSetName='primary')]
        [Array]$RRSetGroup,

        [Parameter(Mandatory=$false)]
        $namespace = 'system'
    )

  

    
    $uri_path = "/api/config/dns/namespaces/${namespace}/dns_zones/${name}"
    $xc_connection = $global:XCConnection

    

    #Initial Object creation
    [PSCustomObject]$body = @{
        "metadata" = @{
            "name" = $name
            "labels" = $labels
            "namespace" = $namespace
        }
        "spec" = @{}
    }

    if($description){$body.metadata.description = $description}
    if($annotations){$body.metadata.annotations = $annotations}
    #disabled property doesnt seem to do anything
    if($disabled.IsPresent -eq $true){$body.metadata.disable = $true}
    if($domain){$body.spec.domain = $domain}

    
    if($zoneType -eq "primary"){
        Write-host "Primary parameter set"

        #Create initial primary spec object
        $primary_spec = @{}

        #admin property does not appear to set anything....
        if($admin){$primary_spec.admin = $admin}

        #if not using custom SOA parameters, use default, otherwise add in custom
        if($useCustomSOAParameters -eq $false){
            $primary_spec["default_soa_parameters"] = $null
        }else{
            $primary_spec["soa_parameters"] = $customSOAParameters
        }

        #Add in default rr set
        if($defaultRRSetGroup.count -gt 0){
            $primary_spec["default_rr_set_group"] = $defaultRRSetGroup
        }

        #Add in additional record sets
        if($RRSetGroup.count -gt 0){
            $primary_spec["rr_set_group"] = $RRSetGroup
        }

        #Add DNS Security Mode
        if($dnssecEnabled.IsPresent){
            $dnssec_mode = @{"enable"= @{}}
           
        }else{
            $dnssec_mode = @{"disable"= @{}}
        }
        $primary_spec.dnssec_mode = $dnssec_mode

        $body.spec["primary"] = $primary_spec

    }elseif($zoneType -eq "secondary"){
        Write-host "secondary parameter set"
    }

    $body_json = ConvertTo-json $body -depth 100
    Write-host $body_json


    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'PUT'
        Body     = $body_json     
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
            "Accept" = "*/*"
            
            
        }
    }

    Write-host $req.uri

    return Invoke-RestMethod @req

}



function Get-XCDNSHealthChecks {
    param(
        [Parameter(Mandatory=$false)]
        [string]$namespace="system",
        
        [Parameter(Mandatory=$false)]
        [string]$labelFilter,

        [Parameter(Mandatory=$false)]
        [string[]]$reportFields,

        [Parameter(Mandatory=$false)]
        [string[]]$reportStatusFields
    )

    <#
        https://docs.cloud.f5.com/docs/api/dns-lb-health-check#operation/ves.io.schema.dns_lb_health_check.API.List

        Seems to be an issue with "report_fields" query parameter. My expectation is the values should match the response schema, however
        you can enter garbage strings and "system_metadata" and "get_spec" are populated
    
    #>

    $uri_path = "/api/config/dns/namespaces/${namespace}/dns_lb_health_checks"
    $xc_connection = $global:XCConnection

    
    $query_params = @{ }

    if($reportFields.Length -gt 0){
        $query_params["report_fields"]=$reportFields
    }

    if($reportStatusFields.Length -gt 0){
        $query_params["report_status_fields"]=$reportStatusFields
    }

    if($labelFilter){
        $query_params["label_filter"]=$labelFilter
    }

    $query_params_uri = ""
    foreach($key in $query_params.keys){
        if($query_params_uri -eq ""){
            $query_params_uri = "?"
        }else{
            $query_params_uri += "&"
        }

        $query_params_uri += $key+"="+($($query_params[$key]) -join ",")
    }
   
    

    $req = @{
        Uri         = $xc_connection.url + $uri_path + $query_params_uri
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }

    return Invoke-RestMethod @req

}



function Get-XCDNSHealthCheck {
    param(
        [Parameter(Mandatory=$false)]
        [string]$namespace="system",
        
        [Parameter(Mandatory=$true)]
        [string]$name,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]$reponseFormat
    )

    <#
        https://docs.cloud.f5.com/docs/api/dns-lb-health-check#operation/ves.io.schema.dns_lb_health_check.API.Get
    #>
 

    $uri_path = "/api/config/dns/namespaces/${namespace}/dns_lb_health_checks/${name}"
    $xc_connection = $global:XCConnection

    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }

    if($responseFormat){
        $req.Uri += "?response_format=${responseFormat}"
    }


    return Invoke-RestMethod @req 

}



function Get-XCDNSLoadBalancers {
    param(
        [Parameter(Mandatory=$false)]
        [string]$namespace="system",
        
        [Parameter(Mandatory=$false)]
        [string]$labelFilter,

        [Parameter(Mandatory=$false)]
        [string[]]$reportFields,

        [Parameter(Mandatory=$false)]
        [string[]]$reportStatusFields
    )

    <#
        https://docs.cloud.f5.com/docs/api/dns-load-balancer#operation/ves.io.schema.dns_load_balancer.API.List

        Seems to be an issue with "report_fields" query parameter. My expectation is the values should match the response schema, however
        you can enter garbage strings and "system_metadata" and "get_spec" are populated
    
    #>

    $uri_path = "/api/config/dns/namespaces/${namespace}/dns_load_balancers"
    $xc_connection = $global:XCConnection

    
    $query_params = @{ }

    if($reportFields.Length -gt 0){
        $query_params["report_fields"]=$reportFields
    }

    if($reportStatusFields.Length -gt 0){
        $query_params["report_status_fields"]=$reportStatusFields
    }

    if($labelFilter){
        $query_params["label_filter"]=$labelFilter
    }

    $query_params_uri = ""
    foreach($key in $query_params.keys){
        if($query_params_uri -eq ""){
            $query_params_uri = "?"
        }else{
            $query_params_uri += "&"
        }

        $query_params_uri += $key+"="+($($query_params[$key]) -join ",")
    }
   
    

    $req = @{
        Uri         = $xc_connection.url + $uri_path + $query_params_uri
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }

    return Invoke-RestMethod @req

}

function Get-XCDNSLoadBalancersHealthStatus {
    param(
        [Parameter(Mandatory=$false)]
        [string]$namespace="system"
    )

    <#
        https://docs.cloud.f5.com/docs/api/dns-load-balancer#operation/ves.io.schema.dns_load_balancer.CustomDataAPI.DNSLBHealthStatusList

    
    #>

    $uri_path = "/api/data/namespaces/${namespace}/dns_load_balancers/health_status"
    $xc_connection = $global:XCConnection

     


    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }

    return Invoke-RestMethod @req

}



function Get-XCDNSLoadBalancerPoolHealthStatus {
    param(
        [Parameter(Mandatory=$false)]
        [string]$namespace="system",
        
        [Parameter(Mandatory=$true)]
        [string]$loadbalancerName,

        [Parameter(Mandatory=$true)]
        [string[]]$poolName
    )

    <#
        https://docs.cloud.f5.com/docs/api/dns-load-balancer#operation/ves.io.schema.dns_load_balancer.CustomDataAPI.DNSLBPoolHealthStatus

    
    #>

    $uri_path = "/api/data/namespaces/${namespace}/dns_load_balancers/${loadbalancerName}/dns_lb_pools/${poolName}/health_status"
    $xc_connection = $global:XCConnection

    
    $req = @{
        Uri         = $xc_connection.url + $uri_path + $query_params_uri
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }

    return Invoke-RestMethod @req

}


function Get-XCDNSLoadBalancerHealthStatus {
    param(
        [Parameter(Mandatory=$false)]
        [string]$namespace="system",
        
        [Parameter(Mandatory=$true)]
        [string]$loadbalancerName,

        [Parameter(Mandatory=$true)]
        [string[]]$poolName
    )

    <#
        https://docs.cloud.f5.com/docs/api/dns-load-balancer#operation/ves.io.schema.dns_load_balancer.CustomDataAPI.DNSLBHealthStatus

    
    #>

    $uri_path = "/api/data/namespaces/${namespace}/dns_load_balancers/${loadbalancerName}/health_status"
    $xc_connection = $global:XCConnection

    
    $req = @{
        Uri         = $xc_connection.url + $uri_path + $query_params_uri
        Method      = 'GET'      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }

    return Invoke-RestMethod @req

}



function ConvertPSObjectToHashtable
{
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertPSObjectToHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = (ConvertPSObjectToHashtable $property.Value).PSObject.BaseObject
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}
