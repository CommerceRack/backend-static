# API: adminPrivateSearch


## ACCESS REQUIREMENTS: ##
[[ORDER|CONCEPT_order]] - SEARCH




## INPUT PARAMETERS: ##
  * _cartid: 
  * type: order
  * type: ['order']

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
> </ul>
> 

## RESPONSE: ##
  * @products: an array of product ids
  * @LOG: an array of strings explaining how the search was performed (if LOG=1 or TRACEPID non-blank)

**CAUTION: 
Using LOG=1 or TRACEPID in a product (non debug) environment will result in the search feature being
disabled on a site.
**
