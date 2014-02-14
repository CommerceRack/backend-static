#!/usr/bin/perl

use lib "/httpd/modules";
use Data::Dumper;
use JSON::XS;
use File::Slurp;

my %VARS = ();
opendir my $D, "/httpd/static/definitions/amz";
while ( my $file = readdir($D) ) {
	next if (substr($file,0,1) eq '.');
	next if ($file !~ /json$/);

	# print "FILE: $file\n";
	my $str = File::Slurp::read_file("/httpd/static/definitions/amz/$file");
	my $ref = JSON::XS::decode_json($str);
	# print Dumper($ref);

	foreach my $node (@{$ref}) {
		next if ($node->{'type'} ne 'textlist');
		# print "$node->{'id'}\n";
		$VARS{$node->{'id'}}++;
		}

	}
closedir $D;

foreach my $k (sort keys %VARS) {
	print "$k\n";
	}
