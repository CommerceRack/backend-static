# API: adminCustomerSelectorDetail


## ACCESS REQUIREMENTS: ##
[[PRODUCT|CONCEPT_product]] - READ/DETAIL


a product customer is a relative pointer to a grouping of customers.

[Concept - customer](concept_customer)

## INPUT PARAMETERS: ##
  * selector: 
CIDS=1,2,3,4
EMAILS=user@domain.com,user2@domain.com
SUBLIST=0	all subscribers (any list)
SUBLIST=1-15	a specific subscriber list
ALL=*			all customers (regardless of subscriber status)


## OUTPUT PARAMETERS: ##
  * @CIDS: an array of product id's
