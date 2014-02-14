#!/usr/bin/perl

use strict;
use lib "/httpd/modules";
use Data::Dumper;
use JSON::XS;
use File::Slurp;

my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

my %VARS = ();
opendir my $D, "/httpd/static/definitions/amz";
while ( my $file = readdir($D) ) {
	next if (substr($file,0,1) eq '.');
	next if ($file !~ /json$/);

	print "FILE: $file\n";
	my $str = File::Slurp::read_file("/httpd/static/definitions/amz/$file");
	my $ref = JSON::XS::decode_json($str);
	# print Dumper($ref);

	my $hidden = undef;
	my $xpath = undef;
	foreach my $node (@{$ref}) {
		## find the first hidden
		if (defined $hidden) {
			}
		elsif ($node->{'type'} eq 'hidden') { $hidden = $node; }
		
		if (defined $xpath) {
			}
		elsif (defined $node->{'xmlpath'}) {
			my @ar = split(/\./,$node->{'xmlpath'});
			pop @ar;	# remove end
			$xpath = join(".",@ar).'.';	# trailing period
			}		
		}
	if ((defined $hidden) && (defined $xpath)) {
		$hidden->{'xmlpath'} = $xpath;
		print Dumper($hidden);
	   my $pretty_printed_unencoded = $coder->encode($ref);

	#	open F, ">/httpd/static/definitions/amz/$file.$ts";
	#	print F $json;
	#	close F;

		open F, ">/httpd/static/definitions/amz/$file";
		print F $pretty_printed_unencoded;
		close F;
		}
	elsif (not defined $hidden) {
		warn "Missing hidden on $file\n";
		}
	elsif (not defined $xpath) {
		warn "Missing xpath on $file\n";
		}

	}
closedir $D;

foreach my $k (sort keys %VARS) {
	print "$k\n";
	}
