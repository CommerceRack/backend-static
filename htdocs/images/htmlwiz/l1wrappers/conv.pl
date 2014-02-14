#!/usr/bin/perl

use lib "/httpd/modules";
# use SITE;
use Image::Magick;
use INI;

open I, ">output/index.txt";
print I "<STUFF>\n";

opendir(D,".");
while ( $p = readdir(D)) {
	next if (substr($p,0,1) eq '.');
	next if (-f $p);
	next if ($p eq 'output');
	print "$p\n";

#	&SITE::init();
	open F, "<$p/main.zhtml"; $/ = undef;
	$buf = <F>;
	close F; $/ = "\n";

	open F, "<foo.txt"; $/ = undef;
	$foo = <F>;
	close F; $/ = "\n";
	$foo =~ s/REPLACETHIS/$p/;
	open F, ">output/$p.txt";
	print F $foo;
	close F;

	$body = "<center><!-- IMAGE1 --></center><br>\n";
	$body .= "<!-- PRODUCT_DESCRIPTION --><br>\n";
	$body .= "<br><b>Accepted Payments:</b><br>\n";
	$body .= "<!-- PAYMENT_POLICY --><br>\n";
	$body .= "<br><b>Return Policy:</b><br>\n";
	$body .= "<!-- RETURN_POLICY -->\n";
	$body .= "<br>Another Auction By <!-- COMPANY_NAME --><br>\n<br>";

	$buf =~ s/\<\!\-\- BODY \-\-\>/$body/igs;	
	$buf =~ s/<map.*?<\/map>//igs;
	$buf =~ s/<!-- WRAPPER_URL -->/http\:\/\/www\.zoovy\.com\/htmlwiz\/l1wrappers\/$p/igs;
	$buf =~ s/<!-- GRAPHICS_URL -->/http\:\/\/www\.zoovy\.com\/htmlwiz/igs;
	$buf =~ s/<!-- MENU.*?-->//igs;
	$buf =~ s/<!-- BREADCRUMB.*?-->//igs;
	$buf =~ s/<!-- CONFIG.*?-->//igs;
	$buf =~ s/<a href="<!-- HOME_URL -->">//igs;
	$buf =~ s/<!-- LOGO.*?-->/<!-- COMPANY_LOGO -->/igs;
	$buf =~ s/<head>.*?<\/head>//igs;
	$buf =~ s/<!-- FOOTER -->/\&nbsp\;/igs;
	$buf =~ s/$p\/menu\.gif/blank.gif/igs;

	%hash = &INI::read_ini("/httpd/site/themes/$p.ini");
	foreach $k (keys %hash) {
		$buf =~ s/<!--[ ]*$k[ ]*-->/$hash{$k}/igs;
		}
	

	open F, ">output/$p.html";
	print F $buf;
	close F;

	$pretty = $p;
	$pretty =~ s/l1_//igs;

	use Image::Magick;
   $x = new Image::Magick;
   $x->Read("$p/preview.jpg");
   $x->Write("output/$p.gif");
	$x = undef;

	print I "<TEMPLATE NAME=\"$p\">$pretty - style 1</TEMPLATE>\n";
	}
closedir(D);

print I "</STUFF>\n";
close(I);