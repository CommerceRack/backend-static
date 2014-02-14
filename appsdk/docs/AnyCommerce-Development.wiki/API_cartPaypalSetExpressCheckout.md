# API: cartPaypalSetExpressCheckout




## INPUT PARAMETERS: ##
  * _cartid: 
  * getBuyerAddress:  0|1 (if true - paypal will ask shopper for address)
  * cancelURL:  ''   (required, but may be blank for legacy checkout)
  * returnURL:  ''	 (required, but may be blank for legacy checkout)
  * useShippingCallbacks _(optional)_ :  0|1 (if true - forces shipping callbacks,
generates an error when giftcards are present and shipping is not free) 
if set to zero, then store settings (enable/disabled) will be used.


## RESPONSE: ##
  * URL: url to redirect checkout to (checkout will finish with legacy method, but you CAN build your own)
  * TOKEN: paypal token
  * ACK: paypal "ACK" message
  * ERR: (optional message from paypal api)
  * _ADDRESS_CHANGED: 1|0
  * _SHIPPING_CHANGED: methodid (the new value of CART->ship.selected_id)
