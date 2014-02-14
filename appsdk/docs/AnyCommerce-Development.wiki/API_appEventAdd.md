# API: appEventAdd



User events are the facility for handling a variety of "future" and "near real time" backend operations.
Each event has a name that describes what type of object it is working with ex: CART, ORDER, PRODUCT, CUSTOMER
then a period, and what happened (or should happen in the future) ex: CART.GOTSTUFF, ORDER.CREATED, PRODUCT.CHANGED
custom program code can be associated with a users account to "listen" for specific events and then take action.


## INPUT PARAMETERS: ##
  * event: CART.REMARKET
  * pid _(optional)_ : product id
  * pids _(optional)_ : multiple product id's (comma separated)
  * safe _(optional)_ : category id
  * sku _(optional)_ : inventory id
  * cid _(optional)_ : customer(buyer) id
  * email _(optional)_ : customer email
  * more _(optional)_ : a user defined field (for custom events)

> NOTE:
> in addition each event generated will record: sdomain, ip, and cartid
> 

## INPUT PARAMETERS: ##
  * uuid _(optional)_ : a unique identifier (cart id will be used if not specified)
  * dispatch_gmt _(optional)_ :  an epoch timestamp when the future event should dispatch
