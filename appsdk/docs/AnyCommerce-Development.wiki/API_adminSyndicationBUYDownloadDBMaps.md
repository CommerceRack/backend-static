# API: adminSyndicationBUYDownloadDBMaps


## ACCESS REQUIREMENTS: ##
[[SYNDICATION|CONCEPT_syndication]] - READ/DETAIL


## INPUT PARAMETERS: ##
  * DST: BUY|BST


	buy.com/bestbuy.com have support for json dbmaps, which allow uses to create ad-hoc schema that maps existing product attributes to buy.com data.
	since buy.com product feeds are no longer sent in an automated fasion the utility of this feature is somewhat limited, but can still be used to perform additional validation
	during/prior to export.
	each dbmap has a 1-8 digit code, and associated json (which uses a modified flexedit syntax).
	each product would then have a corresponding buycom:dbmap or bestbuy:dbmap field set.

