# API: adminOrderDetail


## ACCESS REQUIREMENTS: ##
[[ORDER|CONCEPT_order]] - READ/DETAIL


provides a full dump of data inside an order

## INPUT PARAMETERS: ##
  * _cartid _(required)_ : admin session id
  * orderid _(required)_ : Order ID

## RESPONSE: ##
  * order: a json representation of an order (exact fields depend on version/order source)
