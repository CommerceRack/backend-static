# API: adminOrderPaymentMethods


## ACCESS REQUIREMENTS: ##
[[ORDER/PAYMENT|CONCEPT_order/payment]] - U



displays a list of payment methods available for an order (optional), there are a few scenarios where things
get wonky.
first - if the logged in user is admin, then additional methods like cash, check, all become available (assuming they are
enabled).
second - if the order has a zero dollar total, only ZERO will be returned.
third - if the order has giftcards, no paypalec is available. (which is fine, because paypalec is only available for the client)
fourth - if the order has paypalec payment (already) then other methods aren't available, because paypal doesn't support mixing and matching payment types.


## INPUT PARAMETERS: ##
  * _cartid: 
  * orderid _(optional)_ : orderid #
  * customerid _(optional)_ : customerid #
  * country _(optional)_ : ISO country cod
  * ordertotal _(optional)_ : #####.##

## RESPONSE: ##
  * @methods: 

```json

@methods = [
	[ id:"method", pretty:"pretty title", fee:"##.##" ],
	[ id:"method", pretty:"pretty title", fee:"##.##" ]
	]
```
