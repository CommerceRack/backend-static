# API: adminWalletList


## ACCESS REQUIREMENTS: ##
[[CUSTOMER/WALLET|CONCEPT_customer/wallet]] - LIST




## INPUT PARAMETERS: ##
  * method: CHANGED
  * limit: ###

```json


@WALLETS : [
{ ID="" CID="" CREATED="" EXPIRES="" IS_DEFAULT="" DESCRIPTION="" ATTEMPTS="" FAILURES="" IS_DELETED="" }
{ ID="" CID="" CREATED="" EXPIRES="" IS_DEFAULT="" DESCRIPTION="" ATTEMPTS="" FAILURES="" IS_DELETED="" }
{ ID="" CID="" CREATED="" EXPIRES="" IS_DEFAULT="" DESCRIPTION="" ATTEMPTS="" FAILURES="" IS_DELETED="" }


```

## INPUT PARAMETERS: ##
  * method: ACK
  * @WALLETS: an array of wallets to ack.
