# API: cartItemUpdate




## INPUT PARAMETERS: ##
  * _cartid: 
  * stid: xyz
  * uuid: xyz
  * quantity: 1
  * _msgs: (contains a count of the number of messages)


### Possible Errors ###
    * .9101: Item cannot be added to cart due to price not set.
    * .9102: could not lookup pogs
    * .9103: Some of the items in this kit are not available for purchase: 
    * .9000: Unhandled item detection error
    * .9001: Product xyz is no longer available
    * .9002: Product xyz has already been purchased

