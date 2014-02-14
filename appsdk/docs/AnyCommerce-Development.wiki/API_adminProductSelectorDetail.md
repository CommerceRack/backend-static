# API: adminProductSelectorDetail


## ACCESS REQUIREMENTS: ##
[[PRODUCT|CONCEPT_product]] - READ/DETAIL


a product selector is a relative pointer to a grouping of products.

[Concept - product](concept_product)

## INPUT PARAMETERS: ##
  * selector: 
NAVCAT=.safe.path
NAVCAT=$list
CSV=pid1,pid2,pid3
CREATED=YYYYMMDD|YYYYMMDD
RANGE=pid1|pid2
MANAGECAT=/path/to/category
SEARCH=saerchterm
PROFILE=xyz
SUPPLIER=xyz
MFG=xyx
ALL=your_base_are_belong_to_us


## OUTPUT PARAMETERS: ##
  * @products: an array of product id's
