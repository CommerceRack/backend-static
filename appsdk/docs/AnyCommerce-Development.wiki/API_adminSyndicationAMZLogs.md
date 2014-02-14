# API: adminSyndicationAMZLogs


## ACCESS REQUIREMENTS: ##
[[SYNDICATION|CONCEPT_syndication]] - READ/DETAIL


## INPUT PARAMETERS: ##
  * DST: marketplace destination code (usually 3 or 4 digits) which can be obtained from the dst code in appResourceGet 'integrations' file

## OUTPUT PARAMETERS: ##
  * @ROWS: 
	[ pid, sku, feed, ts, msgtype, msg ]


returns up to 1000 products where the amazon error flag is set in the SKU Lookup table.
