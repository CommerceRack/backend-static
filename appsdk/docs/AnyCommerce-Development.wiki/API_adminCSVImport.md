# API: adminCSVImport


## ACCESS REQUIREMENTS: ##
[[JOB|CONCEPT_job]] - CREATE



This is a wrapper around the CSV file import available in the user interface.
Creates an import batch job. Filetype may be one of the following:
* PRODUCT
* INVENTORY
* CUSTOMER
* ORDER
* CATEGORY
* REVIEW
* REWRITES
* RULES
* LISTINGS



_HINT: 
The file type may also be overridden in the header. See the CSV import documentation for current
descriptions of the file. 
_

## INPUT PARAMETERS: ##
  * filetype: PRODUCT|INVENTORY|CUSTOMER|ORDER|CATEGORY|REVIEW|REWRITES|RULES|LISTINGS
  * fileguid: guid from fileupload
  * [headers]: any specific headers for the file import

## OUTPUT PARAMETERS: ##
  * JOBID: 
