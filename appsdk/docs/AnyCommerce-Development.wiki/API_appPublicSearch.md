# API: appPublicSearch




## INPUT PARAMETERS: ##
  * _cartid: 
  * type: product|faq|blog
  * type: ['product','blog']

> NOTE:
> if not specified then: type:_all is assumed.
> 
> NOTE:
> www.elasticsearch.org/guide/reference/query-dsl/
> 

## INPUT PARAMETERS: ##
  * mode: elastic-native
  * filter:  { 'term':{ 'profile':'DEFAULT' } };
  * filter:  { 'term':{ 'profile':['DEFAULT','OTHER'] } };	## invalid: a profile can only be one value and this would fail
  * filter:  { 'or':{ 'filters':[ {'term':{'profile':'DEFAULT'}},{'term':{'profile':'OTHER'}}  ] } };
  * filter:  { 'constant_score'=>{ 'filter':{'numeric_range':{'base_price':{"gte":"100","lt":"200"}}}};
  * query:  {'text':{ 'profile':'DEFAULT' } };
  * query:  {'text':{ 'profile':['DEFAULT','OTHER'] } }; ## this would succeed, 

## RESPONSE: ##
  * size: 100 # number of results
  * sort: ['_score','base_price','prod_name']
  * from: 100	# start from result # 100
  * scroll: 30s,1m,5m

> NOTE:
> 
> Filter is an exact match, whereas query is a token/substring match - filter is MUCH faster and should be used
> when the exact value is known (ex: tags, profiles, upc, etc.)
> <ul> KNOWN KEYS:
> * pid
> * skus: [ 'PID:ABCD', 'PID:ABCE' ]
> * options : [ 'Size: Large', 'Size: Medium', 'Size: Small' ]
> * pogs: [ 'AB', 'ABCD', 'ABCE' ]
> * tags: [ IS_FRESH, IS_NEEDREVIEW, IS_HASERRORS, IS_CONFIGABLE, IS_COLORFUL, IS_SIZEABLE, IS_OPENBOX, IS_PREORDER, IS_DISCONTINUED, IS_SPECIALORDER, IS_BESTSELLER, IS_SALE, IS_SHIPFREE, IS_NEWARRIVAL, IS_CLEARANCE, IS_REFURB, IS_USER1, ..]
> * images: [ 'path/to/image1', 'path/to/image2' ]
> * ean, asin, upc, fakeupc, isbn, prod_mfgid
> * accessory_products: [ 'PID1', 'PID2', 'PID3' ]
> * related_products: [ 'PID1', 'PID2', 'PID3' ]
> * base_price: amount*100 (so $1.00 = 100)
> * keywords: [ 'word1', 'word2', 'word3' ]
> * assembly: [ 'PID1', 'PID2', 'PID3' ],
> * prod_condition: [ 'NEW', 'OPEN', 'USED', 'RMFG', 'RFRB', 'BROK', 'CRAP' ]
> * prod_name, description, detail
> * prod_features
> * prod_is
> * prod_mfg
> * profile
> * salesrank
> </ul>
> 

## RESPONSE: ##
  * @products: an array of product ids
  * @LOG: an array of strings explaining how the search was performed (if LOG=1 or TRACEPID non-blank)

**CAUTION: 
Using LOG=1 or TRACEPID in a product (non debug) environment will result in the search feature being
disabled on a site.
**
