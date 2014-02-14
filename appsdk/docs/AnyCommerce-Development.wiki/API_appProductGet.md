# API: appProductGet




## INPUT PARAMETERS: ##
  * _cartid: 
  * pid: productid
  * ver: version#
  * withVariations: 1
  * withInventory: 1
  * withSchedule: 1

> NOTE:
> NOT IMPLEMENTED: navcatsPlease=1 = showOnlyCategories=1
> 

```json

[
	'pid' : product-id,
	'%attribs' : [ 'zoovy:prod_name'=>'xyz' ],
	'@variations' : [ JSON POG OBJECT ],
	'@inventory' : [ 'sku1' : [ 'inv':1, 'res':2 ], 'sku2' : [ 'inv':3, 'res':4 ] ],
]
```

**CAUTION: 
This does not apply schedule pricing.
**

_HINT: 
to tell if a product exists check the value "zoovy:prod_created_gmt".
It will not exist, or be set to zero if the product has been deleted or does not exist OR is not 
accessible on the current partition.
_
