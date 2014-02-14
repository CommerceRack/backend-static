# API: adminGiftcardCreate


## ACCESS REQUIREMENTS: ##
[[GIFTCARD|CONCEPT_giftcard]] - CREATE




## INPUT PARAMETERS: ##
  * expires: YYYYMMDD
  * balance: currency
  * quantity: defaults to 1 (if not specified)
  * email _(optional)_ : if a customer exists this will be matched to the cid, if a customer cannot be found a new customer account will be created, not compatible with qty > 1
  * series _(optional)_ : a mechanism for grouping cards, usually used with quantity greater than 1
