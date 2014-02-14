# API: adminVersionCheck




## INPUT PARAMETERS: ##
  * client: 
  * version: 
  * stationid: 
  * subuser: 
  * localip: 
  * osver: 
  * finger: 

Checks the clients version and compatibility level against the API's current compatibility level.

## OUTPUT PARAMETERS: ##
  * : 
RESPONSE can be either
* OKAY - proceed with normal
* FAIL - a reason for the failure
* WARN - a warning, but it is okay to proceed


```json

ConfigVersion
Response
ResponseMsg
```
