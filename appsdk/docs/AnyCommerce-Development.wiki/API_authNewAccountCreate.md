# API: authNewAccountCreate



establish a new anycommerce account (this data should be collected during the registration process)


## INPUT PARAMETERS: ##
  * domain: 
  * email: 
  * firstname: 
  * lastname: 
  * company: 
  * phone: 
  * verification: sms|voice

> NOTE:
> returns a valid token to the account
> 

## RESPONSE: ##
  * ts: timestamp
  * userid: login@username
  * deviceid: login@username
  * authtoken: login@username
