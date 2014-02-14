# API: adminKPIDBDataQuery


## ACCESS REQUIREMENTS: ##
[[DASHBOARD|CONCEPT_dashboard]] - LIST




## INPUT PARAMETERS: ##
  * @datasets _(required)_ : ['dataset1','dataset2']
  * grpby _(required)_ : day|dow|quarter|month|week|none
  * column _(required)_ : gms|distinct|total
  * function _(required)_ : sum|min|max|avg
  * period _(optional)_ : a formula ex: months.1, weeks.1
  * startyyyymmdd _(optional)_ : (not needed if period is passed)
  * stopyyyymmdd _(optional)_ : (not needed if period is passed)
