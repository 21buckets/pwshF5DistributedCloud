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



function Get-HttpLoadbalancers {
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

function Get-HttpLoadbalancer {
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


function Get-Routes {
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


function Get-DNSDomains {
    
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

function Get-DNSDomain {

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



function Create-DNSDomain {

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


    $req = @{
        Uri         = $xc_connection.url + $uri_path
        Method      = 'POST'
        Body     = $body      
        ContentType = 'application/json'
        Headers = @{
            "Authorization" = "APIToken $($xc_connection.api_token)"
        }
    }

    return Invoke-RestMethod @req -debug
}

