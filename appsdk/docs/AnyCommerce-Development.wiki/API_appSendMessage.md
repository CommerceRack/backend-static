# API: appSendMessage




## INPUT PARAMETERS: ##
  * _cartid: 
  * msgtype:  feedback
  * sender:  user@domain.com   [the sender of the message]
  * subject:  subject of the message
  * body:  body of the message
  * PRODUCT _(optional)_ : product-id-this-tellafriend-is-about
  * OID _(optional)_ : 2012-01-1234  [the order this feedback is about]

> NOTE:
> 
> msgtype:feedback requires 'sender', but ignores 'recipient'
> msgtype:tellafriend requires 'recipient', 'product'
> msgtype:tellafriend requi 'product'
> 
