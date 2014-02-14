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

	my $changed=0;
	my $USERNAME = '';
	if ($MID>0) { $USERNAME = &ZOOVY::resolve_merchant_from_mid($MID); }

	print STDERR "MID: $MID [$DOCID]\n";

	my ($t) = TOXML->new('WRAPPER',$DOCID,USERNAME=>$USERNAME,MID=>$MID);
	next if (not defined $t);

	my ($iniref) = $t->findElements('CONFIG');	
	next if (not defined $iniref);

	if (not defined $iniref) {
		die("USER[$USERNAME] DOCID[$DOCID] has no CONFIG element!\n");
		}

	# next if (index($iniref->{'THEME'},'&')>0);

	if (not defined $iniref->{'SITEBUTTONS'}) { $iniref->{'SITEBUTTONS'} = 'default'; } ## use the default buttons
	if ('' eq $iniref->{'SITEBUTTONS'}) { $iniref->{'SITEBUTTONS'} = 'default'; } ## use the default buttons

	if (index($iniref->{'SITEBUTTONS'},'&')>0) {}		# already in key=value& format
	elsif (index($iniref->{'SITEBUTTONS'},'&')<=0) {
		## legacy

		my $file = "/httpd/static/sitebuttons/$iniref->{'SITEBUTTONS'}/info.txt";
		print "FILE: $file\n";
		open F, "<$file";
		$/ = undef; $iniref->{'SITEBUTTONS'} = <F>; $/ = undef;
		close F;
		$changed++;
		}

	next unless ($changed);
	print "Changed: $DOCID\n";
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