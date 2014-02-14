#!/usr/bin/perl

use Text::CSV;

$version = Text::CSV->version();      # get the module version
$csv = Text::CSV->new();              # create a new object

$status = $csv->combine(@columns);    # combine columns into a string
$line = $csv->string();               # get the combined string

$status = $csv->parse($line);         # parse a CSV string into fields
@columns = $csv->fields();            # get the parsed fields

open F, "<highrisk.txt";
while (<F>) {	
	# print $_."\n";
	$line = $_;
	$line =~ s/[\n\r]+//g;
	($line) = split(/,/,$line);
	($line) = split(/:/,$line);
	$line =~ s/"//g;
	next if (substr($line,0,1) eq '#');
	print "<option>$line</option>\n";
	}
close F;