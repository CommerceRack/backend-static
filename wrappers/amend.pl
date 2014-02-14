#!/usr/bin/perl

use lib "/httpd/modules";
use TOXML;
use ZOOVY;
use POSIX;
use Data::Dumper;
use Storable;

$dbh = &DBINFO::db_zoovy_connect();
$pstmt = "select * from THEMES";
$sth = $dbh->prepare($pstmt);
$sth->execute();
while ( $hashref = $sth->fetchrow_hashref() ) {

	print Dumper($hashref);

	($t) = TOXML->new('WRAPPER',$hashref->{'CODE'});
	next if (not defined $t);
	($m) = $t->findElements('CONFIG');
	
	if (not defined $m) {
		push @{$t->{'_ELEMENTS'}}, { 'TYPE'=>'CONFIG' };
		($m) = $t->findElements('CONFIG');
		}

	$m->{'TITLE'} = $hashref->{'NAME'};
	$m->{'CREATED'} = strftime("%Y%m%d",localtime($hashref->{'CREATED_GMT'}));
	$m->{'CATEGORIES'} = $hashref->{'BW_CATEGORIES'};
	$m->{'COLORS'} = $hashref->{'BW_COLORS'};
	$m->{'PROPERTIES'} = $hashref->{'BW_PROPERTIES'};
	if ($hashref->{'IS_POPUP'}) { $m->{'SUBTYPE'} = 'P'; }

	print "$hashref->{'CODE'}\n";
	open F, ">$hashref->{'CODE'}/main.xml";
	print F $t->as_xml();
	close F;

	store $t, "$hashref->{'CODE'}/main.bin";

	#print Dumper($hashref);
	#print Dumper($m);
	}

&DBINFO::db_zoovy_close();