# API: adminImageFolderList


## ACCESS REQUIREMENTS: ##
[[IMAGE|CONCEPT_image]] - LIST


returns a list of image categories and timestamps for each category

## RESPONSE: ##
  * @folders: 

```json


<Folder ImageCount="5" TS="123" Name="Path1" FID="1" ParentFID="0" ParentName="|"/>
<Folder ImageCount="2" TS="456" Name="Path1b" FID="2" ParentFID="1" ParentName="|Path1"/>
<Folder ImageCount="1" TS="567" Name="Path1bI" FID="3" ParentFID="2" ParentName="|Path1|Pathb"/>
<Folder ImageCount="0" TS="789" Name="Path2" FID="4" ParentFID="0" ParentName="|"/>

```
