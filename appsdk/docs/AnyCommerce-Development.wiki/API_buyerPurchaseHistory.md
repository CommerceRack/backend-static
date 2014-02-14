# API: buyerPurchaseHistory




## INPUT PARAMETERS: ##
  * _cartid: 
  * POOL _(optional)_ :  RECENT,COMPLETED, etc.
  * TS _(optional)_ :  modified timestamp from
  * CREATED_GMT _(optional)_ :  created since ts
  * CREATEDTILL_GMT _(optional)_ :  created since ts
  * PAID_GMT _(optional)_ :  paid since
  * PAIDTILL_GMT _(optional)_ :  paid until ts
  * PAYMENT_STATUS _(optional)_ :  
  * PAYMENT_METHOD _(optional)_ :  tender type (ex: CREDIT)
  * SDOMAIN _(optional)_ :  
  * MKT _(optional)_ :   a report by market (use bitwise value)
  * EREFID _(optional)_ :  
  * LIMIT _(optional)_ :  max record sreturns
  * CUSTOMER _(optional)_ :   the cid of a particular buyer.
  * DETAIL _(optional)_ :   1 - minimal (orderid + modified)
         3 - all of 1 + created, pool
			5 - full detail
         0xFF - just return objects


**CAUTION: 
This can ONLY be used for authenticated buyers.
**
