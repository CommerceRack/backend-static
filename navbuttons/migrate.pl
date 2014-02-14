#!/usr/bin/perl

use lib "/httpd/modules";

my %bg = ();
opendir $D, "/httpd/static/navbuttons.old";
while ( my $file = readdir($D) ) {
	next if (substr($file,0,1) eq '.');

	my $buf = undef;
	open F, "</httpd/static/navbuttons.old/$file"; $/ = undef; $buf = <F>; $/ = "\n"; close F;

	if ($file =~ /^(.*?)\.gif$/) {
		my $file = $1;
		open F, ">/httpd/static/navbuttons/$file/background.gif";
		print F $buf;
		close F;
		$bg{ $file  } = "background.gif";
		}
	elsif ($file =~ /^(.*?)\.jpg$/) {
		my $file = $1;
		open F, ">/httpd/static/navbuttons/$file/background.jpg";
		print F $buf;
		close F;
		$bg{$file} = "background.jpg";
		}
	elsif ($file =~ /^(.*?)\.ini$/) {
		my $dirx = $1;
	
		my $dir = "/httpd/static/navbuttons/$dirx";
		mkdir $dir;
		chmod 0777, $dir;
		
		open F, ">$dir/legacy.ini";
		print F $buf;
		close F;	
		}
	else {
		print "FILE: $file\n";
		}

	}
closedir($D);


foreach my $k (keys %bg) {
	print "K: $k\n";
	open Fx, ">>/httpd/static/navbuttons/$k/legacy.ini";
	print Fx "bgimage = $bg{$k}\n";
	close Fx;
	}