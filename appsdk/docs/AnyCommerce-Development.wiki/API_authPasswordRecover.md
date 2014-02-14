# API: authPasswordRecover


employs the password recovery mechanism for the account (currently only email)

## INPUT PARAMETERS: ##
  * session: random session id (32 character)
  * ts: timestamp

## RESPONSE: ##
  * userkey: secret user key
  * ts: current time
