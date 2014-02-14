# API: cartShippingMethods




## INPUT PARAMETERS: ##
  * _cartid: 
  * trace: 0|1	(optional)
  * update: 0|1 (optional - defaults to 0): set the shipping address, etc. in the cart to the new values.

_HINT: 
in cart the following pieces of data must be set:
	data.ship_address
	data.ship_country
	data.ship_zip
	data.ship_state
_

```json

@methods = [
	[ id:, name:, carrier:, amount
	]
```
