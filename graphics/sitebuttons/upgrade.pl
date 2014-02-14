#!/usr/bin/perl

use lib "/httpd/modules";
use Data::Dumper;
use INI;
use ZTOOLKIT;


opendir $D, ".";
while ( $path = readdir($D) ) {
	next if (substr($path,0,1) eq '.');
	next if (! -d $path);	

	if (-f "/httpd/site/sitebuttons/$path/sitebuttons.DO_NOT_USE_THIS") {
		rename("/httpd/site/sitebuttons/$path/sitebuttons.DO_NOT_USE_THIS","/httpd/site/sitebuttons/$path/sitebuttons.ini");
		}

	next if (! -f "/httpd/site/sitebuttons/$path/sitebuttons.ini");

	my $REF = &INI::read_ini("/httpd/site/sitebuttons/$path/sitebuttons.ini",'',1,0,0,0,0);
	print "/httpd/site/sitebuttons/$path/sitebuttons.ini\n";
	print Dumper($REF);

	next if ((keys %{$REF})==0);
	my $ext = $REF->{'extension'};

	delete $REF->{'extension'};
	delete $REF->{'name'};

	my $default = undef;
	foreach my $btn (keys %{$REF}) {
		if ($btn =~ /^(.*?)_width$/) {
			$btn = $1; 		# add_to_cart_width becomes add_to_cart
			$REF->{$btn} = $path.'|'.$ext.'|'.$REF->{$btn."_width"}.'|'.$REF->{$btn.'_height'};
			delete $REF->{$btn.'_width'};
			delete $REF->{$btn.'_height'};
			if (not defined $default) { 
				$default = $REF->{$btn};
				$REF->{'default'} = $default;
				delete $REF->{$btn};
				}
			elsif ($REF->{$btn} eq $default) { delete $REF->{$btn}; }
			}
		}

	$info = &ZTOOLKIT::buildparams($REF);
	print "FILE: $path [$info]\n";

	open F, ">/httpd/site/sitebuttons/$path/info.txt";
	print F $info;
	close F;

	rename("/httpd/site/sitebuttons/$path/sitebuttons.ini","/httpd/site/sitebuttons/$path/sitebuttons.DO_NOT_USE_THIS");
	}
closedir $D;