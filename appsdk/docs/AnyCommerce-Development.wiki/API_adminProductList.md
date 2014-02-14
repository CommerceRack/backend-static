# API: adminProductList


## ACCESS REQUIREMENTS: ##
[[PRODUCT|CONCEPT_product]] - LIST


accesses the product database to return a specific hardcoded list of products

## INPUT PARAMETERS: ##
  * CREATED_BEFORE: modified since timestamp
  * CREATED_SINCE: modified since timestamp
  * SUPPLIER: supplier id

_HINT: 
indexed attributes: zoovy:prod_id,zoovy:prod_name,
zoovy:prod_supplierid,  zoovy:prod_salesrank, zoovy:prod_mfgid,
zoovy:prod_upc, zoovy:profile
_
