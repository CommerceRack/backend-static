# API: adminProductCreate


## ACCESS REQUIREMENTS: ##
[[PRODUCT|CONCEPT_product]] - CREATE


creates a new product in the database

[Concept - product](concept_product)

## INPUT PARAMETERS: ##
  * pid: pid : an A-Z|0-9|-|_ -- max length 20 characters, case insensitive
  * %attribs: [ 'zoovy:prod_name':'value' ]

```json

%attribs:[ 'zoovy:prod_name':'value' ]
```
