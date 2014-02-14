# API: adminUIProductPanelExecute


## ACCESS REQUIREMENTS: ##
[[PRODUCT|CONCEPT_product]] - U




## INPUT PARAMETERS: ##
  * pid: Product Identifier
  * sub: LOAD|SAVE|.. (other behaviors may be specified by the actual panel content)
  * panel: Panel Identifier (the 'id' field returned by adminUIProductList

## RESPONSE: ##
  * html: the html content of the product editor panel
  * js: the js which is required by the panel.
