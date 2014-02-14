# API: adminSyndicationDebug


## ACCESS REQUIREMENTS: ##
[[SYNDICATION|CONCEPT_syndication]] - SEARCH


## INPUT PARAMETERS: ##
  * DST: marketplace destination code (usually 3 or 4 digits) which can be obtained from the dst code in appResourceGet 'integrations' file
  * FEEDTYPE: PRODUCT|INVENTORY
  * PID _(optional)_ : PRODUCTID

## OUTPUT PARAMETERS: ##
  * HTML: Html messaging describing the syndication process + any errors

runs the syndication process in realtime and returns an html response describing 'what happened'
