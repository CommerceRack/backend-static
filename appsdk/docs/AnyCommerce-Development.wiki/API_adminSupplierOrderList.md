# API: adminSupplierOrderList


## ACCESS REQUIREMENTS: ##
[[ORDER|CONCEPT_order]] - READ/DETAIL
[[SUPPLIER|CONCEPT_supplier]] - READ/DETAIL




[Concept - supplier](concept_supplier)

## INPUT PARAMETERS: ##
  * VENDORID: 6-8 digit supplier/vendor id
  * FILTER _(required)_ : UNCONFIRMED|RECENT
  * FILTER=UNCONFIRMED _(optional)_ : The last 300 non corrupt/non error orders which have no confirmed timestamp
  * FILTER=RECENT _(optional)_ : The last 100 unarchived orders
  * DETAIL _(required)_ : 1|0 includes an optional @ORDERDETAIL in response

## OUTPUT PARAMETERS: ##
  * @ORDERS: detail about the vendor/supplier orders
  * @ORDERDETAIL: 
