# API: appBuyerAuthenticate


Authenticates a buyer against an enabled/supported trust service

## INPUT PARAMETERS: ##
  * auth: facebook|google
  * create: 0|1
  * token: token
  * id_token: required for auth=google, only id_token or access_token are required (but both can safely be passed)
  * access_token: required for auth=google, only id_token or access_token are required (but both can safely be passed)

## OUTPUT PARAMETERS: ##
  * CID: 
