# API: cartItemsAddSerialized




## INPUT PARAMETERS: ##
  * _cartid: 
  * data: which is a form serializes (jquery.serialize) variables the cart. [[LINKDOC]50110]

> NOTE:
> Returns: see addToCart
> 

_HINT: 

This internally decodes 'data' from key1=value1&key2=value2 and passes it to addToCart, it's provided
as a convenience to developers who want to quickly use jquery serialize to a form.

_
