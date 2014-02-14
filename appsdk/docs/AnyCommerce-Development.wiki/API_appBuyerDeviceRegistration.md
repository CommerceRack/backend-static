# API: appBuyerDeviceRegistration


verify or create a client registration

## INPUT PARAMETERS: ##
  * verb: verifyonly|create
  * deviceid: client generated device key (guid), or well known identifier from device
  * os: android|appleios
  * devicetoken _(optional)_ : devicetoken (appleios) or registrationid (android) is required 
	(to avoid religious debatesboth are equivalent -- either is acceptable)
  * registrationid _(optional)_ : devicetoken (appleios) or registrationid (android) is required 
	(to avoid relgious debates, both are equivalent -- either is acceptable)
  * email _(optional)_ : email registration is insecure and may not always be available

## OUTPUT PARAMETERS: ##
  * CID: client id
