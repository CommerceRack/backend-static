#!/usr/perl

use File::Slurp;
use JSON::XS;
use lib "/httpd/modules";
use Data::Dumper;

my $ts = time();


my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

opendir $D, "/httpd/static/definitions/amz";
while ( my $file = readdir($D) ) {
	next if (substr($file,0,1) eq '.');
	next if ($file !~ /\.json$/);
	print "FILE: $file\n";

	my $json = File::Slurp::read_file("/httpd/static/definitions/amz/$file");
	my $jrefs = JSON::XS::decode_json($json);

	foreach my $ref (@{$jrefs}) {
		if (defined $ref->{'_pretty'}) {
			$ref->{'xmlpath'} = $ref->{'_pretty'};
			delete $ref->{'_pretty'};
			}
		delete $ref->{'_longerific'};
		delete $ref->{'longerific'};
		delete $ref->{'_attrib'};
		delete $ref->{'_order'};
		delete $ref->{'_short'};
		}


   $pretty_printed_unencoded = $coder->encode($jrefs);

#	open F, ">/httpd/static/definitions/amz/$file.$ts";
#	print F $json;
#	close F;

	open F, ">/httpd/static/definitions/amz/$file";
	print F $pretty_printed_unencoded;
	close F;
	}
closedir $D;