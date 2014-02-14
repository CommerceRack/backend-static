#!/usr/bin/perl

use Storable;
use Data::Dumper;

$/ = undef;	
open F, "<./default/add_to_site.gif"; 
my $GIF = <F>;
close F; 
open F, "<./default/add_to_site.jpg"; 
my $JPG = <F>;
close F; 
$/ = "\n";

opendir $DX, ".";
while ( my $d = readdir($DX) ) {	
	print "D: $d\n";
#	next if ($d eq 'default');
	next unless (-f "./$d/sitebuttons.ini");

	my %hash = ();
	open F, "<./$d/sitebuttons.ini";
	while (<F>) {
		($k,$v) = split(/=/,$_);
		$k = lc($k);
		$k =~ s/[\s]*$//gs;
		$k =~ s/ /_/gs;
		$v =~ s/[\s]*$//gs;
		$v =~ s/^[\s]*//gs;
		$v =~ s/[\n\r]+//gs;
		# print "K: [$k] V: [$v]\n";
		$hash{$k} = $v;
		}
	close F;
	
	store \%hash, "./$d/sitebuttons.ini.bin";
	chown(65534, 65534, "./$d/sitebuttons.ini.bin");
	
#	open F, ">>./$d/sitebuttons.ini";
#	print F "Add To Site Width = 122\nAdd To Site Height = 32\n";
#	close F;

#	open F, ">./$d/add_to_site.gif"; print F $GIF; close F;
#	chown(65534, 65534, "./$d/add_to_site.gif");

#	open F, ">./$d/add_to_site.jpg"; print F $JPG; close F;
#	chown(65534, 65534, "./$d/add_to_site.jpg");

#	print $d."\n";
	}
closedir $DX;