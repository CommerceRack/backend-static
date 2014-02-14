# API: buyerOrderUpdate



A macro is a set of commands that will be applied to an order, they are useful because they are applied (whenever possible)
as a single atomic transaction. buyers have access to a subset of macros from full order processing, but enough to adjust
payment, and in some cases cancel orders.


## INPUT PARAMETERS: ##
  * _cartid: 
  * orderid: 2012-01-1234
  * @updates: see example below

> NOTE:
> 
> This uses the same syntax as adminOrderUpdate, but only a subset are supported (actually at this point ALL commands are supported, but we'll restrict this eventually), 
> and may (eventually) differ based on business logic and/or add some custom ones. 
> 

```json

@updates:[
	'cmd',
	'cmd?some=param',
	]
```
```json

Allowed commands:
ADDNOTE
```
