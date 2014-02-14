# API: buyerOrderGet



Grabs a raw order object (buyer perspective) so that status information can be displayed. 


## INPUT PARAMETERS: ##
  * _cartid: 

_HINT: In order to access an order status the user must either be an authenticated buyer, OR use softauth=order with
cartid + either orderid or erefid_

## INPUT PARAMETERS: ##
  * softauth: order
  * erefid: (conditionally-required for softauth=order) external reference identifier (ex: ebay sale #) or amazon order #
  * orderid: (conditionally-required for softauth=order) internal zoovy order #
  * cartid: (conditionally-required for softauth=order) internal cartid #
  * orderid: (required for softauth=order) original cart session id
