#!/usr/bin/perl

use strict;
use lib "/httpd/modules";
use Data::Dumper;
use JSON::XS;
use File::Slurp;

my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

my %VARS = ();

my $file = 'amz.clothing.json';
my $str = File::Slurp::read_file("/httpd/static/definitions/amz/$file");
my $ref = JSON::XS::decode_json($str);

print Dumper($ref);

#my $config = undef;
#foreach my $node (@{$ref}) {
#	## find the first hidden
#	if (defined $config) {
#		}
#	elsif ($node->{'type'} eq 'config') { $config = $node; }
#	}

#if (not defined $config) {
#	$config = { 'type'=>'config' };
#	unshift @{$ref}, $config;
#	}

	
#my $catalog = undef;
#my $subcat = undef;
#if ($file =~ /amz\.(.*?)\.(.*?)\.json$/) {
#	$catalog = $1; $subcat = $2;
#	}

#	$catalog = uc($catalog);
#	$catalog =~ s/GOURMET/FOOD/;
#	$catalog =~ s/ELECTRONIX/CE/;
#	$catalog =~ s/JEWELRY/JEWERLY/;

my %subcat_pretty = (
		##MUSICALINSTRUMENTS
		 'BRASSANDWOODWINDINSTRUMENTS', 'BrassAndWoodwindInstruments',
		 'KEYBOARDINSTRUMENTS', 'KeyboardInstruments',
		 'PERCUSSIONINSTRUMENTS', 'PercussionInstruments',
						## GOURMET
								 'GOURMETMISC', 'GourmetMisc' );

#		my $xmlsubcat = $subcat_pretty{uc($subcat)};
#		if ($xmlsubcat eq '') { 
#			warn "Did not match on subcat=$subcat";
#			$xmlsubcat = $subcat; 
#			}
#	print "CATALOG[$catalog] SUBCAT[$subcat] XMLSUBCAT[$xmlsubcat]\n";
#	$config->{'catalog'} = $catalog;
#	$config->{'subcat'} = $subcat;
#	$config->{'amz-subcat'} = $xmlsubcat;

#  my $pretty_printed_unencoded = $coder->encode($ref);
#	open F, ">/httpd/static/definitions/amz/$file";
#	print F $pretty_printed_unencoded;
#	close F;
#	print Dumper($ref);
#	}

#foreach my $k (sort keys %VARS) {
#	print "$k\n";
#	}
