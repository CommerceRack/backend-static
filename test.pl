#!/usr/bin/perl

use lib "/httpd/modules";
use SITE;

my $t1 = time();
foreach $x (1..10000) {
	SITE::whatis("1.2.3.4","asdf");
	}
my $t2 = time();
print "T: ".($t2-$t1)."\n";

die();
exit;

use lib "/httpd/modules";
use ORDER;

my ($o) = ORDER->new('brian','2006-11-23483');
use Data::Dumper;

use TOXML;
use ZOOVY;

$USERNAME = 'brian';
$PROFILE = 'DEFAULT';
my ($t) = TOXML->new('ORDER','html1',USERNAME=>$USERNAME);
my $nsref = &ZOOVY::fetchmerchantns_ref($USERNAME,$PROFILE);
my ($html) = $t->render( USERNAME=>'brian', nsref=>$nsref, PROFILE=>$PROFILE, ORDER=>$o );

print $html."\n";

# print Dumper($o);


exit;

use lib "/httpd/modules";
use Data::Dumper;
use DOMAIN;

my $d = DOMAIN->new('brian','asdfadsf.com');
print Dumper($d);


$d->sendmail('transfer');