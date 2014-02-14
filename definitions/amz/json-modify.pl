#!/usr/perl

use File::Slurp;
use JSON::XS;
use lib "/httpd/modules";
use Data::Dumper;

my $ts = time();

opendir $D, "/httpd/static/definitions/amz";
while ( my $file = readdir($D) ) {
	next if (substr($file,0,1) eq '.');
	next if ($file !~ /\.json$/);
	print "FILE: $file\n";

	my $json = File::Slurp::read_file("/httpd/static/definitions/amz/$file");
	my $jrefs = JSON::XS::decode_json($json);

	foreach my $ref (@{$jrefs}) {
		$ref->{'xmlpath'} = $ref->{'_pretty'};
		delete $ref->{'_pretty'};
		delete $ref->{'_longerific'};
		delete $ref->{'longerific'};
		delete $ref->{'_attrib'};
		delete $ref->{'_order'};
		delete $ref->{'_short'};
		print Dumper($ref);
		}

	}
closedir $D;