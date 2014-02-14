#!/usr/bin/perl

use lib "/httpd/modules";
use TOXML;
use ZTOOLKIT;
use INI;
use ZOOVY;
use POSIX;
use Data::Dumper;
use Storable;
use strict;

my $dbh = &DBINFO::db_zoovy_connect();
my $pstmt = "select MID,DOCID from TOXML where MID=0 and FORMAT='WRAPPER'";
my $sth = $dbh->prepare($pstmt);
$sth->execute();
while ( my ($MID,$DOCID) = $sth->fetchrow() ) {

	print STDERR "MID: $MID $DOCID\n";

	my $USERNAME = '';
	if ($MID>0) { $USERNAME = &ZOOVY::resolve_merchant_from_mid($MID); }

	my ($t) = TOXML->new('WRAPPER',$DOCID,USERNAME=>$USERNAME,MID=>$MID);
	next if (not defined $t);

	my ($iniref) = $t->findElements('CONFIG');	
	next if (not defined $iniref);

	if (not defined $iniref) {
		die("USER[$USERNAME] DOCID[$DOCID] has no CONFIG element!\n");
		}

	# next if (index($iniref->{'THEME'},'&')>0);

	my $keys = 50;
	if (index($iniref->{'THEME'},'&')>0) {}		# already includes key=value&
	elsif (not defined $iniref->{'THEME'}) {
		## uses a default theme.
		}
	elsif (index($iniref->{'THEME'},'&')<=0) {
		## legacy
		
      my $REF = &INI::read_ini("/httpd/site/themes/$iniref->{'THEME'}.ini",'',1,1,1,0,0);
		$REF->{'name'} = $iniref->{'THEME'};
      if (not scalar keys %{$REF}) {
         $REF = &INI::read_ini("/httpd/site/themes/default.ini",'',1,1,1,0,0);
			$REF->{'name'} = 'default';
         }
		
		$iniref->{'THEME'} = &ZTOOLKIT::buildparams($REF);
		}

#	my $REF = &ZTOOLKIT::parseparams($iniref->{'THEME'});
#	$keys = scalar(keys %{$REF});
#	print "KEYS: $keys\n";
#
#	next if ($keys > 10);
#
#	my $name = $REF->{'name'};
#	if ($name eq '') { $name = 'default'; }
#	print Dumper($name,$REF,"/httpd/site/themes/$name.ini");
#	$REF = &INI::read_ini("/httpd/site/themes/$name.ini",'',1,1,1,0,0);
#
#	if (scalar(keys %{$REF})<10) {
#		print "Please fix: $REF->{'name'}\n";
#		die();
#		}
#
#	$iniref->{'THEME'} = &ZTOOLKIT::buildparams($REF);
#	print "T: [$iniref->{'THEME'}] [keys; $keys]\n";
#	# die();
#
	open F, ">$DOCID/main.xml";
	print F $t->as_xml();
	close F;

	store $t, "$DOCID/main.bin";

	#print Dumper($hashref);
	#print Dumper($iniref);
	}

&DBINFO::db_zoovy_close();