# pwshF5DistributedCloud

This repository contains a PowerShell Module for interacting with the F5 Distributed Cloud REST API. It is currently in early development phase where initial functions are being developed.


All functions will be prefixed with "XC" after the relevant (standard) PowerShell verb. i.e.

`Get-XCNamespaces`  
`New-XCDNSZone`  
`Remove-XCDNSZone`


## Usage

### Pre-requisites

1. Import the module  
`Import-module pwshF5DistributedCloud`

2. Generate API Key in Distributed Cloud console by following the below steps:  
  a. Select your account icon on the top right of the Distributed Cloud console  
  b. Select `Account Settings`  
  c. Select `Credentials`
  d. Select `Add Credential`
  e. As this module currently only support API Token authentication, select `API Token` from the `Credential type` dropdown
  f. Set `expiry date`
  g. Select `Generate`

3. Take note of your account tenancy (first section of your URL)



### Setting Connection Details

1. Set the connection details by executing the `Set-XCConnectionDetails` function, i.e.

  `Set-XCConnectionDetails -apiToken $api_token -tenant $tenant`


### Example Commands


`Get-XCDNSZones`  
`Get-XCDNSDomains`




## TO DO:

1. Add help messages and example usage to functions
2. Add the other 1,000 API commands!


