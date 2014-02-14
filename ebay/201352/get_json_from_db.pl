#!/usr/bin/env perl

## Fetches item specifics recommendation .json from compressed db
## and dumps into console
##
## If you want to get specs for Books -> Fiction & Literature (category 377):
## ./get_json_from_db 377
## ./get_json_from_db 377 > 377.json

use strict;
use warnings;
use Compress::Zlib;
use Data::Dumper;
use DBI;
use JSON::XS;
use File::Basename;

my $dirname = dirname(__FILE__);
my $dbpath = $dirname.'/ebay.db';

if($ARGV[0]) {
	die "No database found at $dbpath" unless -f $dbpath;
	my $edbh	= DBI->connect("dbi:SQLite:dbname=$dbpath","","");
	my ($cid,$site) = ($ARGV[0],0);
	$site = $1 if $ARGV[0] =~ /\.(d+)/;
	my $rec = $edbh->selectrow_hashref("SELECT * FROM ebay_specifics WHERE site=? AND cid=?",{},$site,$cid);
	if($rec) {
		print Compress::Zlib::memGunzip($rec->{json});
		#print JSON::XS::decode_json(Compress::Zlib::memGunzip($specifics->{json}));
		} 
	else {
		print "No recommendations found for category $ARGV[0]\n"
		}
	} 
else {
	print "Syntax: $0 <catID>\n";
	print "Syntax: $0 <catID.site>\n";
	print "site=0 for eBay USA (default), site=100 for eBay Motors\n";
}