# API: adminCustomerDetail


## ACCESS REQUIREMENTS: ##
[[CUSTOMER|CONCEPT_customer]] - DELETE/REMOVE




## INPUT PARAMETERS: ##
  * CID: Customer ID
  * newsletters: 1 (returns @NEWSLETTERS)
  * addresses: 1  (returns @BILLING @SHIPPING)   [[ this may duplicate data from %CUSTOMER ]]
  * wallets: 1   (returns @WALLETS)
  * wholesale: 1  (returns %WS)
  * giftcards: 1 (returns @GIFTCARDS)
  * tickets: 1 (returns @TICKETS)
  * notes: 1 (returns @NOTES)
  * events: 1 (returns @EVENTS)
  * orders: 1 (returns @ORDERS)

## RESPONSE: ##
  * %CUSTOMER: Customer Object

[Concept - wallet](concept_wallet)
