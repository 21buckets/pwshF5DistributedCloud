function Set-XCConnectionDetails {
    param(
        [Parameter(Mandatory = $true)]
        $tenant,

        [Parameter(Mandatory = $true)]
        $apiToken
    )


     $global:XCConnection = @{
        url               = "https://${tenant}.console.ves.volterra.io"
        api_token         = $apiToken
    }

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


    return Invoke-RestMethod @req
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

    $dnssec_mode = $dnssecEnable ? "DNSSEC_ENABLE" : "DNSSEC_DISABLE"
    

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


