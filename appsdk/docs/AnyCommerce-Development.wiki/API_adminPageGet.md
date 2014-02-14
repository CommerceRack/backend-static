# API: adminPageGet


## ACCESS REQUIREMENTS: ##
[[PAGE|CONCEPT_page]] - READ/DETAIL




## INPUT PARAMETERS: ##
  * PATH:  .path.to.page or @CAMPAIGNID
  * @get:  [ 'attrib1', 'attrib2', 'attrib3' ]
  * all:  set to 1 to return all fields (handy for json libraries which don't return @get=[]) 

```json

attrib1:xyz
attrib2:xyz
```

> NOTE:
> leave @get blank for all page attributes
> 
