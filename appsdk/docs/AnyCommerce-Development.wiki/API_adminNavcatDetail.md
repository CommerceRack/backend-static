# API: adminNavcatDetail


## ACCESS REQUIREMENTS: ##
[[NAVCAT|CONCEPT_navcat]] - READ/DETAIL


returns detailed information about a navigation category or product list.

## INPUT PARAMETERS: ##
  * prt _(optional)_ : returns the navigation for partition
  * navtree _(optional)_ : returns the navigation for navtree specified (use the navtree parameter from adminNavTreeList)

[Concept - navcat](concept_navcat)

## OUTPUT PARAMETERS: ##
  * : 
path:.safe.name or path:$listname
returns:
pretty:'some pretty name',
@products:['pid1','pid2','pid3'],
%meta:['prop1':'data1','prop2':'data2']

