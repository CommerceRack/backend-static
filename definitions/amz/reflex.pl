#!/usr/bin/perl

use strict;

use JSON::XS;
use Data::Dumper;
use File::Slurp;

# goes through the json and identifies any attribute which isn't currently in PRODUCT::FLEXEDIT

use lib "/httpd/modules";
use PRODUCT::FLEXEDIT;

# isolate existing amz: fields in PRODUCT::FLEXEDIT::fields
my @EXISTING_AMZ_FLEX_FIELDS = ();
foreach my $id (keys %PRODUCT::FLEXEDIT::fields) {
	if ($id =~ /^amz\:/) { 
		delete $PRODUCT::FLEXEDIT::fields{$id}->{'src'};
		push @EXISTING_AMZ_FLEX_FIELDS, $id; 
		}
	}

# go through the json files, modify PRODUCT::FLEXEDIT in memory to track the src of various attributes
opendir my $D, "/httpd/static/definitions/amz";
my %VALID = ();
while ( my $f = readdir($D)) {
	next if (substr($f,0,1) eq '.');
	next unless ($f =~ /\.json$/);
	print "F:$f\n";

	my $json = File::Slurp::read_file("/httpd/static/definitions/amz/$f");
	my $fields = JSON::XS::decode_json($json);
	# print Dumper($ref);

	foreach my $ref (@{$fields}) {
		next if (not defined $ref->{'id'});
		# print Dumper($ref)."\n";
		my $id = $ref->{'id'};
		if ($id !~ /:/) {
			print "IGNORING: $id\n";
			}
		elsif (defined $PRODUCT::FLEXEDIT::fields{ $id }) {
			$PRODUCT::FLEXEDIT::fields{$id}->{'src'} = $f;
			$VALID{$id}++;
			}
		else {
			print "MISSING: $id\n";
			$ref->{'src'} = $f;
			$PRODUCT::FLEXEDIT::fields{$id} = $ref;
			$VALID{$id}++;
			}
		}
	}
closedir $D;

# now filter out attributes which are no longer used (have no src=)
foreach my $id (@EXISTING_AMZ_FLEX_FIELDS) {
	if (not defined $PRODUCT::FLEXEDIT::fields{$id}) {
		warn "error $id\n";
		}
	elsif (not defined $PRODUCT::FLEXEDIT::fields{$id}->{'src'}) {
		print "WE CAN REMOVE: $id\n";
		}
	else {
		## yay, still in use!
		}
	}

#print Dumper(@EXISTING_AMZ_FLEX_FIELDS);