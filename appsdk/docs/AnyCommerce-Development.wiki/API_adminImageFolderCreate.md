# API: adminImageFolderCreate


## ACCESS REQUIREMENTS: ##
[[IMAGE|CONCEPT_image]] - CREATE


creates a new folder in the media library, folder names must be in lower case.

## INPUT PARAMETERS: ##
  * folder: DIR1|DIR2

## RESPONSE: ##
  * fid: the internal folder id#
  * name: the name the folder was created

_HINT: you can call these in any order, subpaths will be created._

```json


<Category FID="1234" Name=""/>

```
