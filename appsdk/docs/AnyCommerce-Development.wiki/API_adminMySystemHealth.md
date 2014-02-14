# API: adminMySystemHealth


## ACCESS REQUIREMENTS: ##
[[HELP|CONCEPT_help]] - CREATE



Runs a series of diagnostics and returns 3 arrays @SYSTEM, @MYAPPS, @MARKET
the call itself may be *VERY* slow - taking up to 30 seconds.

each array will contain one or more responses ex:
{ 
	'type':'critical|issue|alert|bad|fyi|good',
	'system':'a short (3-12 char) global unique identifier for the system ex: Inventory',
	'title':'a pretty title for the message',
	'detail':'not always included, but provides more detail about a specific issue what that could mean, ex:
an unusually large number of unprocessed events does not mean there is a problem per-se,
it means many automation systems such as inventory, supply chain, 
marketplace tracking notifications and more could be delayed.',
	'debug':'xozo some internal crap that means something to a developer',
}



## RESPONSE: ##
  * @SYSTEM: 
  * @MYAPPS: 
  * @MARKET: 
