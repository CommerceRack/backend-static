# API: adminDataQuery


accesses local management database for a variety of fields/reports

## INPUT PARAMETERS: ##
  * query: 
	listing-active,listing-active-fixed,listing-active-store,listing-active-auction,listing-all,listing-allwattempts,
	event-warnings,event-success,event-pending,event-target-powr.auction,event-target-ebay.auction,event-target-ebay.fixed

  * since_gmt: epoch timestamp - returns all data since that time
  * batchid: batchid (only valid with event- requests)

## OUTPUT PARAMETERS: ##
  * @HEADER: 
  * @ROWS: 


### Additional Access Notes: ###
 * EBAY: 

