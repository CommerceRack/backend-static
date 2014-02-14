# API: adminImageList


## ACCESS REQUIREMENTS: ##
[[IMAGE|CONCEPT_image]] - L 


returns the list of images for a given folder (if specified). 

## INPUT PARAMETERS: ##
  * folder: folder to view
  * reindex: if a folder is requested, this will reindex the current folder
  * keyword: keyword (uses case insensitive substring)
  * orderby: NONE|TS|TS_DESC|NAME|NAME_DESC|DISKSIZE|DISKSIZE_DESC|PIXEL|PIXEL_DESC
  * detail: NONE|FOLDER

## RESPONSE: ##
  * @images: 

```json


<Image Name="abc" TS="1234" Format="jpg" />
<Image Name="abc2" TS="1234" Format="jpg" />
<Image Name="abc3" TS="1234" Format="jpg" />
<Image Name="abc4" TS="1234" Format="jpg" />
<Image Name="abc5" TS="1234" Format="jpg" />

```
