# API: appMashUpSMTP


[Concept - mashup](concept_mashup)



> NOTE:
> 

## INPUT PARAMETERS: ##
  * permission: .mashups/smtp-sample.json
  * sender _(optional)_ : 
  * recipient _(optional)_ : 
  * subject _(optional)_ : 
  * body: 

```json

{
	"call":"appMashUpSMTP",			/* required */
	"call-limit-daily":"10",		/* recommended: max of 10 calls per day */
	"call-limit-hourly":"2",		/* recommended: max of 2 calls per hour */
	"min-version":201338,			/* recommended: minimum api version */
	"max-version":201346,			/* recommended: maximum api version */
	"@whitelist":[
		/* the line below will force the sender to you@domain.com */
		{ "id":"sender",    "verb":"set", "value":"you@domain.com" },
		/* the line above will use the recipient provided in the app call */
		{ "id":"recipient", "verb":"get" },
		/* this is an optional parameter, provided by the app, defaulting to "unknown" */
		{ "id":"eyecolor",  "verb":"get", "default":"unknown" },
		/* the default behavior is "verb":"get" .. so this is basically whitelisting subject */
		{ "id":"subject"    },
		/* the body message, which will substitute %eyecolor% */
		{ "id":"body", 	  "verb":"sub", "value":"Your eye color is: %eyecolor%" }
		]
}
```
