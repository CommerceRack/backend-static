# API: appPageGet




## INPUT PARAMETERS: ##
  * PATH:  .path.to.page or @CAMPAIGNID
  * @get:  [ 'attrib1', 'attrib2', 'attrib3' ]
  * all:  set to 1 to return all fields (handy for json libraries which don't return @get=[]) 

## RESPONSE: ##
  * %page:  [ 'attrib1':'xyz', 'attrib2':'xyz' ],

> NOTE:
> leave @get empty @get = [] for all page attributes
> 
