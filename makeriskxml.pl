#!/usr/bin/perl

##OUTPUT FORMAT:
#<?xml version="1.0" encoding="iso-8859-1"?> 
#<countries> 
#<country label="United States" data="U.S."/> 
#<country label="Canada" data="Canada"/> 
#<country label="Mexico" data="Mexico"/> 
#</countries> 

require Text::CSV;
$risk = @ARGV[0];
$xml .= "<?xml version='1.0' encoding='iso-8859-1'?>\n";
$xml .= "<countries>\n";	
                        
$file = $risk."risk.csv";
open (F, "/httpd/static/$file") or die ("can't open file to  from:$!");
      $text = <F>;
      while($text){
        $_ = $text;
	$one = substr($text,0,1);
	if ($one eq "\#"){
		print "SKIP\n";
	}else{	
            my $csv = Text::CSV->new;
            my $column = '';
            my $inputstring = $text;
            if ($csv->parse($inputstring)) {
               my @field = $csv->fields;
               my $count = 0;
               for $column (@field) {
                 #print ++$count, " => ", $column, "\n";
			if($column ne ''){
				##CREATE XML STRING
				if($count == 0){
					$xml .= "<country ";
					$xml .= "label=\"$column\" data=\"$column\"";
					$xml .= "/>\n";
				}
				$count++;
               		}
		}	
            }else{
                  my $err = $csv->error_input;
                  print "parse() failed on argument: ", $err, "\n";
            }
	}	
	 $text = <F>;
      }
$xml .= "</countries>";
close F;

open (F, ">".$risk."risk.xml") or die ("Can't open file to print to:$!");
print F $xml;
close F;
print $risk."risk.xml has been generated successfully\n";
