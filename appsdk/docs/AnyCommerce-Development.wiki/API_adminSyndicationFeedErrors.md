# API: adminSyndicationFeedErrors


## ACCESS REQUIREMENTS: ##
[[SYNDICATION|CONCEPT_syndication]] - SEARCH


## INPUT PARAMETERS: ##
  * DST: marketplace destination code (usually 3 or 4 digits) which can be obtained from the dst code in appResourceGet 'integrations' file

displays up to 500 to remove/hide these.

## OUTPUT PARAMETERS: ##
  * @ROWS: 
	[ timestamp1, sku1, feedtype1, errcode1, errmsg1, batchjob#1 ],
	[ timestamp2, sku2, feedtype2, errcode2, errmsg2, batchjob#2 ],

