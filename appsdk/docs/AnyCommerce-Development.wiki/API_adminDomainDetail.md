# API: adminDomainDetail


## ACCESS REQUIREMENTS: ##
[[DOMAIN|CONCEPT_domain]] - LIST


## INPUT PARAMETERS: ##
  * DOMAINNAME: 

## OUTPUT PARAMETERS: ##
  * @HOSTS: 
	{ "HOSTNAME":"www", "HOSTTYPE":"APP|REDIR|VSTORE|CUSTOM" },
	HOSTTYPE=APP		will have "PROJECT"
	HOSTTYPE=REDIR	will have "REDIR":"www.domain.com" "URI":"/path/to/301"  (if URI is blank then it will redirect with previous path)
	HOSTTYPE=VSTORE	will have @REWRITES

