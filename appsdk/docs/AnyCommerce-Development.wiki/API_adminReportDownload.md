# API: adminReportDownload


## ACCESS REQUIREMENTS: ##
[[REPORT|CONCEPT_report]] - LIST




Inside "$R" (the REPORT object) there are following output values:
@HEAD the header object (below)
@BODY the body object (further below)

	that is all that is *required* @DASHBOARDS and @GRAPHS are discussed later.


	@HEAD is an array, of "header columns" structured as such:
		[
		'name'=>'Name of Column',
		'type'=>  	NUM=numeric,  CHR=character, ACT=VERB (e.g. button), 
						LINK=http://www.somelink.com
						ROW (causes the contents to placed in it's own row e.g. a detail summary)
					(see specialty types below)
		'pre'=>	?? pretext
		'post'=> ?? posttext
		],

 
	@BODY is an array of arrays 
		the array is re-ordered based on the current sort (and then re-saved)
		[
			[ 'abc','1','2','3' ],
			[ 'def','4','5','6' ]
		]

	@SUMMARY = [
		{ type=>'BREAK,CNT,SUM,AVG', src=>col#, sprintf=>"formatstr" },
		{ type=>'BREAK,CNT,SUM,AVG', src=>col#, sprintf=>"formatstr" },
		]

	@DASHBOARD = [
		{ 
			title=>'', subtitle=>'', groupby=>col#, 
			@HEAD=>[ 
				{ type=>'NUM|CHR|VAL|SUM|AVG|TOP|LOW|CNT', name=>'name of column', src=col# }
				{ type=>'NUM|CHR|VAL|SUM|AVG|TOP|LOW|CNT', name=>'name of column', src=col# }
				],
			@GRAPHS=>[ 'file1', 'file2', 'file3' ]
		}, 
		{ 
			title=>'', subtitle=>'', groupby=>col#, 
			@HEAD=>[ 
				{ type=>'NUM|CHR|VAL|SUM|AVG|TOP|LOW|CNT', name=>'name of column', src=col# }
				{ type=>'NUM|CHR|VAL|SUM|AVG|TOP|LOW|CNT', name=>'name of column', src=col# }
				],
			@GRAPHS=>[ 'file1', 'file2', 'file3' ]
		}, 
		]

specialty column types: ==
	YJH - Year/JulianDay/Hour
	YJJ - Year/JulianDay
	YWK - Year/Week
 	YMN - Year/Month
	YDT - takes a gmt time and returns the pretty date
	YDU - how many days/hours/minutes/seconds the duration is

	NUM=numeric
	CHR=character
	ACT=VERB (e.g. button) "<input type=\"button\" value=\"Start Dispute\" class=\"button2\" onClick=\"customAction('OPEN','$claim');\">";
	ROW 



[Concept - report](concept_report)

## INPUT PARAMETERS: ##
  * GUID: the globally unique id assigned to this report (probably obtained from a batch job list)
