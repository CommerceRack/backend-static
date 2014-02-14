# API: adminOrderList


## ACCESS REQUIREMENTS: ##
[[ORDER|CONCEPT_order]] - LIST


returns a list of orders based on one or more filter criteria

## INPUT PARAMETERS: ##
  * _admin _(required)_ : admin session id
  * TS _(optional)_ : modified since timestamp
  * EREFID _(optional)_ : string (external reference id)
  * CUSTOMER _(optional)_ : #CID
  * DETAIL _(optional)_ : 1,3,5
  * POOL _(optional)_ : RECENT,PENDING,PROCESSING
  * PRT _(optional)_ : 
  * BILL_FULLNAME _(optional)_ : string
  * BILL_EMAIL _(optional)_ : string
  * BILL_PHONE _(optional)_ : string
  * SHIP_FULLNAME _(optional)_ : string
  * CREATED_GMT _(optional)_ : #epoch
  * CREATEDTILL_GMT _(optional)_ : #epoch
  * PAID_GMT _(optional)_ : #epoch
  * PAIDTILL_GMT _(optional)_ : #epoch
  * PAYMENT_STATUS _(optional)_ : 001
  * SHIPPED_GMT _(optional)_ : 1/0
  * NEEDS_SYNC _(optional)_ : 1/0
  * MKT _(optional)_ : EBY,AMZ
  * LIMIT _(optional)_ : #int (records returned)

**CAUTION: 
maximum number of records returned is 1,000
**

## RESPONSE: ##
  * @orders: an array of orders containing varied amounts of data based on the detail level requested

```json


@orders:[
	[ 'ORDERID':'2012-01-1234', 'MODIFIED_GMT':123456 ],
	[ 'ORDERID':'2012-01-1235', 'MODIFIED_GMT':123457 ],
	[ 'ORDERID':'2012-01-1236', 'MODIFIED_GMT':123458 ]
	]
```

> NOTE:
> 
> Detail level 3 includes POOL, CREATED_GMT
> Detail level 5 includes CUSTOMER ID, ORDER_BILL_NAME, ORDER_BILL_EMAIL, ORDER_BILL_ZONE, ORDER_PAYMENT_STATUS, ORDER_PAYMENT_METHOD, ORDER_TOTAL, ORDER_SPECIAL, MKT, MKT_BITSTR
> 
