#!/usr/bin/perl

$risk = @ARGV[0];
my $output;
$file = $risk."risk.txt";
open (F, "/httpd/static/$file") or die ("can't open file to  from:$!");
      $text = <F>;
      while($text){
        $_ = $text;
        $one = substr($text,0,1);
        if ($one eq "\#"){
                print "SKIP\n";
        }else{
		$text =~ s/:/\,/gi;
		$text =~ s/\"//gi;
		$text =~ s/\s//gi;
		$output .= "$text\n";
        }
         $text = <F>;
      }
close F;


open (F, ">".$risk."risk.csv") or die ("Can't open file to print to:$!");
print F $output;
close F;