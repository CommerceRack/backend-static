#!/usr/bin/perl

use strict;

use lib "/httpd/modules";
use Storable;
use SITE;

# run this on newdev to distribute files
# IMPORTANT: - webservers don't automatically update - they will keep a file in memory for 90 seconds.
# for d in $SERVERS; do echo $d; scp banned.pl $d:/httpd/static/banned.pl; ssh $d "/httpd/static/banned.pl > /dev/null"; done

#
# HOW THIS WORKS:
#	edit the _DATA_ section below, it generates a lookup and exclusion file
#	called /httpd/static/banned.bin which can be pushed.
#
# the following are valid designations:
#		BOT - a crawler, should get no sessions, but not be banned
#		SAFE - we like this person, they get sessions.
#		KILL - they get a 501
#		MISS - they get a 404
#		SCAN - they are allowed to scan, but no search logs.
#
#	IP:1.2.3.4
#	UA:user agent
#	UARE:user agent regular expression
#
#

sub parse_line {
	my ($line) = @_;

	my %KV = ();
	my @nodes = split(/\|/,$line);
	$KV{'ISA'} = shift @nodes;
	if (index($nodes[0],':')<0) {
	    $nodes[0] = "IP:$nodes[0]";
            # print "$nodes[0]\n";
            }
	foreach my $kv (@nodes) {
		my ($matchtype,$matchval) = split(/\:/,$kv,2);
		$KV{$matchtype} = $matchval;	
		if ($matchtype eq 'IP') { 
			$KV{'IF'} = 'IP'; 
			$KV{'#'} = sprintf("%s-%s",$KV{'IF'},$KV{'IP'});
			}
		elsif ($matchtype eq 'UA') { 
			$KV{'IF'} = 'UA'; 
			$KV{'#'} = sprintf("%s-%s",$KV{'IF'},$KV{'UA'});
			}
		}
	$KV{'.'} = $line;

	#if ($line =~ /161\.69\.30\.140/) {
	#	print Dumper(\%KV)."LINE: $line\n";
	#	}

	return(\%KV);
	}



my %DUP = ();
my @LINES = ();

#my ($zdbh) = &DBINFO::db_zoovy_connect();
#my $pstmt = "select ID,IP,SERVER,DOMAIN,STATS,count(*) INFRACTIONS from SITE_THRESHOLD_VIOLATIONS where CREATED_TS>date_sub(now(),interval 24 hour) group by IP having INFRACTIONS>10 order by IP;";
#my $sth = $zdbh->prepare($pstmt);
#$sth->execute();
#while ( my ($ID,$IP,$SERVER,$DOMAIN,$STATS,$COUNT) = $sth->fetchrow() ) {
#	if (not &SITE::whatis($IP)) {
#		my $line = "BOT|$IP|INFRACTIONS:$COUNT ($DOMAIN) $STATS";
#		push @LINES, &parse_line($line);
#		}
#	}
#$sth->finish();
#&DBINFO::db_zoovy_close();

while (<DATA>) {
	chomp($_);

	if (index($_,'#')>=0) { $_ = substr($_,0,index($_,'#')); }
	$_ =~ s/[\s\t]+$//gs;
	# print "LINE: [$_]\n";

	if (($_ eq '') || (substr($_,0,1) eq '#')) {
		# comment
		push @LINES, { '.'=>$_, 'IF'=>'' };
		}
	else {
		push @LINES, parse_line($_);	
		}
	}



#open F, "</dev/shm/banned-more.txt";
#while (<F>) {
#	print "Loading /dev/shm/banned-more.txt";
#	chomp($_);
#	next if ($_ eq '');
#	next if (substr($_,0,1) eq '#');
#	push @LINES, &parse_line($_);
#	}
#close F;

my %SEEN = ();
my %MAP = ();
open Z, ">/tmp/banned.new";
foreach my $line (@LINES) {
	##
	## is_banned - returns
	## 
#	print "LINE: $line->{'#'}\n";

	my $append = 1;
	if ($line->{'IF'} eq '') {
		## comment!
		}
	elsif ($SEEN{ $line->{'#'} } && ($line->{'ISA'} ne 'SAFE')) {
#		if we've seen this, and it's not safe, then that's fine!
#		print "SEEN: $line->{'#'}\n";
		$append = 0;
		}
	elsif ($line->{'IF'} eq 'IP') {
		$SEEN{$line->{'#'}}++;
		my ($oct1,$oct2,$oct3,$oct4) = split(/\./,$line->{'IP'});
		if ($oct4 eq '') { $oct4 = '*'; }

		#if ($line->{'IP'} eq '216.224.247.146') {
		#	print Dumper($line, $MAP{'%IP'}->{$oct1}->{$oct2}->{$oct3}->{$oct4});
		#	}

		## NOTE: the line below will leave BOT even if we're SAFE, which is why %SEEN exists above.
		#if (defined $MAP{'%IP'}->{$oct1}->{$oct2}->{$oct3}->{$oct4}) {
		#	print "IGNORE $line->{'#'}\n";
		#	}
		#else {
			$MAP{'%IP'}->{$oct1}->{$oct2}->{$oct3}->{$oct4} = $line->{'ISA'};
		#	}
		}
	elsif ($line->{'IF'} eq 'UA') {
		push @{$MAP{'@UA'}}, [ $line->{'UA'}, $line->{'ISA'} ];
		}
	else {
		die("Unknown matchtype on line: $_\n");
		}

	if ($append) {
		print Z "$line->{'.'}\n";
		}

	}
close Z;
use Data::Dumper;
#print Dumper(\%MAP);

Storable::nstore \%MAP, '/httpd/static/banned.bin';
print "Wrote: /httpd/static/banned.bin (you should go push it)\n"; 

my @TESTS = ();
push @TESTS, [ '', "66.14.3.25", '' ];
push @TESTS, [ 'KILL', '69.16.180.6', ''];
push @TESTS, [ 'BOT', '', 'i-am-an-unknown-robot'];
push @TESTS, [ 'BOT', '', 'Teoma-Bot'];
push @TESTS, [ 'SAFE', '192.168.2.2', '' ];	# zoovy's ssl ip 
push @TESTS, [ 'SAFE', '208.74.184.1', '' ];	# zoovy's ssl ip 

foreach my $test (@TESTS) {
	my ($designation) = SITE::whatis($test->[1],$test->[2]);
	my ($result) = ($test->[0] eq $designation)?'PASS':'FAIL';
	print join(',',@{$test})." designation[$designation] result[$result]\n";

	if ($test->[0] ne $designation) {
		die("TeST FAILED\n");
		}
	}



# http://www.robotstxt.org/db.html
# http://rotehiet.com/~peter/bsdly.net.traplist
# http://www.botscout.com/
# http://www.botslist.ca/

__DATA__
KILL|209.159.1.158|RESAON: scanner
KILL|203.190.1.158|REASON: scanner
SAFE|99.125.201.118|REASON: beachmart
SAFE|71.199.73.121|REASON: h2oguru
BOT|208.115.113.87|REASON: hitting naboo4
BOT|157.55.33.252|REASON: Binb bot
BOT|157.55.34.168|REASON:
BOT|157.56.92.162|REASON: bing bot
BOT|206.16.59.106|REASON: ConveraCrawler/0.9e
BOT|199.30.20.35|REASON: msnbot-media/1.1
BOT|220.181.108.*|REASON: Baidu
KILL|123.151.43.83|REASON: china telecom hitting www.mrzaccessories.com
SAFE|63.87.61.76|REASON: reefs2go customer 2927072
SAFE|70.166.86.29|REASON: spaparts
SAFE|92.119.181.99|REASON: tatiana
SAFE|173.71.198.45|REASON: Belinda Giger - source-tropical.com / tikimaster
KILL|46.119.224.18|REASON: bad uri parsing (bot)
KILL|173.44.37.226|REASON: log spam gssstore
KILL|173.44.37.242|REASON: log spam gssstore
KILL|173.44.37.250|REASON: log spam gssstore
KILL|96.47.224.42|REASON: log spam gssstore
KILL|96.47.224.50|REASON: log spam gssstore
KILL|96.47.225.170|REASON: log spam gssstore
KILL|96.47.225.178|REASON: log spam gssstore
KILL|96.47.225.186|REASON: log spam gssstore
KILL|96.47.225.66|REASON: log spam gssstore
KILL|96.47.225.74|REASON: log spam gssstore
KILL|96.47.225.82|REASON: log spam gssstore
SAFE|98.175.105.186|REASON: spaparts
BOT|220.255.2.*|REASON: way too many rquests
KILL|92.249.127.111|REASON:referer http://vksaver-besplatno.ru/
KILL|178.137.129.161|REASON:referer http://www.vr-goda.ru/
KILL|91.207.4.186|REASON:referer http://lineage2club.ru/
KILL|178.137.5.8|REASON:referer http://gruzoperevozkipomoscve.ru/
KILL|37.139.52.23|REASON:referer http://pakkula.ru/
KILL|200.137.2.254|REASON:referer http://www.darkcatalog.ru/
KILL|89.108.102.171|REASON:referer http://forex.osobye.ru/
KILL|195.242.218.133|REASON:referer http://gdz-onlain.ru/
KILL|192.162.19.177|REASON:referer http://www.olloclip-fisheye.ru/
KILL|61.157.44.24|REASON:fuck you china telecom
SAFE|99.95.102.40|REASON:pnt
SAFE|207.168.245.47|REASON:greatlookz
SAFE|72.87.193.105|REASON:pnt
SAFE|98.93.9.246|REASON:westkycustoms
KILL|100.43.64.*|REASON:Yandex
KILL|100.43.65.*|REASON:Yandex
KILL|100.43.66.*|REASON:Yandex
KILL|100.43.67.*|REASON:Yandex
KILL|100.43.68.*|REASON:Yandex
KILL|100.43.69.*|REASON:Yandex
KILL|100.43.70.*|REASON:Yandex
KILL|100.43.71.*|REASON:Yandex
KILL|100.43.72.*|REASON:Yandex
KILL|100.43.73.*|REASON:Yandex
KILL|100.43.74.*|REASON:Yandex
KILL|100.43.75.*|REASON:Yandex
KILL|100.43.76.*|REASON:Yandex
KILL|100.43.77.*|REASON:Yandex
KILL|100.43.78.*|REASON:Yandex
KILL|100.43.79.*|REASON:Yandex
KILL|100.43.80.*|REASON:Yandex
KILL|100.43.81.*|REASON:Yandex
KILL|100.43.82.*|REASON:Yandex
KILL|100.43.83.*|REASON:Yandex
KILL|100.43.84.*|REASON:Yandex
KILL|100.43.85.*|REASON:Yandex
KILL|100.43.86.*|REASON:Yandex
KILL|100.43.87.*|REASON:Yandex
KILL|100.43.88.*|REASON:Yandex
KILL|100.43.89.*|REASON:Yandex
KILL|100.43.90.*|REASON:Yandex
KILL|100.43.91.*|REASON:Yandex
KILL|100.43.92.*|REASON:Yandex
KILL|100.43.93.*|REASON:Yandex
KILL|100.43.94.*|REASON:Yandex
KILL|100.43.95.*|REASON:Yandex
KILL|183.60.243.190|REASON:scanning
KILL|82.192.66.19|REASON:Twenga
KILL|82.192.66.20|REASON:Twenga
KILL|82.192.66.21|REASON:Twenga
KILL|82.192.66.22|REASON:Twenga
KILL|82.192.66.23|REASON:Twenga
KILL|82.192.66.24|REASON:Twenga
KILL|82.192.66.25|REASON:Twenga
KILL|82.192.66.26|REASON:Twenga
KILL|82.192.66.27|REASON:Twenga
KILL|82.192.66.28|REASON:Twenga
KILL|82.192.66.29|REASON:Twenga
KILL|82.192.66.30|REASON:Twenga
KILL|82.192.66.31|REASON:Twenga
KILL|82.192.66.32|REASON:Twenga
KILL|82.192.66.33|REASON:Twenga
KILL|82.192.66.34|REASON:Twenga
KILL|82.192.66.35|REASON:Twenga
KILL|82.192.66.36|REASON:Twenga
KILL|82.192.66.37|REASON:Twenga
KILL|82.192.66.38|REASON:Twenga
KILL|82.192.66.39|REASON:Twenga
KILL|82.192.66.40|REASON:Twenga
KILL|82.192.66.41|REASON:Twenga
KILL|82.192.66.42|REASON:Twenga
KILL|82.192.66.43|REASON:Twenga
KILL|82.192.66.44|REASON:Twenga
KILL|82.192.66.45|REASON:Twenga
KILL|82.192.66.46|REASON:Twenga
KILL|82.192.66.47|REASON:Twenga
KILL|82.192.66.48|REASON:Twenga
KILL|82.192.66.49|REASON:Twenga
KILL|82.192.66.50|REASON:Twenga
KILL|82.192.66.51|REASON:Twenga
KILL|82.192.66.52|REASON:Twenga
KILL|82.192.66.53|REASON:Twenga
KILL|82.192.66.54|REASON:Twenga
KILL|82.192.66.55|REASON:Twenga
KILL|82.192.66.56|REASON:Twenga
KILL|82.192.66.57|REASON:Twenga
KILL|82.192.66.58|REASON:Twenga
KILL|82.192.66.59|REASON:Twenga
KILL|82.192.66.60|REASON:Twenga
KILL|82.192.66.61|REASON:Twenga
KILL|82.192.66.62|REASON:Twenga
KILL|82.192.66.63|REASON:Twenga
KILL|82.192.66.64|REASON:Twenga
KILL|82.192.66.65|REASON:Twenga
KILL|82.192.66.66|REASON:Twenga
KILL|82.192.66.67|REASON:Twenga
KILL|82.192.66.68|REASON:Twenga
KILL|82.192.66.69|REASON:Twenga
KILL|82.192.66.70|REASON:Twenga
KILL|82.192.66.71|REASON:Twenga
KILL|82.192.66.72|REASON:Twenga
KILL|82.192.66.73|REASON:Twenga
KILL|82.192.66.74|REASON:Twenga
KILL|82.192.66.75|REASON:Twenga
KILL|82.192.66.76|REASON:Twenga
KILL|82.192.66.77|REASON:Twenga
KILL|82.192.66.78|REASON:Twenga
KILL|82.192.66.79|REASON:Twenga
KILL|82.192.66.80|REASON:Twenga
KILL|82.192.66.81|REASON:Twenga
KILL|82.192.66.82|REASON:Twenga
KILL|82.192.66.83|REASON:Twenga
KILL|82.192.66.84|REASON:Twenga
KILL|82.192.66.85|REASON:Twenga
KILL|82.192.66.86|REASON:Twenga
KILL|82.192.66.87|REASON:Twenga
KILL|82.192.66.88|REASON:Twenga
KILL|82.192.66.89|REASON:Twenga
KILL|82.192.66.90|REASON:Twenga
KILL|82.192.66.91|REASON:Twenga
KILL|82.192.66.92|REASON:Twenga
KILL|82.192.66.93|REASON:Twenga
KILL|82.192.66.94|REASON:Twenga
KILL|82.192.66.95|REASON:Twenga
KILL|82.192.66.96|REASON:Twenga
KILL|82.192.66.97|REASON:Twenga
KILL|82.192.66.98|REASON:Twenga
KILL|82.192.66.99|REASON:Twenga
KILL|82.192.66.100|REASON:Twenga
KILL|82.192.66.101|REASON:Twenga
KILL|82.192.66.102|REASON:Twenga
KILL|82.192.66.103|REASON:Twenga
KILL|82.192.66.104|REASON:Twenga
KILL|82.192.66.105|REASON:Twenga
KILL|82.192.66.106|REASON:Twenga
KILL|82.192.66.107|REASON:Twenga
KILL|82.192.66.108|REASON:Twenga
KILL|82.192.66.109|REASON:Twenga
KILL|82.192.66.110|REASON:Twenga
KILL|82.192.66.111|REASON:Twenga
KILL|82.192.66.112|REASON:Twenga
KILL|82.192.66.113|REASON:Twenga
KILL|82.192.66.114|REASON:Twenga
KILL|82.192.66.115|REASON:Twenga
KILL|82.192.66.116|REASON:Twenga
KILL|82.192.66.117|REASON:Twenga
KILL|82.192.66.118|REASON:Twenga
KILL|82.192.66.119|REASON:Twenga
KILL|82.192.66.120|REASON:Twenga
KILL|82.192.66.121|REASON:Twenga
KILL|82.192.66.122|REASON:Twenga
KILL|82.192.66.123|REASON:Twenga
KILL|82.192.66.124|REASON:Twenga
KILL|82.192.66.125|REASON:Twenga
KILL|82.192.66.126|REASON:Twenga
KILL|82.192.66.127|REASON:Twenga
KILL|82.192.66.128|REASON:Twenga
KILL|82.192.66.129|REASON:Twenga
KILL|82.192.66.130|REASON:Twenga
KILL|82.192.66.131|REASON:Twenga
KILL|82.192.66.132|REASON:Twenga
KILL|82.192.66.133|REASON:Twenga
KILL|82.192.66.134|REASON:Twenga
KILL|82.192.66.135|REASON:Twenga
KILL|82.192.66.136|REASON:Twenga
KILL|82.192.66.137|REASON:Twenga
KILL|82.192.66.138|REASON:Twenga
KILL|82.192.66.139|REASON:Twenga
KILL|82.192.66.140|REASON:Twenga
KILL|82.192.66.141|REASON:Twenga
KILL|82.192.66.142|REASON:Twenga
KILL|82.192.66.143|REASON:Twenga
KILL|82.192.66.144|REASON:Twenga
KILL|82.192.66.145|REASON:Twenga
KILL|82.192.66.146|REASON:Twenga
KILL|82.192.66.147|REASON:Twenga
KILL|82.192.66.148|REASON:Twenga
KILL|82.192.66.149|REASON:Twenga
KILL|82.192.66.150|REASON:Twenga
KILL|82.192.66.151|REASON:Twenga
KILL|82.192.66.152|REASON:Twenga
KILL|82.192.66.153|REASON:Twenga
KILL|82.192.66.154|REASON:Twenga
KILL|82.192.66.155|REASON:Twenga
KILL|82.192.66.156|REASON:Twenga
KILL|82.192.66.157|REASON:Twenga
KILL|82.192.66.158|REASON:Twenga
KILL|82.192.66.159|REASON:Twenga
KILL|82.192.66.160|REASON:Twenga
KILL|82.192.66.161|REASON:Twenga
KILL|82.192.66.162|REASON:Twenga
KILL|82.192.66.163|REASON:Twenga
KILL|82.192.66.164|REASON:Twenga
KILL|82.192.66.165|REASON:Twenga
KILL|82.192.66.166|REASON:Twenga
KILL|82.192.66.167|REASON:Twenga
KILL|82.192.66.168|REASON:Twenga
KILL|82.192.66.169|REASON:Twenga
KILL|82.192.66.170|REASON:Twenga
KILL|82.192.66.171|REASON:Twenga
KILL|82.192.66.172|REASON:Twenga
KILL|82.192.66.173|REASON:Twenga
KILL|82.192.66.174|REASON:Twenga
KILL|82.192.66.175|REASON:Twenga
KILL|82.192.66.176|REASON:Twenga
KILL|82.192.66.177|REASON:Twenga
KILL|82.192.66.178|REASON:Twenga
KILL|82.192.66.179|REASON:Twenga
KILL|82.192.66.180|REASON:Twenga
KILL|82.192.66.181|REASON:Twenga
KILL|82.192.66.182|REASON:Twenga
KILL|82.192.66.183|REASON:Twenga
KILL|82.192.66.184|REASON:Twenga
KILL|82.192.66.185|REASON:Twenga
KILL|82.192.66.186|REASON:Twenga
KILL|82.192.66.187|REASON:Twenga
KILL|82.192.66.188|REASON:Twenga
KILL|82.192.66.189|REASON:Twenga
KILL|82.192.66.190|REASON:Twenga
KILL|82.192.66.191|REASON:Twenga
KILL|82.192.66.192|REASON:Twenga
KILL|82.192.66.193|REASON:Twenga
KILL|82.192.66.194|REASON:Twenga
KILL|82.192.66.195|REASON:Twenga
KILL|82.192.66.196|REASON:Twenga
KILL|82.192.66.197|REASON:Twenga
KILL|82.192.66.198|REASON:Twenga
KILL|82.192.66.199|REASON:Twenga
KILL|82.192.66.200|REASON:Twenga
KILL|82.192.66.201|REASON:Twenga
KILL|82.192.66.202|REASON:Twenga
KILL|82.192.66.203|REASON:Twenga
KILL|82.192.66.204|REASON:Twenga
KILL|82.192.66.205|REASON:Twenga
KILL|82.192.66.206|REASON:Twenga
KILL|82.192.66.207|REASON:Twenga
KILL|82.192.66.208|REASON:Twenga
KILL|82.192.66.209|REASON:Twenga
KILL|82.192.66.210|REASON:Twenga
KILL|82.192.66.211|REASON:Twenga
KILL|82.192.66.212|REASON:Twenga
KILL|82.192.66.213|REASON:Twenga
KILL|82.192.66.214|REASON:Twenga
KILL|82.192.66.215|REASON:Twenga
KILL|82.192.66.216|REASON:Twenga
KILL|82.192.66.217|REASON:Twenga
KILL|82.192.66.218|REASON:Twenga
KILL|82.192.66.219|REASON:Twenga
KILL|82.192.66.220|REASON:Twenga
KILL|82.192.66.221|REASON:Twenga
KILL|82.192.66.222|REASON:Twenga
KILL|82.192.66.223|REASON:Twenga
KILL|82.192.66.224|REASON:Twenga
KILL|82.192.66.225|REASON:Twenga
KILL|82.192.66.226|REASON:Twenga
KILL|82.192.66.227|REASON:Twenga
KILL|82.192.66.228|REASON:Twenga
KILL|82.192.66.229|REASON:Twenga
KILL|82.192.66.230|REASON:Twenga
KILL|82.192.66.231|REASON:Twenga
KILL|82.192.66.232|REASON:Twenga
KILL|82.192.66.233|REASON:Twenga
KILL|82.192.66.234|REASON:Twenga
KILL|82.192.66.235|REASON:Twenga
KILL|82.192.66.236|REASON:Twenga
KILL|82.192.66.237|REASON:Twenga
KILL|82.192.66.238|REASON:Twenga
KILL|82.192.66.239|REASON:Twenga
KILL|82.192.66.240|REASON:Twenga
KILL|82.192.66.241|REASON:Twenga
KILL|82.192.66.242|REASON:Twenga
KILL|82.192.66.243|REASON:Twenga
KILL|82.192.66.244|REASON:Twenga
KILL|82.192.66.245|REASON:Twenga
KILL|82.192.66.246|REASON:Twenga
KILL|82.192.66.247|REASON:Twenga
KILL|82.192.66.248|REASON:Twenga
KILL|82.192.66.249|REASON:Twenga
KILL|82.192.66.250|REASON:Twenga
KILL|82.192.66.251|REASON:Twenga
KILL|82.192.66.252|REASON:Twenga
KILL|82.192.66.253|REASON:Twenga
KILL|82.192.66.254|REASON:Twenga
KILL|82.192.66.255|REASON:Twenga
KILL|174.199.64.*|REASON:Choopa net AhrefsBot
KILL|174.199.65.*|REASON:Choopa net AhrefsBot
KILL|174.199.66.*|REASON:Choopa net AhrefsBot
KILL|174.199.67.*|REASON:Choopa net AhrefsBot
KILL|174.199.68.*|REASON:Choopa net AhrefsBot
KILL|174.199.69.*|REASON:Choopa net AhrefsBot
KILL|174.199.70.*|REASON:Choopa net AhrefsBot
KILL|174.199.71.*|REASON:Choopa net AhrefsBot
KILL|174.199.72.*|REASON:Choopa net AhrefsBot
KILL|174.199.73.*|REASON:Choopa net AhrefsBot
KILL|174.199.74.*|REASON:Choopa net AhrefsBot
KILL|174.199.75.*|REASON:Choopa net AhrefsBot
KILL|174.199.76.*|REASON:Choopa net AhrefsBot
KILL|174.199.77.*|REASON:Choopa net AhrefsBot
KILL|174.199.78.*|REASON:Choopa net AhrefsBot
KILL|174.199.79.*|REASON:Choopa net AhrefsBot
KILL|174.199.80.*|REASON:Choopa net AhrefsBot
KILL|174.199.81.*|REASON:Choopa net AhrefsBot
KILL|174.199.82.*|REASON:Choopa net AhrefsBot
KILL|174.199.83.*|REASON:Choopa net AhrefsBot
KILL|174.199.84.*|REASON:Choopa net AhrefsBot
KILL|174.199.85.*|REASON:Choopa net AhrefsBot
KILL|174.199.86.*|REASON:Choopa net AhrefsBot
KILL|174.199.87.*|REASON:Choopa net AhrefsBot
KILL|174.199.88.*|REASON:Choopa net AhrefsBot
KILL|174.199.89.*|REASON:Choopa net AhrefsBot
KILL|174.199.90.*|REASON:Choopa net AhrefsBot
KILL|174.199.91.*|REASON:Choopa net AhrefsBot
KILL|174.199.92.*|REASON:Choopa net AhrefsBot
KILL|174.199.93.*|REASON:Choopa net AhrefsBot
KILL|174.199.94.*|REASON:Choopa net AhrefsBot
KILL|174.199.95.*|REASON:Choopa net AhrefsBot
KILL|174.199.96.*|REASON:Choopa net AhrefsBot
KILL|174.199.97.*|REASON:Choopa net AhrefsBot
KILL|174.199.98.*|REASON:Choopa net AhrefsBot
KILL|174.199.99.*|REASON:Choopa net AhrefsBot
KILL|174.199.100.*|REASON:Choopa net AhrefsBot
KILL|174.199.101.*|REASON:Choopa net AhrefsBot
KILL|174.199.102.*|REASON:Choopa net AhrefsBot
KILL|174.199.103.*|REASON:Choopa net AhrefsBot
KILL|174.199.104.*|REASON:Choopa net AhrefsBot
KILL|174.199.105.*|REASON:Choopa net AhrefsBot
KILL|174.199.106.*|REASON:Choopa net AhrefsBot
KILL|174.199.107.*|REASON:Choopa net AhrefsBot
KILL|174.199.108.*|REASON:Choopa net AhrefsBot
KILL|174.199.109.*|REASON:Choopa net AhrefsBot
KILL|174.199.110.*|REASON:Choopa net AhrefsBot
KILL|174.199.111.*|REASON:Choopa net AhrefsBot
KILL|174.199.112.*|REASON:Choopa net AhrefsBot
KILL|174.199.113.*|REASON:Choopa net AhrefsBot
KILL|174.199.114.*|REASON:Choopa net AhrefsBot
KILL|174.199.115.*|REASON:Choopa net AhrefsBot
KILL|174.199.116.*|REASON:Choopa net AhrefsBot
KILL|174.199.117.*|REASON:Choopa net AhrefsBot
KILL|174.199.118.*|REASON:Choopa net AhrefsBot
KILL|174.199.119.*|REASON:Choopa net AhrefsBot
KILL|174.199.120.*|REASON:Choopa net AhrefsBot
KILL|174.199.121.*|REASON:Choopa net AhrefsBot
KILL|174.199.122.*|REASON:Choopa net AhrefsBot
KILL|174.199.123.*|REASON:Choopa net AhrefsBot
KILL|174.199.124.*|REASON:Choopa net AhrefsBot
KILL|174.199.125.*|REASON:Choopa net AhrefsBot
KILL|174.199.126.*|REASON:Choopa net AhrefsBot
KILL|174.199.127.*|REASON:Choopa net AhrefsBot
KILL|91.201.64.*|REASON: Donekoserv
KILL|91.201.65.*|REASON: Donekoserv
KILL|91.201.66.*|REASON: Donekoserv
KILL|91.201.67.*|REASON: Donekoserv


SAFE|98.175.109.176|REASON:spaparts
SAFE|24.234.224.124|REASON:lasvegasfurniture
SAFE|184.89.82.77|REASON:moetown55
SAFE|65.78.156.161|REASON:designed2bsweet employee
SAFE|65.78.156.154|REASON:designed2bsweet employee
SAFE|25.78.134.159|REASON:beachmart
KILL|95.168.172.156|REASON:aborts
KILL|89.108.102.171|REASON:aborts

KILL|213.186.119.*|REASON:high request rate
KILL|182.118.25.*|REASON:high request rate
BOT|208.83.156.*|REASON:thefind
BOT|23.20.27.*|REASON:amazon cloud
BOT|192.114.71.13|

KILL|182.118.20.*|DATE:20121010|REASON:abusive (confirmed) botnet
KILL|182.118.21.*|DATE:20121010|REASON:abusive (confirmed) botnet
KILL|182.118.22.*|DATE:20121010|REASON:abusive (confirmed) botnet
KILL|182.118.23.*|DATE:20121010|REASON:abusive (confirmed) botnet
KILL|182.118.24.*|DATE:20121010|REASON:abusive (confirmed) botnet
KILL|182.118.25.*|DATE:20121010|REASON:abusive (confirmed) botnet

SCAN|165.193.42.85|DATE:20120809|REASON:hits=3163 sec=810 type=
BOT|95.108.150.235|DATE:20120809|REASON:hits=1420 sec=3837 type=
#SCAN|74.111.33.106|DATE:20120809|REASON:hits=714 sec=546 type=
#SCAN|65.49.71.101|DATE:20120809|REASON:hits=668 sec=3360 type=
BOT|66.249.68.36|DATE:20120809|REASON:hits=357 sec=225 type=WATCH
KILL|213.186.120.196|DATE:20120809|REASON:hits=306 sec=4848 type=KILL
KILL|213.186.122.2|DATE:20120809|REASON:hits=290 sec=4622 type=
KILL|213.186.122.3|DATE:20120809|REASON:hits=275 sec=3051 type=

SAFE|50.193.107.149|REASON:toynk office
SAFE|50.20.144.10|REASON:cubworlds seo company
SAFE|74.111.188.69|REASON:cypherstyles barry
SAFE|75.174.216.147|REASON:homebrewers scott
SAFE|108.178.100.155|REASON:beautystore mike
SAFE|204.9.109.242|REASON:mulishagear luke
SAFE|67.184.151.113|REASON:cdphonehome


KILL|173.44.37.250
BOT|173.236.21.106
KILL|115.79.234.173|abusive to beautystoredepot (lifetime ban)

## I don't trust twengabot 
KILL|108.59.0.*|REASON:TwengaBot

KILL|178.16.217.114
BOT|100.43.83.158|REASON:571 hits
## GOOGLE
BOT|66.249.67.*|GOOGLE
BOT|66.249.67.11|GOOGLE
BOT|66.249.67.133|GOOGLE
BOT|66.249.67.58|GOOGLE
BOT|66.249.68.168|GOOGLE
BOT|66.249.68.5|GOOGLE
BOT|85.17.73.171|REASON:3630 hits

## site downloading tools
#facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)
BOT-POSITIVE|UA:facebookexternalhit
KILL|UA:baidu
KILL|UA:spotbot
KILL|UA:80legs
KILL|UA:Scooter
KILL|UA:WebStripper
KILL|UA:AhrefsBot
KILL|UA:Ahrefs
KILL|UA:008
## If we think a client is a bot, we just don't write cart ID's into the URL.
## Everything should still work if the user has cookies enabled and the
## user agent was accidentally recognized as a bot

# useragent: Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; GTB5; SearchToolbar 1.1)
SAFE|UA:SearchToolbar

## regular robots
BOT|UA:archiver
BOT|UA:archiving
BOT|UA:bordermanager
BOT|UA:bumblebee
BOT|UA:copier
BOT|UA:crawl
BOT|UA:creep
BOT|UA:diagem
BOT|UA:dia-test
BOT|UA:engine
BOT|UA:fetch api
BOT|UA:ia_archiver	# alexa
##
## NOTE: 12/8/2007 - this was "google" - however Gaurav computer used an internal
##						corporate build of Firefox which had 
##						mozilla/5.0 (macintosh; u; intel mac os x; en-us; rv:1.8.1.6) gecko/20070725 (ck-googlecorp) firefox/2.0.0.6
##
BOT-POSITIVE|UA:Baiduspider
BOT-POSITIVE|UA:google-bot
BOT-POSITIVE|UA:googlebot
BOT-POSITIVE|UA:Mediapartners
BOT-POSITIVE|UA:AdsBot
BOT-POSITIVE|UA:bingbot
BOT|UA:grub-client
BOT|UA:harvest
BOT|UA:incy
BOT|UA:infoseek
BOT|UA:internetseer
BOT|UA:java1.3
BOT|UA:jeeves
BOT|UA:larbin
BOT|UA:library
BOT|UA:libwww
BOT|UA:mercator
BOT|UA:mozdex
BOT|UA:msnbot
BOT|UA:nutch
BOT|UA:pompos
BOT|UA:reaper
BOT|UA:scooter
BOT|UA:scout
BOT|UA:scrubby
SAFE|UA:trident
SAFE|UA:searchtoolbar
BOT|UA:search
BOT|UA:sitecheck
BOT|UA:sleuth
BOT|UA:slurp
BOT|UA:spider
BOT|UA:survey
BOT|UA:sygol
BOT|UA:thunderstone
BOT|UA:t-h-u-n-d-e-r-s-t-o-n-e
BOT|UA:teoma
BOT|UA:urllib
BOT|UA:vagabondo
BOT|UA:walker
BOT|UA:webcraft
BOT|UA:webstripper
BOT|UA:wisenut
BOT|UA:worm
BOT|UA:zyborg
BOT|UA:thefind
SCAN|UA:scanalert
BOT|UA:crawler
BOT|UA:TwengaBot

SAFE|IP:192.168.2.2	# zoovy ssl server
SAFE|IP:192.168.2.	# zoovy internal ip address block
SAFE|IP:208.74.184.	# zoovy ip block


BOT|1.202.218.*|INFRACTIONS:119 (2bhiptshirts.com) /robots.txt
BOT|1.202.219.*|INFRACTIONS:24 (www.ibuynapoleonfireplaces.com) /robots.txt
BOT|100.43.83.136|INFRACTIONS:351|REASON: Yandex
BOT|108.59.8.70|INFRACTIONS:127|REASON: Twenga
BOT|108.59.8.80|INFRACTIONS:83|REASON: Twenga
BOT|109.87.138.55|INFRACTIONS:47 (www.shop.volvocincinnati.com) /robots.txt
BOT|114.32.109.44|INFRACTIONS:16 (m.kyledesigns.com) /robots.txt
BOT|118.239.68.84|INFRACTIONS:35 (www.boomerangfishing.com) i30:11 i120:11 [BOT I30:11]
BOT|119.139.27.160|INFRACTIONS:27 (www.tting.com) /robots.txt
BOT|119.63.196.110|INFRACTIONS:12 (www.clicktoshopllc.com) /robots.txt
BOT|124.115.4.209|INFRACTIONS:107 (www.2bhipshops.com) /sitemap.xml
BOT|124.115.4.210|INFRACTIONS:124 (m.stateofnine.com) /sitemap.xml
BOT|124.115.6.10|INFRACTIONS:272 (www.instrumentsofinspiration.net) /robots.txt
BOT|124.115.6.11|INFRACTIONS:117 (allpetsolutions.com) /robots.txt
BOT|124.115.6.13|INFRACTIONS:100 (www.greatscarves.com) /robots.txt
BOT|124.115.6.14|INFRACTIONS:108 (www.alloceansports.com) /robots.txt
BOT|124.115.6.15|INFRACTIONS:126 (www.wrigleyfieldsport.com) /robots.txt
BOT|124.115.6.16|INFRACTIONS:110 (www.ibuymaximlighting.com) /robots.txt
BOT|124.115.6.17|INFRACTIONS:122 (jimsbigstore.com) /robots.txt
BOT|128.238.153.10|INFRACTIONS:31 (www.hayspear.com) /robots.txt
BOT|128.238.153.11|INFRACTIONS:23 (www.cdphonehome.com) /robots.txt
BOT|128.238.153.12|INFRACTIONS:25 (www.stage3motorsports.com) /robots.txt
BOT|128.238.153.13|INFRACTIONS:26 (www.allcosmeticswholesale.com) /robots.txt
BOT|128.238.153.14|INFRACTIONS:23 (www.thespotlowrider.com) /robots.txt
BOT|128.238.153.15|INFRACTIONS:25 (www.replaceyourcell.com) /robots.txt
BOT|128.238.153.16|INFRACTIONS:20 (www.summitfashions.com) /robots.txt
BOT|128.238.153.18|INFRACTIONS:20 (www.tikioutlet.com) /robots.txt
BOT|128.238.153.30|INFRACTIONS:30 (www.thechessstore.com) /robots.txt
BOT|128.238.153.5|INFRACTIONS:24 (www.bigbadpowersports.com) /robots.txt
BOT|128.238.153.6|INFRACTIONS:26 (www.silver-seal.com) /robots.txt
BOT|128.238.153.7|INFRACTIONS:18 (www.rainbowcustomcars.com) /robots.txt
BOT|128.238.153.8|INFRACTIONS:21 (www.speedaddictcycles.com) /robots.txt
BOT|128.238.153.9|INFRACTIONS:11 (www.bedplanet.com) /robots.txt
BOT|131.253.27.125|INFRACTIONS:25 (www.highpointscientific.com) /robots.txt
BOT|131.253.38.20|INFRACTIONS:12 (www.caliperpaints.com) /robots.txt
BOT|131.253.40.45|INFRACTIONS:13 (inflatablessuperstore.com) /robots.txt
BOT|149.154.158.142|INFRACTIONS:77 (www.bigbusybeeart.com) /robots.txt
BOT|157.55.116.*|REASON:BING
BOT|157.55.32.*|REASON:BING
BOT|157.55.33.*|REASON:BING
BOT|157.55.34.*|REASON:BING
BOT|157.55.35.*|REASON:BING
BOT|157.55.36.*|REASON:BING
BOT|157.56.229.*|REASON:BING
BOT|157.56.92.*|REASON:BING
BOT|157.56.93.*|REASON:BING
BOT|157.56.94.*|REASON:BING
BOT|157.56.95.*|REASON:BING
BOT|173.199.114.*|INFRACTIONS:16 (2bhiptshirts.com) /robots.txt
BOT|173.199.115.*|INFRACTIONS:13 (www.cellphonebeast.com) /robots.txt
BOT|173.199.116.*|INFRACTIONS:15 (smyrnacoin.com) /robots.txt
BOT|173.199.116.*|INFRACTIONS:24 (stateofnine.com) /robots.txt
BOT|173.199.117.*|INFRACTIONS:233 (www.affordableproducts.zoovy.com) /robots.txt
BOT|178.255.215.*|INFRACTIONS:40 (www.favorsngifts.com) /robots.txt
BOT|180.76.5.*|INFRACTIONS:28 (instantcoldcompress.com) /robots.txt
BOT|180.76.6.*|INFRACTIONS:16 (www.apartmentslehighvalley.net) /robots.txt
BOT|207.46.199.*|INFRACTIONS:67 (www.rpm-cycle.com) /robots.txt
BOT|208.115.111.*|INFRACTIONS:310 (www.hawaii360.biz) /robots.txt
BOT|208.115.113.*|INFRACTIONS:327 (www.acworldtoys.com) /robots.txt
BOT|208.83.156.*|INFRACTIONS:362 (www.em190.com) /robots.txt
BOT|217.212.224.183|INFRACTIONS:148 (www.spapartsdepot.com) /robots.txt
BOT|217.69.133.*|INFRACTIONS:70 (www.nyciwear.com) /robots.txt
BOT|218.30.103.*|INFRACTIONS:14 (www.needtobreathestore.com) /robots.txt
BOT|220.181.89.*|INFRACTIONS:14 (costumesltd.com) /robots.txt
BOT|46.165.197.*|INFRACTIONS:174 (www.2bhipbuckles.com) /robots.txt
BOT|62.212.73.211|INFRACTIONS:158 (www.ticohomedecor.com) /robots.txt
BOT|62.24.181.134|INFRACTIONS:53 (www.wlanparts.com) /robots.txt
BOT|62.24.181.135|INFRACTIONS:48 (www.guitarelectronics.com) /robots.txt
BOT|62.24.222.131|INFRACTIONS:24 (www.tattooapparel.com) /robots.txt
BOT|62.24.222.132|INFRACTIONS:11 (www.cypherstyles.com) /robots.txt
BOT|62.24.252.133|INFRACTIONS:44 (www.beachmall.com) /robots.txt
BOT|62.31.187.155|INFRACTIONS:64 (www.teramasu.com) /robots.txt
BOT|64.125.222.16|INFRACTIONS:24 (www.cellphoneslord.com) /robots.txt
BOT|64.125.222.50|INFRACTIONS:20 (www.tikimaster.com) /robots.txt
BOT|64.246.161.190|INFRACTIONS:17 (www.givemethegame.com) /robots.txt
BOT|64.246.161.30|INFRACTIONS:18 (www.garagestyle.com) /robots.txt
BOT|64.246.161.42|INFRACTIONS:17 (www.guns-paintball.com) /robots.txt
BOT|64.246.165.10|INFRACTIONS:21 (www.ggood.com) /robots.txt
BOT|64.246.165.140|INFRACTIONS:23 (www.getlostgps.net) /robots.txt
BOT|64.246.165.150|INFRACTIONS:12 (www.gogoods.info) /robots.txt
BOT|64.246.165.160|INFRACTIONS:14 (www.girlsbirthdayparty.net) /robots.txt
BOT|64.246.165.170|INFRACTIONS:21 (www.gifts-for-fun.com) /robots.txt
BOT|64.246.165.180|INFRACTIONS:19 (www.geoorganicseed.com) /robots.txt
BOT|64.246.165.190|INFRACTIONS:26 (www.glaciercountrytoolworks.com) /robots.txt
BOT|64.246.165.200|INFRACTIONS:25 (www.ghostlakegroup.com) /robots.txt
BOT|64.246.165.210|INFRACTIONS:22 (www.geoshoponline.com) /robots.txt
BOT|64.246.165.50|INFRACTIONS:25 (www.ghostinc.com) /robots.txt
BOT|64.246.178.34|INFRACTIONS:25 (www.glamour-grams.com) /robots.txt
BOT|64.246.187.42|INFRACTIONS:22 (www.globalbrandmall.com) /robots.txt
BOT|64.56.64.136|INFRACTIONS:75 (www.jimsbigstore.com) /robots.txt

## STOPPED HERE
BOT|65.49.71.101|INFRACTIONS:21599 (www.victorianheartquilts4less.com) /robots.txt
BOT|65.49.71.137|INFRACTIONS:7378 (www.speedygoods.com) /robots.txt
BOT|65.52.109.114|INFRACTIONS:12 (inflatablessuperstore.com) /robots.txt
BOT|65.55.211.164|INFRACTIONS:12 (inflatablessuperstore.com) /robots.txt
BOT|65.55.211.172|INFRACTIONS:12 (www.caliperpaints.com) /robots.txt
BOT|65.55.211.175|INFRACTIONS:12 (www.caliperpaints.com) /robots.txt
BOT|65.55.211.180|INFRACTIONS:12 (www.caliperpaints.com) /robots.txt
BOT|65.55.24.214|INFRACTIONS:44 (mopartrim.com) /robots.txt
BOT|65.55.24.215|INFRACTIONS:87 (www.jetflowauger.com) /robots.txt
BOT|65.55.24.216|INFRACTIONS:58 (www.tikioutlet.com) /robots.txt
BOT|65.55.24.220|INFRACTIONS:41 (www.ejejllc.com) /robots.txt
BOT|65.55.24.221|INFRACTIONS:66 (www.americanguitarboutique.com) /robots.txt
BOT|65.55.24.233|INFRACTIONS:50 (www.artprintandposter.com) /robots.txt
BOT|65.55.24.236|INFRACTIONS:76 (www.drapesunlimited.com) /robots.txt
BOT|65.55.24.237|INFRACTIONS:48 (www.custompotrack.com) /robots.txt
BOT|65.55.24.239|INFRACTIONS:68 (www.tallzag.com) /robots.txt
BOT|65.55.24.243|INFRACTIONS:53 (www.spitsadventurewear.com) /robots.txt
BOT|65.55.24.244|INFRACTIONS:59 (www.theotherworlds.com) /robots.txt
BOT|65.55.24.245|INFRACTIONS:61 (www.shop.porscheofthevillage.com) /robots.txt
BOT|65.55.52.111|INFRACTIONS:87 (www.oktoberfestwholesale.com) /robots.txt
BOT|65.55.52.113|INFRACTIONS:45 (www.frogpondaquatics.com) /robots.txt
BOT|65.55.52.115|INFRACTIONS:195 (www.dcitti.zoovy.com) /robots.txt
BOT|65.55.52.116|INFRACTIONS:76 (inflatablessuperstore.com) /robots.txt
BOT|65.55.52.117|INFRACTIONS:43 (www.2bhipbabies.com) /robots.txt
BOT|65.55.52.119|INFRACTIONS:57 (www.rebornartistsupplies.com) /robots.txt
BOT|65.55.52.86|INFRACTIONS:39 (www.beachboysstore.com) /robots.txt
BOT|65.55.52.87|INFRACTIONS:58 (www.chitownfootball.com) /robots.txt
BOT|65.55.52.92|INFRACTIONS:42 (www.shop.beechmontaudi.com) /robots.txt
BOT|65.55.52.94|INFRACTIONS:71 (www.2bhipbabies.com) /robots.txt
BOT|65.55.52.95|INFRACTIONS:63 (www.rockytoptactical.com) /robots.txt
BOT|65.55.52.96|INFRACTIONS:97 (www.shop4toyz.com) /robots.txt
BOT|65.55.52.97|INFRACTIONS:35 (www.yesadeal.com) /robots.txt
BOT|65.55.55.230|INFRACTIONS:67 (www.mymoonandstar.com) /robots.txt
BOT|65.55.55.231|INFRACTIONS:34 (www.garagestyle.com) /robots.txt
#BOT|65.78.156.154|INFRACTIONS:20 (www.designed2bsweet.com) i30:11 i120:12 [BOT I30:11]
BOT|66.112.55.170|INFRACTIONS:13 (replaceyourcell.com) /robots.txt
BOT|66.249.73.*|INFRACTIONS:16 (www.ibuystatuarys.com) /robots.txt
BOT|66.249.73.1|INFRACTIONS:16 (www.ibuystatuarys.com) /robots.txt
BOT|66.249.73.10|INFRACTIONS:23 (kyledesign.zoovy.com) /robots.txt
BOT|66.249.73.101|INFRACTIONS:15 (www.rayscustomtackle.com) /robots.txt
BOT|66.249.73.102|INFRACTIONS:22 (www.rollonbracelets.com) /robots.txt
BOT|66.249.73.103|INFRACTIONS:12 (www.bigoutlet.com) /robots.txt
BOT|66.249.73.104|INFRACTIONS:19 (m.zephyrpaintball.com) /sitemap.xml
BOT|66.249.73.105|INFRACTIONS:14 (www.smartpartspaintballonline.com) /robots.txt
BOT|66.249.73.106|INFRACTIONS:12 (m.hillbillyknifesales.com) /sitemap.xml
BOT|66.249.73.107|INFRACTIONS:12 (www.themountainteeshirt.com) /robots.txt
BOT|66.249.73.108|INFRACTIONS:29 (theofficialmemorabilias.com) /robots.txt
BOT|66.249.73.109|INFRACTIONS:21 (www.oktoberfesthaus.com) /robots.txt
BOT|66.249.73.110|INFRACTIONS:27 (www.performancepda.zoovy.com) /robots.txt
BOT|66.249.73.111|INFRACTIONS:28 (www.instantcoldcompresses.com) /robots.txt
BOT|66.249.73.112|INFRACTIONS:27 (www.homermenandboys.zoovy.com) /robots.txt
BOT|66.249.73.113|INFRACTIONS:23 (www.socoffee.com) /robots.txt
BOT|66.249.73.114|INFRACTIONS:22 (www.autrysports.zoovy.com) /robots.txt
BOT|66.249.73.115|INFRACTIONS:31 (www.thedrillow.com) /robots.txt
BOT|66.249.73.116|INFRACTIONS:18 (www.greatsockz.com) /robots.txt
BOT|66.249.73.117|INFRACTIONS:25 (www.savilearning.theperformancereportwebstore.com) /robots.txt
BOT|66.249.73.118|INFRACTIONS:14 (pinnaclemailbox.com) /robots.txt
BOT|66.249.73.119|INFRACTIONS:33 (www.buildbikes.net) /robots.txt
BOT|66.249.73.12|INFRACTIONS:24 (www.bbkingstore.com) /robots.txt
BOT|66.249.73.120|INFRACTIONS:14 (www.ibuywoodstoves.com) /robots.txt
BOT|66.249.73.121|INFRACTIONS:12 (m.amigaz.com) /sitemap.xml
BOT|66.249.73.122|INFRACTIONS:28 (tatianabras.com) /robots.txt
BOT|66.249.73.123|INFRACTIONS:24 (www.elegantaudio.zoovy.com) /robots.txt
BOT|66.249.73.124|INFRACTIONS:26 (www.foreverflorals.com) /robots.txt
BOT|66.249.73.129|INFRACTIONS:13 (www.birthdayideasstore.com) /robots.txt
BOT|66.249.73.13|INFRACTIONS:32 (sassyassyjeans.net) /robots.txt
BOT|66.249.73.130|INFRACTIONS:18 (www.crite2000.zoovy.com) /robots.txt
BOT|66.249.73.131|INFRACTIONS:26 (www.studiohut.com) /robots.txt
BOT|66.249.73.132|INFRACTIONS:28 (www.sportsworldchicago.net) /robots.txt
BOT|66.249.73.133|INFRACTIONS:21 (www.kyledesign.zoovy.com) /robots.txt
BOT|66.249.73.134|INFRACTIONS:25 (m.usavem.com) /sitemap.xml
BOT|66.249.73.135|INFRACTIONS:30 (stateofnine.com) /robots.txt
BOT|66.249.73.136|INFRACTIONS:26 (www.areadevelopmentcorp.com) /robots.txt
BOT|66.249.73.137|INFRACTIONS:20 (partybrights.com) /robots.txt
BOT|66.249.73.139|INFRACTIONS:14 (www.thetoosidedpurseco.com) /robots.txt
BOT|66.249.73.14|INFRACTIONS:24 (www.ibuypondkits.com) /robots.txt
BOT|66.249.73.140|INFRACTIONS:27 (www.zephyrsunglasses.com) /sitemap.xml
BOT|66.249.73.141|INFRACTIONS:32 (www.aaavacuumcleaners.net) /sitemap.xml
BOT|66.249.73.142|INFRACTIONS:31 (www.redrive.zoovy.com) /robots.txt
BOT|66.249.73.144|INFRACTIONS:31 (reefs2go.com) /robots.txt
BOT|66.249.73.145|INFRACTIONS:14 (www.bikeshacksonline.com) /robots.txt
BOT|66.249.73.146|INFRACTIONS:22 (www.wrigleyfieldsport.com) /robots.txt
BOT|66.249.73.147|INFRACTIONS:21 (www.ecofamilyliving.com) /robots.txt
BOT|66.249.73.149|INFRACTIONS:18 (www.office-chairs-supply.com) /robots.txt
BOT|66.249.73.15|INFRACTIONS:22 (www.drapesunlimited.com) /robots.txt
BOT|66.249.73.150|INFRACTIONS:30 (www.billettruckaccessories.com) /robots.txt
BOT|66.249.73.151|INFRACTIONS:12 (www.zephyrbackpacks.com) /robots.txt
BOT|66.249.73.152|INFRACTIONS:16 (www.protoreflex.com) /robots.txt
BOT|66.249.73.153|INFRACTIONS:48 (www.inflatablessuperstore.com) /robots.txt
BOT|66.249.73.154|INFRACTIONS:28 (www.beltiscool.zoovy.com) /robots.txt
BOT|66.249.73.155|INFRACTIONS:14 (dhsproducts.zoovy.com) /robots.txt
BOT|66.249.73.156|INFRACTIONS:20 (www.dollssoreal.com) /robots.txt
BOT|66.249.73.16|INFRACTIONS:29 (www.soulsurfonline.com) /robots.txt
BOT|66.249.73.161|INFRACTIONS:24 (m.alanagracestore.com) /robots.txt
BOT|66.249.73.162|INFRACTIONS:13 (hotwaterstuff.com) /robots.txt
BOT|66.249.73.163|INFRACTIONS:19 (www.myscbb.gtenterprisecorp.com) /robots.txt
BOT|66.249.73.164|INFRACTIONS:21 (m.jamesmaddockstore.com) /robots.txt
BOT|66.249.73.165|INFRACTIONS:16 (cmamusicfeststore.com) /robots.txt
BOT|66.249.73.166|INFRACTIONS:16 (m.saucebossstore.com) /robots.txt
BOT|66.249.73.167|INFRACTIONS:26 (secure.bigoutlet.com) /robots.txt
BOT|66.249.73.168|INFRACTIONS:25 (autrysports.zoovy.com) /robots.txt
BOT|66.249.73.169|INFRACTIONS:28 (riderswraps.com) /robots.txt
BOT|66.249.73.17|INFRACTIONS:11 (www.dollssoreal.zoovy.com) /robots.txt
BOT|66.249.73.170|INFRACTIONS:15 (www.ledinsider.zoovy.com) /robots.txt
BOT|66.249.73.171|INFRACTIONS:22 (www.dyepaintballonline.com) /sitemap.xml
BOT|66.249.73.172|INFRACTIONS:12 (www.dccomicstshirt.com) /robots.txt
BOT|66.249.73.173|INFRACTIONS:22 (www.shoecoverwarehouse.com) /robots.txt
BOT|66.249.73.174|INFRACTIONS:15 (m.crossbones360.com) /robots.txt
BOT|66.249.73.175|INFRACTIONS:18 (www.gramsgiftcloset.com) /robots.txt
BOT|66.249.73.176|INFRACTIONS:21 (www.thechessstore.zoovy.com) /robots.txt
BOT|66.249.73.177|INFRACTIONS:22 (www.thegiftchoice.com) /robots.txt
BOT|66.249.73.178|INFRACTIONS:21 (www.eventgoggles.com) /robots.txt
BOT|66.249.73.179|INFRACTIONS:21 (www.dabearstore.com) /robots.txt
BOT|66.249.73.18|INFRACTIONS:21 (www.onlinepromgowns.com) /sitemap.xml
BOT|66.249.73.180|INFRACTIONS:19 (www.i-m-so-tired.com) /robots.txt
BOT|66.249.73.181|INFRACTIONS:14 (www.yourlogomats.com) /robots.txt
BOT|66.249.73.182|INFRACTIONS:24 (www.2bhiptshirts.com) /robots.txt
BOT|66.249.73.183|INFRACTIONS:11 (www.mysticwholesale.com) /sitemap.xml
BOT|66.249.73.184|INFRACTIONS:21 (www.tatianabras.com) /robots.txt
BOT|66.249.73.185|INFRACTIONS:25 (www.growingupgreen.net) /robots.txt
BOT|66.249.73.186|INFRACTIONS:20 (www.eclipseego09.com) /robots.txt
BOT|66.249.73.187|INFRACTIONS:20 (www.spaozones.com) /robots.txt
BOT|66.249.73.188|INFRACTIONS:21 (soonerfanshop.com) /robots.txt
BOT|66.249.73.19|INFRACTIONS:16 (www.hifi-alternative.com) /sitemap.xml
BOT|66.249.73.193|INFRACTIONS:31 (www.nantahalatradingpost.com) /robots.txt
BOT|66.249.73.194|INFRACTIONS:23 (www.fastrp.com) /robots.txt
BOT|66.249.73.195|INFRACTIONS:22 (www.monsterrebate.zoovy.com) /robots.txt
BOT|66.249.73.196|INFRACTIONS:25 (www.ibuywaterfeatures.com) /robots.txt
BOT|66.249.73.197|INFRACTIONS:15 (m.bandswag.net) /robots.txt
BOT|66.249.73.20|INFRACTIONS:21 (www.thespotlowrider.com) /robots.txt
BOT|66.249.73.200|INFRACTIONS:26 (m.totalfanshop.zoovy.com) /robots.txt
BOT|66.249.73.201|INFRACTIONS:11 (alloceansports.zoovy.com) /robots.txt
BOT|66.249.73.202|INFRACTIONS:17 (www.wildcollections.zoovy.com) /robots.txt
BOT|66.249.73.203|INFRACTIONS:24 (www.sasydeals.zoovy.com) /robots.txt
BOT|66.249.73.205|INFRACTIONS:17 (www.athruzcloseouts.com) /robots.txt
BOT|66.249.73.206|INFRACTIONS:24 (www.bonnies-treasures.com) /robots.txt
BOT|66.249.73.208|INFRACTIONS:21 (www.bucklesthatrock.com) /robots.txt
BOT|66.249.73.21|INFRACTIONS:23 (www.cubstore.com) /robots.txt
BOT|66.249.73.210|INFRACTIONS:20 (www.mymoonandstar.com) /robots.txt
BOT|66.249.73.211|INFRACTIONS:19 (www.motosporteyewear.com) /robots.txt
BOT|66.249.73.212|INFRACTIONS:13 (www.bigbadpowersports.com) /robots.txt
BOT|66.249.73.214|INFRACTIONS:18 (m.ncknifeman.com) /sitemap.xml
BOT|66.249.73.215|INFRACTIONS:20 (www.2008cubsplayoffgear.com) /robots.txt
BOT|66.249.73.216|INFRACTIONS:26 (www.carolinaparakeetteashoppe.com) /robots.txt
BOT|66.249.73.217|INFRACTIONS:19 (www.bobbirocks.com) /robots.txt
BOT|66.249.73.218|INFRACTIONS:21 (performancereport.zoovy.com) /robots.txt
BOT|66.249.73.219|INFRACTIONS:35 (www.partybrights.com) /robots.txt
BOT|66.249.73.22|INFRACTIONS:27 (www.peggyshomemade.zoovy.com) /robots.txt
BOT|66.249.73.220|INFRACTIONS:28 (trainingsmoke.com) /robots.txt
BOT|66.249.73.225|INFRACTIONS:21 (www.dermadeals.com) /sitemap.xml
BOT|66.249.73.226|INFRACTIONS:23 (www.licenseplateframes.com) /robots.txt
BOT|66.249.73.227|INFRACTIONS:23 (studiohut.zoovy.com) /robots.txt
BOT|66.249.73.228|INFRACTIONS:12 (www.schoolfurniture-online.com) /robots.txt
BOT|66.249.73.229|INFRACTIONS:20 (westchesterwatch.com) /robots.txt
BOT|66.249.73.23|INFRACTIONS:25 (www.rexmorouxstore.com) /robots.txt
BOT|66.249.73.230|INFRACTIONS:15 (www.hotlookz.com) /robots.txt
BOT|66.249.73.231|INFRACTIONS:14 (m.totalfanshop.com) /robots.txt
BOT|66.249.73.232|INFRACTIONS:21 (www.seashellmaster.com) /robots.txt
BOT|66.249.73.233|INFRACTIONS:22 (www.performanceres.theperformancereportwebstore.com) /robots.txt
BOT|66.249.73.234|INFRACTIONS:32 (www.sportstop.zoovy.com) /robots.txt
BOT|66.249.73.235|INFRACTIONS:24 (gooddeals18.com) /robots.txt
BOT|66.249.73.236|INFRACTIONS:26 (espressoparts2.zoovy.com) /robots.txt
BOT|66.249.73.237|INFRACTIONS:25 (bonnies.zoovy.com) /robots.txt
BOT|66.249.73.238|INFRACTIONS:11 (m.tikihomedecor.com) /robots.txt
BOT|66.249.73.239|INFRACTIONS:26 (otisincla.com) /robots.txt
BOT|66.249.73.24|INFRACTIONS:33 (www.renapumpwholesale.com) /robots.txt
BOT|66.249.73.240|INFRACTIONS:21 (www.completecarecenters.com) /sitemap.xml
BOT|66.249.73.241|INFRACTIONS:19 (www.gracehealthcare.net) /robots.txt
BOT|66.249.73.242|INFRACTIONS:22 (m.island-accessories.com) /robots.txt
BOT|66.249.73.243|INFRACTIONS:27 (m.4airborne.com) /sitemap.xml
BOT|66.249.73.244|INFRACTIONS:16 (www.2bhipinc.com) /robots.txt
BOT|66.249.73.245|INFRACTIONS:37 (www.chicagosportsworld.biz) /robots.txt
BOT|66.249.73.246|INFRACTIONS:31 (www.ibuyhomecontrollers.com) /robots.txt
BOT|66.249.73.247|INFRACTIONS:26 (www.bridal-wedding-tiara.com) /robots.txt
BOT|66.249.73.248|INFRACTIONS:20 (gramsgiftcloset.com) /robots.txt
BOT|66.249.73.249|INFRACTIONS:22 (www.crossbows2u.com) /sitemap.xml
BOT|66.249.73.25|INFRACTIONS:13 (www.rotorspeedfeed.com) /robots.txt
BOT|66.249.73.250|INFRACTIONS:14 (www.dealz4realworldwide.com) /robots.txt
BOT|66.249.73.251|INFRACTIONS:31 (www.cypherstyles.com) /sitemap.xml
BOT|66.249.73.252|INFRACTIONS:26 (sportsworldchicago.com) /sitemap.xml
BOT|66.249.73.26|INFRACTIONS:23 (dollssoreal.com) /robots.txt
BOT|66.249.73.27|INFRACTIONS:18 (www.gourmetfruitbaskets.com) /sitemap.xml
BOT|66.249.73.3|INFRACTIONS:19 (beltiscool.zoovy.com) /robots.txt
BOT|66.249.73.33|INFRACTIONS:30 (www.whizardworks.com) /robots.txt
BOT|66.249.73.34|INFRACTIONS:12 (www.bonnies.zoovy.com) /robots.txt
BOT|66.249.73.35|INFRACTIONS:25 (www.promohealthplates.com) /robots.txt
BOT|66.249.73.36|INFRACTIONS:33 (m.smyrnacoin.com) /sitemap.xml
BOT|66.249.73.37|INFRACTIONS:17 (www.leisure.zoovy.com) /robots.txt
BOT|66.249.73.38|INFRACTIONS:33 (www.sassyassyjeans.net) /robots.txt
BOT|66.249.73.39|INFRACTIONS:14 (www.nativstore.com) /robots.txt
BOT|66.249.73.40|INFRACTIONS:21 (www.ibuyfireproducts.com) /robots.txt
BOT|66.249.73.41|INFRACTIONS:25 (www.danymusic.com) /robots.txt
BOT|66.249.73.42|INFRACTIONS:42 (www.orangeonions.com) /robots.txt
BOT|66.249.73.43|INFRACTIONS:20 (ledinsider.zoovy.com) /robots.txt
BOT|66.249.73.44|INFRACTIONS:16 (www.lyongroup.theperformancereportwebstore.com) /robots.txt
BOT|66.249.73.45|INFRACTIONS:49 (inflatablessuperstore.com) /robots.txt
BOT|66.249.73.46|INFRACTIONS:26 (sportstop.zoovy.com) /robots.txt
BOT|66.249.73.47|INFRACTIONS:22 (softenerparts.zoovy.com) /robots.txt
BOT|66.249.73.48|INFRACTIONS:26 (www.autrysports.com) /robots.txt
BOT|66.249.73.49|INFRACTIONS:23 (www.bloomersnbling.com) /robots.txt
BOT|66.249.73.5|INFRACTIONS:17 (m.lukereynoldsstore.com) /robots.txt
BOT|66.249.73.50|INFRACTIONS:26 (www.sportsworldchicago.com) /sitemap.xml
BOT|66.249.73.51|INFRACTIONS:18 (www.bloomindesigns.net) /robots.txt
BOT|66.249.73.52|INFRACTIONS:20 (www.summitfashions.com) /robots.txt
BOT|66.249.73.53|INFRACTIONS:20 (www.tobehip.com) /robots.txt
BOT|66.249.73.54|INFRACTIONS:16 (m.beachboysstore.com) /robots.txt
BOT|66.249.73.55|INFRACTIONS:25 (www.underthesun.zoovy.com) /robots.txt
BOT|66.249.73.56|INFRACTIONS:32 (www.bellydancefabric.com) /sitemap.xml
BOT|66.249.73.58|INFRACTIONS:22 (www.maveriklax.us) /robots.txt
BOT|66.249.73.59|INFRACTIONS:21 (m.rexmorouxstore.com) /robots.txt
BOT|66.249.73.6|INFRACTIONS:18 (www.gamecode4u.com) /robots.txt
BOT|66.249.73.60|INFRACTIONS:20 (www.nyydugout.com) /robots.txt
BOT|66.249.73.65|INFRACTIONS:29 (www.us.halebobstore.com) /sitemap.xml
BOT|66.249.73.66|INFRACTIONS:21 (m.ecobottoms.com) /robots.txt
BOT|66.249.73.67|INFRACTIONS:24 (www.cutecostume.net) /robots.txt
BOT|66.249.73.68|INFRACTIONS:19 (comfortexusa.zoovy.com) /robots.txt
BOT|66.249.73.69|INFRACTIONS:36 (m.skullandbonesdecor.com) /robots.txt
BOT|66.249.73.7|INFRACTIONS:31 (www.quiltjourney.com) /robots.txt
BOT|66.249.73.70|INFRACTIONS:31 (thetoosidedpurseco.com) /robots.txt
BOT|66.249.73.71|INFRACTIONS:28 (www.stateofnine.com) /robots.txt
BOT|66.249.73.72|INFRACTIONS:18 (www.2bhiptees.com) /robots.txt
BOT|66.249.73.74|INFRACTIONS:32 (www.jalyndragonhawk.com) /robots.txt
BOT|66.249.73.75|INFRACTIONS:16 (www.lazerarchery.com) /robots.txt
BOT|66.249.73.76|INFRACTIONS:22 (www.webuildbikes.com) /robots.txt
BOT|66.249.73.77|INFRACTIONS:18 (www.performancereport.zoovy.com) /robots.txt
BOT|66.249.73.78|INFRACTIONS:28 (www.espressoparts2.zoovy.com) /robots.txt
BOT|66.249.73.8|INFRACTIONS:21 (www.ugivem.com) /robots.txt
BOT|66.249.73.80|INFRACTIONS:25 (www.dsbmktg.com) /robots.txt
BOT|66.249.73.81|INFRACTIONS:16 (www.riderswraps.com) /robots.txt
BOT|66.249.73.82|INFRACTIONS:16 (www.westchesterwatch.com) /robots.txt
BOT|66.249.73.83|INFRACTIONS:20 (performancepda.zoovy.com) /robots.txt
BOT|66.249.73.84|INFRACTIONS:34 (www.greatrepublicanz.com) /robots.txt
BOT|66.249.73.85|INFRACTIONS:13 (www.studiohut.zoovy.com) /robots.txt
BOT|66.249.73.86|INFRACTIONS:20 (amigaz.zoovy.com) /robots.txt
BOT|66.249.73.87|INFRACTIONS:23 (orangeonions.com) /robots.txt
BOT|66.249.73.89|INFRACTIONS:21 (wildcollections.zoovy.com) /robots.txt
BOT|66.249.73.9|INFRACTIONS:12 (www.ultimatetoystore.com) /robots.txt
BOT|66.249.73.91|INFRACTIONS:26 (www.perfectpjs.com) /robots.txt
BOT|66.249.73.92|INFRACTIONS:16 (www.superduty-accessoryguy.com) /robots.txt
BOT|66.249.73.97|INFRACTIONS:24 (m.chique-fitness.com) /robots.txt
BOT|66.249.73.98|INFRACTIONS:30 (www.sacredengraving.com) /robots.txt
BOT|66.249.73.99|INFRACTIONS:15 (www.onlineformals.com) /sitemap.xml
BOT|66.85.185.54|INFRACTIONS:25 (www.spiralhaircase.com) /robots.txt
BOT|67.152.29.130|INFRACTIONS:28 (www.gkworld.com) /robots.txt
BOT|67.217.35.30|INFRACTIONS:126 (www.airsoftbobs.com) /robots.txt
BOT|68.47.129.55|INFRACTIONS:141 (www.garagepartsguy.com) /robots.txt
BOT|69.28.58.14|INFRACTIONS:28 (inflatablessuperstore.com) /robots.txt
BOT|69.28.58.70|INFRACTIONS:53 (bloomindesignsgraphics.com) /robots.txt
BOT|69.28.58.71|INFRACTIONS:57 (bigmountaingear.com) /robots.txt
BOT|69.28.58.72|INFRACTIONS:52 (broadwayvacuums.com) /robots.txt
BOT|69.28.58.73|INFRACTIONS:40 (blackhawksshop.com) /robots.txt
BOT|69.28.58.74|INFRACTIONS:24 (broadwayshoebuffer.com) /robots.txt
BOT|69.28.58.75|INFRACTIONS:54 (boomerangfishing.com) /robots.txt
BOT|69.28.58.76|INFRACTIONS:38 (bonnies.zoovy.com) /robots.txt
BOT|69.28.58.77|INFRACTIONS:52 (bostonmedical.com) /robots.txt
BOT|69.28.58.78|INFRACTIONS:47 (bidfortime.com) /robots.txt
BOT|69.28.58.79|INFRACTIONS:47 (buildbikes.net) /robots.txt
BOT|69.28.58.80|INFRACTIONS:59 (blulightning.com) /robots.txt
BOT|69.28.58.81|INFRACTIONS:87 (bigoutlet.com) /robots.txt
BOT|69.28.58.82|INFRACTIONS:43 (bikinimo.com) /robots.txt
BOT|69.28.58.83|INFRACTIONS:49 (bowhuntingstuff.com) /robots.txt
BOT|69.28.58.84|INFRACTIONS:60 (blank-puzzles.com) /robots.txt
BOT|69.28.58.85|INFRACTIONS:55 (canvas-art-posters.com) /robots.txt
BOT|69.28.58.87|INFRACTIONS:47 (bluelightningproducts.com) /robots.txt
BOT|69.28.58.88|INFRACTIONS:34 (berniessmellsnbells.com) /robots.txt
BOT|69.28.58.89|INFRACTIONS:35 (cabootstoo.com) /robots.txt
BOT|69.64.34.49|INFRACTIONS:14 (www.prosafetysupplies.com) /robots.txt
BOT|69.64.46.38|INFRACTIONS:38 (www.greatquotez.com) /robots.txt
BOT|70.28.245.80|INFRACTIONS:60 (www.designed2bsweet.com) i30:11 i120:11 [BOT I30:11]
BOT|70.36.100.148|INFRACTIONS:114 (www.totalfanshop.com) /robots.txt
BOT|71.168.81.16|INFRACTIONS:12 (www.ibuyfiremagicgrills.com) /robots.txt
BOT|71.176.122.244|INFRACTIONS:491 (www.bboyworldshop.com) /robots.txt
BOT|72.233.72.155|INFRACTIONS:26 (www.summitfashions.com) i30:11 i120:11 [BOT I30:11]
BOT|72.30.161.243|INFRACTIONS:14 (www.stage3motorsports.com) /robots.txt
BOT|74.111.22.68|INFRACTIONS:13 (www.source-tropical.com) /robots.txt
BOT|74.118.192.202|INFRACTIONS:36 (www.beautystoredepot.com) /robots.txt
BOT|74.215.15.115|INFRACTIONS:14 (www.antifatiguemat.com) /robots.txt
BOT|76.72.166.150|INFRACTIONS:363 (www.tattooapparel.com) /robots.txt
BOT|77.75.77.11|INFRACTIONS:190 (www.reefs2go.com) /robots.txt
BOT|77.75.77.36|INFRACTIONS:168 (www.cupidmusicstore.com) /robots.txt
BOT|78.30.200.81|INFRACTIONS:41 (www.bowhuntingstuff.com) /robots.txt
BOT|80.202.147.221|INFRACTIONS:25 (cubstore.com) /robots.txt
BOT|80.40.134.120|INFRACTIONS:73 (www.guitarelectronics.com) /robots.txt
BOT|81.144.138.34|INFRACTIONS:59 (www.klatchroasting.zoovy.com) /robots.txt
BOT|81.167.1.232|INFRACTIONS:31 (www.hayspear.com) /robots.txt
BOT|82.128.253.46|INFRACTIONS:48 (www.waterdamagedefense.com) /robots.txt
BOT|82.46.155.45|INFRACTIONS:21 (www.themahjongshop.com) /robots.txt
BOT|83.149.126.98|INFRACTIONS:142 (m.thechessstore.com) /robots.txt
BOT|84.19.190.126|INFRACTIONS:48 (shrink-plastic.com) /robots.txt
BOT|85.19.205.124|INFRACTIONS:11 (www.studiohut.com) /robots.txt
BOT|85.23.153.98|INFRACTIONS:24 (www.stage3motorsports.com) /robots.txt
BOT|87.118.116.25|INFRACTIONS:46 (www.hayspear.com) /robots.txt
BOT|87.194.162.194|INFRACTIONS:15 (www.sassyassyjeans.com) /robots.txt
BOT|88.135.201.228|INFRACTIONS:11 (m.italianseedandtool.com) /robots.txt
BOT|89.75.38.178|INFRACTIONS:39 (bigoutlet.com) /robots.txt
BOT|89.99.5.17|INFRACTIONS:24 (hotmusicbeat.com) /robots.txt
BOT|91.121.111.173|INFRACTIONS:74 (www.dinnerwarepotterymugheaven.com) /robots.txt
BOT|91.121.24.97|INFRACTIONS:23 (www.luvmy3toys.com) /robots.txt
BOT|91.121.81.175|INFRACTIONS:50 (www.cupcakez.com) /robots.txt
BOT|91.209.51.214|INFRACTIONS:15 (www.usflag360.com) /robots.txt
BOT|91.64.204.254|INFRACTIONS:38 (www.flagsonastick.com) /robots.txt
BOT|92.74.250.216|INFRACTIONS:11 (www.partybrites.com) /robots.txt
BOT|93.128.154.122|INFRACTIONS:19 (www.rockerjewelry.com) /robots.txt
BOT|93.180.64.145|INFRACTIONS:245 (www.2bhiphoodies.com) /robots.txt
BOT|93.180.64.200|INFRACTIONS:33 (www.beautystoredepot.com) /robots.txt
BOT|93.219.74.51|INFRACTIONS:11 (www.toynk.com) /robots.txt
BOT|93.93.79.43|INFRACTIONS:15 (www.rdwholesale.net) /robots.txt
BOT|94.100.189.220|INFRACTIONS:14 (www.ibuyfmiproducts.com) /robots.txt
BOT|94.228.34.237|INFRACTIONS:83 (www.gridironsports.com) i30:11 i120:11 [BOT I30:11]
BOT|94.23.13.153|INFRACTIONS:49 (www.triplelux.com) /robots.txt
BOT|94.23.42.135|INFRACTIONS:108 (www.perennialgardenplants.bloomindesigns.com) /robots.txt
BOT|94.245.32.152|INFRACTIONS:27 (m.worldseriescubs.com) /robots.txt
BOT|95.34.76.9|INFRACTIONS:55 (www.elegantaudiovideo.com) /robots.txt
BOT|95.96.224.110|INFRACTIONS:23 (www.bowhuntingstuff.com) /robots.txt
BOT|98.111.60.106|INFRACTIONS:21 (www.greatlookz.zoovy.com) /robots.txt
BOT|98.68.183.251|INFRACTIONS:11 (www.itascamoccasin.com) i30:11 i120:20 [BOT I30:11]






WATCH|100.43.83.158|REASON:3503 hits
WATCH|165.193.42.78|REASON:2184 hits
WATCH|184.173.183.172|REASON:501 hits
SAFE|192.168.2.249|REASON: ZOOVY
WATCH|206.16.59.102|REASON:803 hits
WATCH|50.17.90.2|REASON:2099 hits
WATCH|100.43.83.158|REASON:1241 hits
WATCH|157.55.17.103|REASON:1629 hits
WATCH|157.55.17.195|REASON:560 hits
WATCH|192.168.2.249|REASON:1827 hits
WATCH|206.16.59.118|REASON:577 hits
WATCH|206.16.59.126|REASON:593 hits
WATCH|207.46.13.118|REASON:948 hits
WATCH|207.46.13.208|REASON:572 hits
WATCH|207.46.13.93|REASON:762 hits
WATCH|207.46.13.98|REASON:817 hits
WATCH|207.46.13.99|REASON:2126 hits
WATCH|207.46.195.241|REASON:2073 hits
WATCH|207.46.199.53|REASON:989 hits
WATCH|207.46.199.54|REASON:2338 hits
WATCH|207.46.204.233|REASON:1985 hits
WATCH|207.46.204.242|REASON:660 hits
WATCH|64.57.200.229|REASON:724 hits
BOT|66.249.73.11|REASON:1061 hits
BOT|66.249.73.143|REASON:1610 hits
BOT|66.249.73.148|REASON:509 hits
BOT|66.249.73.199|REASON:556 hits
BOT|66.249.73.204|REASON:678 hits
BOT|66.249.73.207|REASON:1072 hits
BOT|66.249.73.28|REASON:1614 hits
BOT|66.249.73.2|REASON:879 hits
BOT|66.249.73.4|REASON:643 hits
BOT|66.249.73.79|REASON:654 hits
BOT|66.249.73.88|REASON:620 hits
BOT|66.249.73.90|REASON:628 hits
BOT|IP:66.211.170.67|WHEN:20110204|SERVER:www.glassbeadgarden.com|REASON:GOogle
BOT|IP:66.249.67.*|WHEN:20110201|SERVER:www.fleurdelisdirect.com|REASON:Google
BOT|IP:66.249.68.*|WHEN:20110216|SERVER:www.sassyassyjeans.com|REASON:Google
WATCH|8.11.2.10|REASON:855 hits


WATCH|66.249.71.77|REASON:1043 hits
WATCH|85.17.29.107|REASON:998 hits


WATCH|66.249.67.27|REASON:1018 hits
WATCH|66.249.68.180|REASON:549 hits
WATCH|66.249.68.54|REASON:789 hits
KWATCH|8.11.2.10|REASON:1261 hits
WATCH|8.11.2.9|REASON:797 hits


WATCH|107.22.133.228|REASON:1789 hits
WATCH|174.129.177.94|REASON:617 hits
WATCH|66.249.67.*|REASON:506 hits
WATCH|66.249.68.*|REASON:536 hits
WATCH|8.11.2.*|REASON:617 hits


KILL|62.219.8.227|REASON:634 hits
WATCH|66.249.68.104|REASON:1541 hits
WATCH|66.249.68.15|REASON:529 hits
KILL|93.159.111.83|REASON:1040 hits

KILL|38.101.148.126|REASON:912 hits
KILL|8.11.2.9|REASON:791 hits
WATCH|91.146.105.200|REASON:1029 hits
WATCH|95.108.151.244|REASON:2287 hits

SCAN|199.21.99.*|REASON:1092 hits|Yandex 
WATCH|66.249.67.*|REASON:519 hits
WATCH|66.249.68.*|REASON:509 hits
KILL|94.76.221.219|REASON:4218 hits

BOT|95.211.238.109|REASON:robots, max hits
BOT|95.211.238.110|REASON:robots, max hits
BOT|95.211.238.111|REASON:robots, max hits
BOT|95.211.238.112|REASON:robots, max hits
BOT|95.211.238.113|REASON:robots, max hits
BOT|95.211.238.114|REASON:robots, max hits
BOT|95.211.238.115|REASON:robots, max hits

WATCH|123.21.222.219|
WATCH|212.79.110.13|
WATCH|195.128.230.51|
WATCH|178.125.219.9|
WATCH|117.4.36.48|
WATCH|178.154.46.201|REASON:8140 hits
WATCH|178.165.28.232|REASON:3121 hits
WATCH|178.91.128.245|REASON:9536 hits
WATCH|178.93.12.132|REASON:2957 hits
WATCH|183.80.251.160|REASON:2653 hits
WATCH|183.80.30.73|REASON:15079 hits
WATCH|183.80.41.1|REASON:761 hits
WATCH|183.80.49.164|REASON:17047 hits
WATCH|183.80.58.175|REASON:10041 hits
WATCH|183.81.53.117|REASON:6792 hits
WATCH|188.143.24.211|REASON:19404 hits
WATCH|193.151.40.57|REASON:2747 hits
WATCH|194.11.28.1|REASON:7735 hits
WATCH|194.181.137.206|REASON:1512 hits
WATCH|195.211.140.5|REASON:13173 hits
WATCH|195.238.107.121|REASON:3909 hits
WATCH|2.133.101.72|REASON:2186 hits
WATCH|2.195.48.105|REASON:533 hits
WATCH|2.92.224.13|REASON:724 hits
WATCH|2.92.8.107|REASON:2632 hits
WATCH|206.16.59.108|REASON:587 hits
WATCH|209.85.238.66|REASON:583 hits
WATCH|212.164.137.153|REASON:9329 hits
WATCH|212.7.26.191|REASON:7006 hits
WATCH|213.109.237.5|REASON:10947 hits
WATCH|213.154.12.159|REASON:838 hits
WATCH|222.252.76.212|REASON:608 hits
WATCH|222.253.108.52|REASON:4124 hits
WATCH|222.253.74.190|REASON:9586 hits
WATCH|222.254.18.178|REASON:6557 hits
WATCH|23.20.86.230|REASON:585 hits
WATCH|23.20.93.171|REASON:1074 hits
WATCH|24.86.184.185|REASON:2946 hits
WATCH|27.74.64.32|REASON:1689 hits
WATCH|27.78.219.83|REASON:2515 hits
WATCH|27.78.32.82|REASON:10372 hits
WATCH|27.79.220.57|REASON:2489 hits
WATCH|31.135.146.80|REASON:10654 hits
WATCH|37.45.163.99|REASON:552 hits
WATCH|37.45.231.233|REASON:2676 hits
WATCH|37.45.24.25|REASON:1548 hits
WATCH|37.55.155.163|REASON:1450 hits
WATCH|41.100.110.147|REASON:16308 hits
WATCH|41.103.3.109|REASON:19029 hits
WATCH|41.129.9.146|REASON:9434 hits
WATCH|42.114.51.27|REASON:5573 hits
WATCH|42.119.247.70|REASON:17834 hits
WATCH|46.109.247.183|REASON:13083 hits
WATCH|46.200.74.40|REASON:4971 hits
WATCH|46.203.125.114|REASON:721 hits
WATCH|46.216.151.74|REASON:1348 hits
WATCH|46.55.57.212|REASON:14653 hits
WATCH|46.63.6.246|REASON:539 hits
WATCH|58.186.118.44|REASON:2951 hits
WATCH|58.186.44.120|REASON:7071 hits
WATCH|58.187.77.217|REASON:4661 hits
WATCH|62.251.234.252|REASON:16297 hits
WATCH|62.64.125.132|REASON:587 hits
WATCH|66.249.67.49|REASON:690 hits
WATCH|67.184.88.142|REASON:18407 hits
WATCH|70.243.166.236|REASON:3591 hits
WATCH|78.113.28.225|REASON:9630 hits
WATCH|78.60.81.38|REASON:4389 hits
WATCH|78.61.30.27|REASON:3469 hits
WATCH|78.94.154.153|REASON:18250 hits
WATCH|80.188.215.139|REASON:723 hits
WATCH|80.56.195.48|REASON:21528 hits
WATCH|81.182.204.42|REASON:1786 hits
WATCH|85.73.55.11|REASON:7581 hits
WATCH|87.110.163.144|REASON:635 hits
WATCH|87.171.46.137|REASON:10537 hits
WATCH|89.134.96.201|REASON:4402 hits
WATCH|89.232.5.80|REASON:5835 hits
WATCH|91.78.108.55|REASON:1608 hits
WATCH|92.112.144.238|REASON:2317 hits
WATCH|92.112.146.204|REASON:2577 hits
WATCH|92.113.106.89|REASON:3961 hits
WATCH|92.113.15.1|REASON:4877 hits
WATCH|92.114.247.251|REASON:637 hits
WATCH|92.242.99.166|REASON:2693 hits
WATCH|92.47.244.66|REASON:7204 hits
WATCH|92.90.17.129|REASON:2925 hits
WATCH|93.125.108.4|REASON:3148 hits
WATCH|93.183.251.216|REASON:4923 hits
WATCH|93.185.252.189|REASON:1975 hits
WATCH|93.71.157.237|REASON:6344 hits
WATCH|93.75.38.13|REASON:3784 hits
WATCH|93.84.58.34|REASON:15644 hits
WATCH|93.85.13.228|REASON:4040 hits
WATCH|93.85.227.255|REASON:636 hits
WATCH|94.181.36.72|REASON:11743 hits
WATCH|94.68.154.234|REASON:4919 hits
WATCH|94.76.67.66|REASON:11347 hits
WATCH|95.108.150.235|REASON:956 hits
WATCH|95.133.250.141|REASON:3456 hits
WATCH|95.133.37.106|REASON:8901 hits
WATCH|95.134.155.64|REASON:10161 hits
WATCH|95.153.96.248|REASON:13076 hits
WATCH|95.56.26.47|REASON:5325 hits
WATCH|95.57.64.167|REASON:2891 hits
WATCH|95.58.239.5|REASON:513 hits
WATCH|95.59.217.83|REASON:578 hits
WATCH|95.65.77.252|REASON:2202 hits
WATCH|117.4.36.48
WATCH|117.5.123.94
WATCH|113.168.149.158
## 
WATCH|183.80.251.160|REASON:
WATCH|178.125.177.161|REASON:
WATCH|31.135.146.80|REASON:
WATCH|178.127.100.221|REASON:2/12/12|hits=3202 sec=117 type=
WATCH|118.68.188.101|REASON:2/12/12|hits=2719 sec=2 type=
WATCH|183.80.49.164|REASON:2/12/12|hits=2703 sec=0 type=
WATCH|41.100.110.147|REASON:2/12/12|hits=2689 sec=88 type=
WATCH|62.251.234.252|REASON:2/12/12|hits=2593 sec=44 type=
WATCH|41.103.3.109|REASON:2/12/12|hits=2563 sec=0 type=
WATCH|171.226.74.133|REASON:2/12/12|hits=2080 sec=0 type=
WATCH|178.125.177.161|REASON:2/12/12|hits=2059 sec=20 type=
WATCH|42.119.247.70|REASON:2/12/12|hits=2031 sec=55 type=
WATCH|115.75.41.69|REASON:2/12/12|hits=1747 sec=0 type=
WATCH|151.32.21.215|REASON:hits=1669 sec=2 type=

SCAN|161.69.0.*|REASON: McAfee
SCAN|161.69.1.*|REASON: McAfee
SCAN|161.69.2.*|REASON: McAfee
SCAN|161.69.3.*|REASON: McAfee
SCAN|161.69.4.*|REASON: McAfee
SCAN|161.69.5.*|REASON: McAfee
SCAN|161.69.6.*|REASON: McAfee
SCAN|161.69.7.*|REASON: McAfee
SCAN|161.69.8.*|REASON: McAfee
SCAN|161.69.9.*|REASON: McAfee
SCAN|161.69.10.*|REASON: McAfee
SCAN|161.69.11.*|REASON: McAfee
SCAN|161.69.12.*|REASON: McAfee
SCAN|161.69.13.*|REASON: McAfee
SCAN|161.69.14.*|REASON: McAfee
SCAN|161.69.15.*|REASON: McAfee
SCAN|161.69.16.*|REASON: McAfee
SCAN|161.69.17.*|REASON: McAfee
SCAN|161.69.18.*|REASON: McAfee
SCAN|161.69.19.*|REASON: McAfee
SCAN|161.69.20.*|REASON: McAfee
SCAN|161.69.21.*|REASON: McAfee
SCAN|161.69.22.*|REASON: McAfee
SCAN|161.69.23.*|REASON: McAfee
SCAN|161.69.24.*|REASON: McAfee
SCAN|161.69.25.*|REASON: McAfee
SCAN|161.69.26.*|REASON: McAfee
SCAN|161.69.27.*|REASON: McAfee
SCAN|161.69.28.*|REASON: McAfee
SCAN|161.69.29.*|REASON: McAfee
SCAN|161.69.30.*|REASON: McAfee
SCAN|161.69.31.*|REASON: McAfee
SCAN|161.69.32.*|REASON: McAfee
SCAN|161.69.33.*|REASON: McAfee
SCAN|161.69.34.*|REASON: McAfee
SCAN|161.69.35.*|REASON: McAfee
SCAN|161.69.36.*|REASON: McAfee
SCAN|161.69.37.*|REASON: McAfee
SCAN|161.69.38.*|REASON: McAfee
SCAN|161.69.39.*|REASON: McAfee
SCAN|161.69.40.*|REASON: McAfee
SCAN|161.69.41.*|REASON: McAfee
SCAN|161.69.42.*|REASON: McAfee
SCAN|161.69.43.*|REASON: McAfee
SCAN|161.69.44.*|REASON: McAfee
SCAN|161.69.45.*|REASON: McAfee
SCAN|161.69.46.*|REASON: McAfee
SCAN|161.69.47.*|REASON: McAfee
SCAN|161.69.48.*|REASON: McAfee
SCAN|161.69.49.*|REASON: McAfee
SCAN|161.69.50.*|REASON: McAfee
SCAN|161.69.51.*|REASON: McAfee
SCAN|161.69.52.*|REASON: McAfee
SCAN|161.69.53.*|REASON: McAfee
SCAN|161.69.54.*|REASON: McAfee
SCAN|161.69.55.*|REASON: McAfee
SCAN|161.69.56.*|REASON: McAfee
SCAN|161.69.57.*|REASON: McAfee
SCAN|161.69.58.*|REASON: McAfee
SCAN|161.69.59.*|REASON: McAfee
SCAN|161.69.60.*|REASON: McAfee
SCAN|161.69.61.*|REASON: McAfee
SCAN|161.69.62.*|REASON: McAfee
SCAN|161.69.63.*|REASON: McAfee
SCAN|161.69.64.*|REASON: McAfee
SCAN|161.69.65.*|REASON: McAfee
SCAN|161.69.66.*|REASON: McAfee
SCAN|161.69.67.*|REASON: McAfee
SCAN|161.69.68.*|REASON: McAfee
SCAN|161.69.69.*|REASON: McAfee
SCAN|161.69.70.*|REASON: McAfee
SCAN|161.69.71.*|REASON: McAfee
SCAN|161.69.72.*|REASON: McAfee
SCAN|161.69.73.*|REASON: McAfee
SCAN|161.69.74.*|REASON: McAfee
SCAN|161.69.75.*|REASON: McAfee
SCAN|161.69.76.*|REASON: McAfee
SCAN|161.69.77.*|REASON: McAfee
SCAN|161.69.78.*|REASON: McAfee
SCAN|161.69.79.*|REASON: McAfee
SCAN|161.69.80.*|REASON: McAfee
SCAN|161.69.81.*|REASON: McAfee
SCAN|161.69.82.*|REASON: McAfee
SCAN|161.69.83.*|REASON: McAfee
SCAN|161.69.84.*|REASON: McAfee
SCAN|161.69.85.*|REASON: McAfee
SCAN|161.69.86.*|REASON: McAfee
SCAN|161.69.87.*|REASON: McAfee
SCAN|161.69.88.*|REASON: McAfee
SCAN|161.69.89.*|REASON: McAfee
SCAN|161.69.90.*|REASON: McAfee
SCAN|161.69.91.*|REASON: McAfee
SCAN|161.69.92.*|REASON: McAfee
SCAN|161.69.93.*|REASON: McAfee
SCAN|161.69.94.*|REASON: McAfee
SCAN|161.69.95.*|REASON: McAfee
SCAN|161.69.96.*|REASON: McAfee
SCAN|161.69.97.*|REASON: McAfee
SCAN|161.69.98.*|REASON: McAfee
SCAN|161.69.99.*|REASON: McAfee
SCAN|161.69.100.*|REASON: McAfee
SCAN|161.69.101.*|REASON: McAfee
SCAN|161.69.102.*|REASON: McAfee
SCAN|161.69.103.*|REASON: McAfee
SCAN|161.69.104.*|REASON: McAfee
SCAN|161.69.105.*|REASON: McAfee
SCAN|161.69.106.*|REASON: McAfee
SCAN|161.69.107.*|REASON: McAfee
SCAN|161.69.108.*|REASON: McAfee
SCAN|161.69.109.*|REASON: McAfee
SCAN|161.69.110.*|REASON: McAfee
SCAN|161.69.111.*|REASON: McAfee
SCAN|161.69.112.*|REASON: McAfee
SCAN|161.69.113.*|REASON: McAfee
SCAN|161.69.114.*|REASON: McAfee
SCAN|161.69.115.*|REASON: McAfee
SCAN|161.69.116.*|REASON: McAfee
SCAN|161.69.117.*|REASON: McAfee
SCAN|161.69.118.*|REASON: McAfee
SCAN|161.69.119.*|REASON: McAfee
SCAN|161.69.120.*|REASON: McAfee
SCAN|161.69.121.*|REASON: McAfee
SCAN|161.69.122.*|REASON: McAfee
SCAN|161.69.123.*|REASON: McAfee
SCAN|161.69.124.*|REASON: McAfee
SCAN|161.69.125.*|REASON: McAfee
SCAN|161.69.126.*|REASON: McAfee
SCAN|161.69.127.*|REASON: McAfee
SCAN|161.69.128.*|REASON: McAfee
SCAN|161.69.129.*|REASON: McAfee
SCAN|161.69.130.*|REASON: McAfee
SCAN|161.69.131.*|REASON: McAfee
SCAN|161.69.132.*|REASON: McAfee
SCAN|161.69.133.*|REASON: McAfee
SCAN|161.69.134.*|REASON: McAfee
SCAN|161.69.135.*|REASON: McAfee
SCAN|161.69.136.*|REASON: McAfee
SCAN|161.69.137.*|REASON: McAfee
SCAN|161.69.138.*|REASON: McAfee
SCAN|161.69.139.*|REASON: McAfee
SCAN|161.69.140.*|REASON: McAfee
SCAN|161.69.141.*|REASON: McAfee
SCAN|161.69.142.*|REASON: McAfee
SCAN|161.69.143.*|REASON: McAfee
SCAN|161.69.144.*|REASON: McAfee
SCAN|161.69.145.*|REASON: McAfee
SCAN|161.69.146.*|REASON: McAfee
SCAN|161.69.147.*|REASON: McAfee
SCAN|161.69.148.*|REASON: McAfee
SCAN|161.69.149.*|REASON: McAfee
SCAN|161.69.150.*|REASON: McAfee
SCAN|161.69.151.*|REASON: McAfee
SCAN|161.69.152.*|REASON: McAfee
SCAN|161.69.153.*|REASON: McAfee
SCAN|161.69.154.*|REASON: McAfee
SCAN|161.69.155.*|REASON: McAfee
SCAN|161.69.156.*|REASON: McAfee
SCAN|161.69.157.*|REASON: McAfee
SCAN|161.69.158.*|REASON: McAfee
SCAN|161.69.159.*|REASON: McAfee
SCAN|161.69.160.*|REASON: McAfee
SCAN|161.69.161.*|REASON: McAfee
SCAN|161.69.162.*|REASON: McAfee
SCAN|161.69.163.*|REASON: McAfee
SCAN|161.69.164.*|REASON: McAfee
SCAN|161.69.165.*|REASON: McAfee
SCAN|161.69.166.*|REASON: McAfee
SCAN|161.69.167.*|REASON: McAfee
SCAN|161.69.168.*|REASON: McAfee
SCAN|161.69.169.*|REASON: McAfee
SCAN|161.69.170.*|REASON: McAfee
SCAN|161.69.171.*|REASON: McAfee
SCAN|161.69.172.*|REASON: McAfee
SCAN|161.69.173.*|REASON: McAfee
SCAN|161.69.174.*|REASON: McAfee
SCAN|161.69.175.*|REASON: McAfee
SCAN|161.69.176.*|REASON: McAfee
SCAN|161.69.177.*|REASON: McAfee
SCAN|161.69.178.*|REASON: McAfee
SCAN|161.69.179.*|REASON: McAfee
SCAN|161.69.180.*|REASON: McAfee
SCAN|161.69.181.*|REASON: McAfee
SCAN|161.69.182.*|REASON: McAfee
SCAN|161.69.183.*|REASON: McAfee
SCAN|161.69.184.*|REASON: McAfee
SCAN|161.69.185.*|REASON: McAfee
SCAN|161.69.186.*|REASON: McAfee
SCAN|161.69.187.*|REASON: McAfee
SCAN|161.69.188.*|REASON: McAfee
SCAN|161.69.189.*|REASON: McAfee
SCAN|161.69.190.*|REASON: McAfee
SCAN|161.69.191.*|REASON: McAfee
SCAN|161.69.192.*|REASON: McAfee
SCAN|161.69.193.*|REASON: McAfee
SCAN|161.69.194.*|REASON: McAfee
SCAN|161.69.195.*|REASON: McAfee
SCAN|161.69.196.*|REASON: McAfee
SCAN|161.69.197.*|REASON: McAfee
SCAN|161.69.198.*|REASON: McAfee
SCAN|161.69.199.*|REASON: McAfee
SCAN|161.69.200.*|REASON: McAfee
SCAN|161.69.201.*|REASON: McAfee
SCAN|161.69.202.*|REASON: McAfee
SCAN|161.69.203.*|REASON: McAfee
SCAN|161.69.204.*|REASON: McAfee
SCAN|161.69.205.*|REASON: McAfee
SCAN|161.69.206.*|REASON: McAfee
SCAN|161.69.207.*|REASON: McAfee
SCAN|161.69.208.*|REASON: McAfee
SCAN|161.69.209.*|REASON: McAfee
SCAN|161.69.210.*|REASON: McAfee
SCAN|161.69.211.*|REASON: McAfee
SCAN|161.69.212.*|REASON: McAfee
SCAN|161.69.213.*|REASON: McAfee
SCAN|161.69.214.*|REASON: McAfee
SCAN|161.69.215.*|REASON: McAfee
SCAN|161.69.216.*|REASON: McAfee
SCAN|161.69.217.*|REASON: McAfee
SCAN|161.69.218.*|REASON: McAfee
SCAN|161.69.219.*|REASON: McAfee
SCAN|161.69.220.*|REASON: McAfee
SCAN|161.69.221.*|REASON: McAfee
SCAN|161.69.222.*|REASON: McAfee
SCAN|161.69.223.*|REASON: McAfee
SCAN|161.69.224.*|REASON: McAfee
SCAN|161.69.225.*|REASON: McAfee
SCAN|161.69.226.*|REASON: McAfee
SCAN|161.69.227.*|REASON: McAfee
SCAN|161.69.228.*|REASON: McAfee
SCAN|161.69.229.*|REASON: McAfee
SCAN|161.69.230.*|REASON: McAfee
SCAN|161.69.231.*|REASON: McAfee
SCAN|161.69.232.*|REASON: McAfee
SCAN|161.69.233.*|REASON: McAfee
SCAN|161.69.234.*|REASON: McAfee
SCAN|161.69.235.*|REASON: McAfee
SCAN|161.69.236.*|REASON: McAfee
SCAN|161.69.237.*|REASON: McAfee
SCAN|161.69.238.*|REASON: McAfee
SCAN|161.69.239.*|REASON: McAfee
SCAN|161.69.240.*|REASON: McAfee
SCAN|161.69.241.*|REASON: McAfee
SCAN|161.69.242.*|REASON: McAfee
SCAN|161.69.243.*|REASON: McAfee
SCAN|161.69.244.*|REASON: McAfee
SCAN|161.69.245.*|REASON: McAfee
SCAN|161.69.246.*|REASON: McAfee
SCAN|161.69.247.*|REASON: McAfee
SCAN|161.69.248.*|REASON: McAfee
SCAN|161.69.249.*|REASON: McAfee
SCAN|161.69.250.*|REASON: McAfee
SCAN|161.69.251.*|REASON: McAfee
SCAN|161.69.252.*|REASON: McAfee
SCAN|161.69.253.*|REASON: McAfee
SCAN|161.69.254.*|REASON: McAfee
SCAN|161.69.255.*|REASON: McAfee


WATCH|23.20.93.171|REASON:
WATCH|95.108.150.235|REASON:

WATCH|IP:94.65.225.50|REASON:2/12/12

WATCH|IP:77.88.30.246|REASON:12/31/11 #YANDEX LLC

WATCH|IP:188.143.232.210|REASON:
WATCH|IP:159.253.145.175|REASON:' => 75,
WATCH|IP:46.4.95.140|REASON:' => 996,
WATCH|IP:88.190.13.201|REASON:' => 179,
WATCH|IP:184.154.48.82|REASON:' => 835


WATCH|IP:176.9.51.207|REASON:12/29/11

WATCH|IP:216.176.179.82|REASON:hyperspin  #1	Seattle, Washington, USA (Wowrack)		Internap	
WATCH|IP:69.22.166.25|REASON:hyperspin #2	San Jose, California, USA	Limelight, nLayer	
WATCH|IP:74.200.95.42|REASON:hyperspin #3	Ashburn, Virginia, USA	PCCWGlobal, Limelight Network, nLayer, Cogent, Hurricane Electric, ServerCentral	
WATCH|IP:74.200.92.42|REASON:hyperspin #4	Chicago, Illinois, USA	Hurricane Electric, PCCWGlobal	
WATCH|IP:204.14.88.163|REASON:hyperspin #5	Secaucus, New Jersey, USA (Fluid Hosting)	Internap, Bandcon	
WATCH|IP:72.55.164.246|REASON:hyperspin #6	Montreal, Quebec, Canada	Tata Communications, Videotron, Peer1, TorIX, Level 3, Deutsche Telekom	
WATCH|IP:85.234.152.91|REASON:hyperspin #7	Maidenhead, Berkshire, UK	Euroconnex	
WATCH|IP:94.23.240.44|REASON:hyperspin #8	Roubaix, France (VHosting Solution)	Global Croissing, Teleglobe, FreeTelecom, Sfinx, FreeIX, Telehouse 1, Telehouse 2, Redbus, Global Switch	
WATCH|IP:83.149.104.60|REASON:hyperspin #9	Amsterdam, Netherlands (Leaseweb)	TeliaSonera, Abovenet, Teleglobe, Interoute, AMS-IX, KPN, UUNET, DE-CIX	
WATCH|IP:77.240.118.10|REASON:hyperspin #10	Madrid, Spain	Ibericahost	
WATCH|IP:78.159.196.25|REASON:hyperspin #11	Milan, Italy	Retelit	
WATCH|IP:212.95.32.114|REASON:hyperspin #12	Frankfurt, Hesse, Germany	AMS-IX, DE-CIX, LINX, DTAG, Global Crossing, Tiscali	
WATCH|IP:203.211.130.204|REASON:hyperspin #13	Singapore	Reach, ANC, Pacific Internet, Singtel MegaPOP, StarHub	
WATCH|IP:219.84.160.129|REASON:hyperspin #14	Zhongzheng, Taipei, Taiwan	So-Net	
WATCH|IP:202.168.198.9|REASON:hyperspin #15	Neihu, Taipei, Taiwan	eASPNet	
WATCH|IP:203.31.191.5|REASON:hyperspin #16	Brisbane, Queensland, Australia  	Optus, Telstra, Pipe Networks

WATCH|IP:176.9.51.135|REASON:scanning without permission
WATCH|IP:41.203.119.18|REASON:scanning without permission
WATCH|IP:85.17.29.107|REASON:12/22/11
WATCH|IP:67.212.188.154|REASON:scanning without permission
WATCH|IP:128.2.207.79|REASON:12/22/11
WATCH|IP:69.51.123.114|REASON:12/26/11

WATCH|IP:81.93.218.199|REASON:generating *huge* carts 12/10/11
WATCH|IP:174.127.133.2|
WATCH|IP:95.108.216.251|REASON:abuse
WATCH|IP:76.182.68.4
WATCH|IP:207.46.204.177|REASON:msn|WHEN:20110913

WATCH|IP:93.158.148.30|REASON: excessive use
WATCH|IP:8.11.2.10|REASON:excessive use
WATCH|IP:206.16.59.104|REASON:excessive use
# https://www.securitymetrics.com/scanning.adp
KILL|IP:204.238.82.16|REASON:securitymetrics
KILL|IP:204.238.82.17|REASON:securitymetrics
KILL|IP:204.238.82.18|REASON:securitymetrics
KILL|IP:204.238.82.19|REASON:securitymetrics
KILL|IP:204.238.82.20|REASON:securitymetrics
KILL|IP:204.238.82.21|REASON:securitymetrics
KILL|IP:204.238.82.22|REASON:securitymetrics
KILL|IP:204.238.82.23|REASON:securitymetrics
KILL|IP:204.238.82.24|REASON:securitymetrics
KILL|IP:204.238.82.25|REASON:securitymetrics
KILL|IP:204.238.82.26|REASON:securitymetrics
KILL|IP:204.238.82.27|REASON:securitymetrics
KILL|IP:204.238.82.28|REASON:securitymetrics
KILL|IP:204.238.82.29|REASON:securitymetrics
KILL|IP:204.238.82.30|REASON:securitymetrics
KILL|IP:204.238.82.31|REASON:securitymetrics
KILL|IP:204.238.82.32|REASON:securitymetrics
KILL|IP:204.238.82.33|REASON:securitymetrics
KILL|IP:204.238.82.34|REASON:securitymetrics
KILL|IP:204.238.82.35|REASON:securitymetrics
KILL|IP:204.238.82.36|REASON:securitymetrics
KILL|IP:204.238.82.37|REASON:securitymetrics
KILL|IP:204.238.82.38|REASON:securitymetrics
KILL|IP:204.238.82.39|REASON:securitymetrics
KILL|IP:204.238.82.40|REASON:securitymetrics
KILL|IP:204.238.82.41|REASON:securitymetrics
KILL|IP:204.238.82.42|REASON:securitymetrics
KILL|IP:204.238.82.43|REASON:securitymetrics
KILL|IP:204.238.82.44|REASON:securitymetrics
KILL|IP:204.238.82.45|REASON:securitymetrics
KILL|IP:204.238.82.46|REASON:securitymetrics
KILL|IP:204.238.82.47|REASON:securitymetrics
KILL|IP:204.238.82.48|REASON:securitymetrics
KILL|IP:63.235.131.224|REASON:securitymetrics
KILL|IP:63.235.131.225|REASON:securitymetrics
KILL|IP:63.235.131.226|REASON:securitymetrics
KILL|IP:63.235.131.227|REASON:securitymetrics
KILL|IP:63.235.131.228|REASON:securitymetrics
KILL|IP:63.235.131.229|REASON:securitymetrics
KILL|IP:63.235.131.230|REASON:securitymetrics
KILL|IP:63.235.131.231|REASON:securitymetrics
KILL|IP:63.235.131.232|REASON:securitymetrics
KILL|IP:63.235.131.233|REASON:securitymetrics
KILL|IP:63.235.131.234|REASON:securitymetrics
KILL|IP:63.235.131.235|REASON:securitymetrics
KILL|IP:63.235.131.236|REASON:securitymetrics
KILL|IP:63.235.131.237|REASON:securitymetrics
KILL|IP:63.235.131.238|REASON:securitymetrics
KILL|IP:63.235.131.239|REASON:securitymetrics
KILL|IP:63.235.131.240|REASON:securitymetrics
KILL|IP:63.235.131.241|REASON:securitymetrics
KILL|IP:63.235.131.242|REASON:securitymetrics
KILL|IP:63.235.131.243|REASON:securitymetrics
KILL|IP:63.235.131.244|REASON:securitymetrics
KILL|IP:63.235.131.245|REASON:securitymetrics
KILL|IP:63.235.131.246|REASON:securitymetrics
KILL|IP:63.235.131.247|REASON:securitymetrics
KILL|IP:63.235.131.248|REASON:securitymetrics
KILL|IP:63.235.131.249|REASON:securitymetrics
KILL|IP:63.235.131.250|REASON:securitymetrics
KILL|IP:63.235.131.251|REASON:securitymetrics
KILL|IP:63.235.131.252|REASON:securitymetrics
KILL|IP:63.235.131.253|REASON:securitymetrics
KILL|IP:63.235.131.254|REASON:securitymetrics


WATCH|IP:50.81.88.38|WHEN:20110718|REASON:dos

WATCH|IP:77.88.27.27
WATCH|IP:173.224.112.96
WATCH|IP:74.86.96.147
WATCH|IP:46.21.144.176
WATCH|IP:84.45.53.2

##
## file contains a list of known bots on various webservers .. each webserver
##	if it notices a high rate of requests may append to it's individual file.
##

WATCH|IP:157.55.116.	# msn
WATCH|IP:75.101.230.	# amazon?


## some random spider hitting our servers 11/12/07
#KILL|IP:82.99.30.
## Datability Software Systems, Inc. 9/13/07
## security testing robot SCAN ALERT 3/8/07
#KILL|IP:64.14.3.
## live.com
WATCH|IP:65.55.3.
WATCH|IP:65.55.214.
##		204.238.82.4 - abuse@sdcorp.com - added 11/8/06
#KILL|IP:204.238.82.
## 38.98.120.80 - mean robot spidering dealexpress
#KILL|IP:38.98.120.80
## Exodus?
#KILL|IP:209.67.114.
## Rackspace?
#KILL|IP:72.32.118.
#KILL|IP:152.163.100.
## Isomedia Inc
#KILL|IP:207.115.69.
## Google -- THIS WAS BAD, ALWAYS CHECK WHOIS
SAFE|IP:66.249.72.
#KILL|IP:8.11.2.
#KILL|IP:208.101.11.
#KILL|IP:64.41.168.
## BAD BOT - 4/30/08 spidering wlanparts  .207, .209, etc.
#MISS|IP:60.240.249.
#MISS|IP:140.99.16.42
MISS|IP:91.214.46.18




__DATA__

SAFE|IP:67.175.134.211|WHEN:20121025|USER:cubworld

BOT|IP:95.108.150.235|WHEN:20110630|REASON:Yandex
KILL|IP:62.231.141.195|WHEN:20110630

WATCH|IP:67.195.114.*|REASON:yahoo
WATCH|IP:67.195.113.*|REASON:yahoo
WATCH|IP:67.195.112.*|REASON:yahoo
WATCH|IP:67.195.111.*|REASON:yahoo
WATCH|IP:67.195.110.*|REASON:yahoo

## REPRICING ENGINE?
KILL|IP:184.72.157.108|WHEN:20101005
KILL|IP:38.99.96.238|REASON:took out entire snap cluster

## SPAMBOT
KILL|IP:112.202.123.96
BOT|IP:213.186.120.196|WHEN:20101005
BOT|IP:213.186.119.*|WHEN:20120808|AhrefsBot
BOT|IP:213.186.122.*|WHEN:20120808
BOT|IP:213.186.120.*|WHEN:20120808
BOT|IP:213.186.127.*|WHEN:20120808
KILL|IP:95.108.249.29|WHEN:20101005
KILL|IP:89.216.16.104|WHEN:20101005|REASON:ignored-robotstxt

## CONTROLSCAN
KILL|IP:69.16.180.6
KILL|IP:69.16.180.10
KILL|IP:69.16.180.11
KILL|IP:69.16.180.12
KILL|IP:69.16.180.13
KILL|IP:69.16.180.14
KILL|IP:69.16.180.15
KILL|IP:69.16.180.16
KILL|IP:69.16.180.17
KILL|IP:69.16.180.18
KILL|IP:209.67.114.33
KILL|IP:209.67.114.34
KILL|IP:216.35.7.113
KILL|IP:216.35.7.105
KILL|IP:216.35.7.104
KILL|IP:216.35.7.102

## searchme.com - made a lot of connections to different sites,
## connections open for excessively long times.
MISS|IP:208.111.154.16
MISS|IP:208.111.154.15
MISS|IP:208.111.154.14
## FR-PROXAD-ADSL -- request every 2 seconds 11/18/08
KILL|IP:88.165.221.16
KILL|IP:66.161.95.
## Verizon 7/14/09 - santaferanch.com
#KILL|IP:71.101.47.83
## santaferanch.com
# 8/24/09 - keeps requesting the same page over and over again on beachmart. /product/FFWS7V2/null
MISS|IP:170.201.180.137
# 9/25/09
MISS|IP:91.214.45.89
# 9/30/09
KILL|IP:204.238.82.17
# 10/06/09
KILL|IP:91.214.44.121
KILL|IP:194.8.75.251
KILL|IP:77.88.30.247
KILL|IP:91.214.44.91
KILL|IP:173.80.202.144
KILL|IP:88.131.106.6
KILL|IP:91.214.44.2
# 7/29/10 - excesive requests to my.incipio.com
KILL|IP:12.41.229.41
KILL|IP:71.190.207.43
# 20100810 
KILL|IP:95.108.244.251
##
WATCH|IP:4.79.204.36
WATCH|IP:95.211.113.73
WATCH|IP:94.75.199.203


KILL|IP:212.113.35.162|WHEN:20100915|REASON:making 10+ requests per second
WATCH|IP:207.46.195.241|REASON:msn
WATCH|IP:63.150.152.126|REASON:buysafe
WATCH|IP:64.124.148.23|WHEN:20101105|REASON:robotstxt
KILL|IP:89.216.16.104|WHEN:20101105|REASON:ignored-robotstxt
WATCH|IP:209.51.162.220|WHEN:20101105|REASON:robotstxt
WATCH|IP:209.51.162.219|WHEN:20101105|REASON:robotstxt

KILL|IP:164.47.72.242 
KILL|IP:75.171.160.45
KILL|IP:174.30.131.196
KILL|IP:85.17.208.184
WATCH|IP:82.192.74.*
KILL|IP:82.192.93.215|WHEN:20110325|REASON:too many hits
WATCH|IP:209.51.153.38
WATCH|IP:67.195.115.166
WATCH|IP:208.115.111.247

## 20110302 - newsletter form spam on bamtar and chiquelife
KILL|IP:195.191.54.90

## 20110215 - did not request robots.txt spambot: http://www.forumpostersunion.com/showthread.php?t=16125
KILL|IP:174.127.132.*
KILL|IP:174.127.132.30
WATCH|IP:107.10.51.227|WHEN:20110206|SERVER:www.leatherfurniturecenter.com|REASON:robots.txt
WATCH|IP:107.10.51.227|WHEN:20110206|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:108.12.201.41|WHEN:20110219|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:108.12.201.41|WHEN:20110219|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:108.6.108.251|WHEN:20110206|SERVER:www.ibuybarbecues.com|REASON:robots.txt
WATCH|IP:109.169.48.119|WHEN:20110221|SERVER:www.austinbazaar.com|REASON:robots.txt
WATCH|IP:109.172.66.47|WHEN:20110216|SERVER:www.hillbillyknifesales.com|REASON:robots.txt
WATCH|IP:109.172.66.47|WHEN:20110217|SERVER:www.hillbillyknifesales.com|REASON:robots.txt
WATCH|IP:109.172.66.47|WHEN:20110219|SERVER:www.hillbillyknifesales.com|REASON:robots.txt
WATCH|IP:109.232.56.100|WHEN:20110214|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:109.60.11.22|WHEN:20110209|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:109.95.210.241|WHEN:20110205|SERVER:www.halebobstore.com|REASON:robots.txt
WATCH|IP:110.136.179.37|WHEN:20110203|SERVER:www.goshotcamera.com|REASON:robots.txt
WATCH|IP:110.137.218.70|WHEN:20110221|SERVER:www.redrive.net|REASON:robots.txt
WATCH|IP:110.138.189.141|WHEN:20110214|SERVER:www.luau-party-supplies.biz|REASON:robots.txt
WATCH|IP:110.138.48.129|WHEN:20110218|SERVER:www.2bhiphoodies.com|REASON:robots.txt
WATCH|IP:110.139.115.94|WHEN:20110221|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:110.175.40.218|WHEN:20110206|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:110.175.40.218|WHEN:20110207|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:110.175.40.218|WHEN:20110211|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:110.44.177.4|WHEN:20110202|SERVER:thewigclub.zoovy.com|REASON:robots.txt
WATCH|IP:110.75.164.*|WHEN:20110222
WATCH|IP:110.75.171.*|WHEN:20110222
WATCH|IP:110.75.172.*|WHEN:20110222
WATCH|IP:110.75.173.*|WHEN:20110222
WATCH|IP:110.75.174.*|WHEN:20110222
WATCH|IP:110.75.175.*|WHEN:20110222
WATCH|IP:110.75.176.*|WHEN:20110222
WATCH|IP:12.175.178.250|WHEN:20110201|SERVER:aaavacs.com|REASON:robots.txt
WATCH|IP:173.203.237.*|WHEN:20110218|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:174.142.104.57|WHEN:20110202|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:174.143.142.123|WHEN:20110202|SERVER:www.elegantbed.com|REASON:robots.txt
WATCH|IP:174.143.142.*|WHEN:20110202|SERVER:www.allvelvet.com|REASON:robots.txt
WATCH|IP:174.143.252.*|WHEN:20110209|SERVER:www.thecubanshop.com|REASON:robots.txt
WATCH|IP:174.143.253.*|WHEN:20110208|SERVER:www.crunruh.com|REASON:robots.txt
WATCH|IP:174.143.254.*|WHEN:20110201|SERVER:www.medicalfurniture-online.com|REASON:robots.txt
WATCH|IP:174.143.26.*|WHEN:20110201|SERVER:ssl.zoovy.com|REASON:robots.txt
WATCH|IP:190.223.91.*|WHEN:20110205|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:190.232.36.27|WHEN:20110207|SERVER:www.cbpots.com|REASON:robots.txt
WATCH|IP:190.232.41.27|WHEN:20110214|SERVER:www.perfectpjs.com|REASON:robots.txt
WATCH|IP:190.232.66.170|WHEN:20110204|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:190.236.117.29|WHEN:20110218|SERVER:www.blackhawksshop.com|REASON:robots.txt
WATCH|IP:190.236.35.104|WHEN:20110221|SERVER:www.hotsaucehawaii.com|REASON:robots.txt
WATCH|IP:190.236.35.21|WHEN:20110208|SERVER:www.ahlersgifts.com|REASON:robots.txt
WATCH|IP:190.41.100.95|WHEN:20110210|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:190.43.104.152|WHEN:20110210|SERVER:www.decor411.com|REASON:robots.txt
WATCH|IP:190.43.105.60|WHEN:20110210|SERVER:www.mysticwholesale.com|REASON:robots.txt
WATCH|IP:190.43.224.200|WHEN:20110204|SERVER:www.warehousedirectusa.com|REASON:robots.txt
WATCH|IP:190.43.224.240|WHEN:20110208|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:190.43.29.235|WHEN:20110204|SERVER:www.glamour-grams.com|REASON:robots.txt
WATCH|IP:190.43.33.221|WHEN:20110203|SERVER:www.greatweddingz.com|REASON:robots.txt
WATCH|IP:190.43.56.75|WHEN:20110217|SERVER:www.arcohost.com|REASON:robots.txt
WATCH|IP:190.43.56.75|WHEN:20110217|SERVER:www.logfurnituresite.com|REASON:robots.txt
WATCH|IP:190.43.71.38|WHEN:20110210|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:190.43.74.4|WHEN:20110211|SERVER:www.honeybabee.com|REASON:robots.txt
WATCH|IP:190.43.74.4|WHEN:20110211|SERVER:www.oldcookbooks.com|REASON:robots.txt
WATCH|IP:190.43.74.4|WHEN:20110212|SERVER:www.yuppygift.com|REASON:robots.txt
WATCH|IP:190.43.74.4|WHEN:20110214|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:190.43.74.4|WHEN:20110214|SERVER:www.ibuychairs.com|REASON:robots.txt
WATCH|IP:190.43.74.4|WHEN:20110214|SERVER:www.modernmobilegallery.com|REASON:robots.txt
WATCH|IP:190.43.74.4|WHEN:20110214|SERVER:www.robdiamond.net|REASON:robots.txt
WATCH|IP:190.43.74.4|WHEN:20110215|SERVER:www.leatherfurniturecenter.com|REASON:robots.txt
WATCH|IP:190.43.74.87|WHEN:20110216|SERVER:www.modernmini.com|REASON:robots.txt
WATCH|IP:190.43.97.221|WHEN:20110203|SERVER:www.chiquelife.com|REASON:robots.txt
WATCH|IP:190.43.97.221|WHEN:20110203|SERVER:www.chique-plus.com|REASON:robots.txt
WATCH|IP:190.43.97.221|WHEN:20110203|SERVER:www.tooltaker.com|REASON:robots.txt
WATCH|IP:190.55.102.33|WHEN:20110215|SERVER:sopundmart.zoovy.com|REASON:robots.txt
WATCH|IP:190.55.102.33|WHEN:20110215|SERVER:soundmart.zoovy.com|REASON:robots.txt
WATCH|IP:190.81.226.78|WHEN:20110209|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:190.81.226.78|WHEN:20110217|SERVER:www.hcgdietcure.com|REASON:robots.txt
WATCH|IP:190.81.226.78|WHEN:20110219|SERVER:espressoparts2.zoovy.com|REASON:robots.txt
WATCH|IP:190.81.226.78|WHEN:20110220|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:192.1.249.137|WHEN:20110204|SERVER:www.warehousedirectusa.com|REASON:robots.txt
WATCH|IP:192.1.249.137|WHEN:20110205|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110201|SERVER:www.cuttingboardsltd.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110202|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110202|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110205|SERVER:www.pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110206|SERVER:www.mosaictile.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110207|SERVER:gooddeals18.zoovy.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110207|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110214|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110214|SERVER:www.clicktoshop.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110214|SERVER:www.clicktoshopllc.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110214|SERVER:www.cupidmusicstore.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110214|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110214|SERVER:www.oktoberfesthaus.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110214|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:192.35.222.230|WHEN:20110222|SERVER:www.hitchcovers.com|REASON:robots.txt
WATCH|IP:192.41.40.175|WHEN:20110216|SERVER:www.myhotshoes.com|REASON:robots.txt
WATCH|IP:193.151.115.14|WHEN:20110212|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:193.169.86.35|WHEN:20110222|SERVER:stage3motorsports.com|REASON:robots.txt
WATCH|IP:193.169.86.35|WHEN:20110222|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:193.29.76.36|WHEN:20110217|SERVER:www.gss-store.com|REASON:robots.txt
WATCH|IP:193.29.76.36|WHEN:20110217|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:193.73.251.4|WHEN:20110210|SERVER:www.furniture-online.com|REASON:robots.txt

WATCH|IP:194.110.211.*|WHEN:20110202|SERVER:handsnpaws.zoovy.com|REASON:robots.txt
WATCH|IP:194.24.174.4|WHEN:20110202|SERVER:summitfashions.com|REASON:robots.txt
WATCH|IP:194.24.174.4|WHEN:20110202|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:194.29.178.13|WHEN:20110216|SERVER:www.beltsandmore.com|REASON:robots.txt
WATCH|IP:194.46.166.48|WHEN:20110215|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:195.112.238.35|WHEN:20110202|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:195.132.137.56|WHEN:20110213|SERVER:berniessmellsnbells.com|REASON:robots.txt
WATCH|IP:195.132.137.56|WHEN:20110213|SERVER:www.berniessmellsnbells.com|REASON:robots.txt
WATCH|IP:195.132.137.56|WHEN:20110220|SERVER:crunruh.zoovy.com|REASON:robots.txt
WATCH|IP:199.15.29.49|WHEN:20110208|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:199.46.199.231|WHEN:20110215|SERVER:gunnersalley.zoovy.com|REASON:robots.txt
WATCH|IP:201.240.43.36|WHEN:20110207|SERVER:www.beach-signs.com|REASON:robots.txt
WATCH|IP:201.240.44.225|WHEN:20110220|SERVER:www.espressoparts2.zoovy.com|REASON:robots.txt
WATCH|IP:201.240.49.112|WHEN:20110213|SERVER:www.kalamkaripaintings.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110203|SERVER:m.doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110203|SERVER:m.furthurstore.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110203|SERVER:m.gkworld.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110203|SERVER:m.greatglovesonline.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110203|SERVER:m.tikimaster.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110203|SERVER:m.worldseriescubs.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110203|SERVER:m.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110203|SERVER:m.zephyrsports.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110203|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110216|SERVER:m.barefoottess.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110216|SERVER:m.bbkingstore.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110216|SERVER:m.blackhawksshop.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110216|SERVER:m.furthurstore.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110216|SERVER:m.gkworld.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110216|SERVER:m.greatglovesonline.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110216|SERVER:m.kyledesigns.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110216|SERVER:m.tikimaster.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110216|SERVER:m.toynk.com|REASON:robots.txt
WATCH|IP:203.131.253.72|WHEN:20110216|SERVER:m.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:203.131.253.75|WHEN:20110202|SERVER:m.redfordfilms.com|REASON:robots.txt
WATCH|IP:203.131.253.75|WHEN:20110216|SERVER:m.redfordfilms.com|REASON:robots.txt
WATCH|IP:203.218.207.122|WHEN:20110219|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:203.30.39.238|WHEN:20110214|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:203.45.244.248|WHEN:20110215|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:203.82.87.64|WHEN:20110206|SERVER:www.elegantbed.com|REASON:robots.txt
WATCH|IP:204.13.200.8|WHEN:20110210|SERVER:surfcitymusic.com|REASON:robots.txt
WATCH|IP:204.13.200.8|WHEN:20110210|SERVER:www.surfcitymusic.com|REASON:robots.txt
WATCH|IP:204.13.200.8|WHEN:20110211|SERVER:leedway.com|REASON:robots.txt
WATCH|IP:204.13.200.8|WHEN:20110211|SERVER:www.leedway.com|REASON:robots.txt
WATCH|IP:204.15.129.18|WHEN:20110212|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:204.236.214.97|WHEN:20110210|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110209|SERVER:homebrewers.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110209|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:bierboothaus.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:birdhousesltd.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:clicktoshopllc.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:garmentracksltd.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:oktoberfesthaus.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:pushreelmowers.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:www.birdhousesltd.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:www.clicktoshopllc.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:www.garmentracksltd.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:www.oktoberfesthaus.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110217|SERVER:www.pushreelmowers.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110218|SERVER:garmentracksltd.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110218|SERVER:pushreelmowers.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110218|SERVER:www.garmentracksltd.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110218|SERVER:www.pushreelmowers.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110219|SERVER:garmentracksltd.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110219|SERVER:pushreelmowers.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110219|SERVER:www.garmentracksltd.com|REASON:robots.txt
WATCH|IP:204.236.225.207|WHEN:20110219|SERVER:www.pushreelmowers.com|REASON:robots.txt
WATCH|IP:204.238.82.23|WHEN:20110208|SERVER:www.europottery.com|REASON:robots.txt
WATCH|IP:204.238.82.23|WHEN:20110219|SERVER:www.ticodecorations.com|REASON:robots.txt
WATCH|IP:204.238.82.30|WHEN:20110218|SERVER:froggysfog.com|REASON:robots.txt
WATCH|IP:204.45.64.253|WHEN:20110202|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110201|SERVER:dabearsgear.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110201|SERVER:poshuniforms.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110201|SERVER:protoloader.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110201|SERVER:www.chitownfootball.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110201|SERVER:www.dabeargear.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110201|SERVER:www.dabearsgear.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110201|SERVER:www.poshuniforms.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110201|SERVER:www.protoloader.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110201|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110202|SERVER:arjanusa.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110202|SERVER:warehousehawaii.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110202|SERVER:www.arjanusa.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110202|SERVER:www.hayspear.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110202|SERVER:www.specialtyfoodshawaii.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110202|SERVER:www.warehousehawaii.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110203|SERVER:berniessmellsnbells.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110203|SERVER:www.berniessmellsnbells.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110204|SERVER:broadwaybuffer.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110204|SERVER:cbpots.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110204|SERVER:www.broadwaybuffer.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110204|SERVER:www.cbpots.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110205|SERVER:domainname.us.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110205|SERVER:fairwaymarketingaz.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110205|SERVER:fancyboy.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110205|SERVER:filewhat.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110205|SERVER:fryup.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110205|SERVER:www.domainname.us.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110205|SERVER:www.fairwaymarketingaz.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110205|SERVER:www.fancyboy.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110205|SERVER:www.filewhat.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110205|SERVER:www.fryup.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:gloveuse.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:gobriefs.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:go-goods.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:herballovepotions.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:infectioncontrol.us|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:www.gloveuse.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:www.gobriefs.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:www.go-goods.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:www.herballovepotions.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:www.infectioncontrol.us|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110206|SERVER:www.zasde.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110208|SERVER:lechartreuse.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110208|SERVER:www.lechartreuse.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110209|SERVER:aboutgloves.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110209|SERVER:alloceansports.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110209|SERVER:qcollectionjunior.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110209|SERVER:www.aboutgloves.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110209|SERVER:www.alloceansports.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110209|SERVER:www.qcollectionjunior.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110210|SERVER:rockdown.com|REASON:robots.txt
WATCH|IP:205.178.190.234|WHEN:20110210|SERVER:www.rockdown.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110201|SERVER:onlineformals.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110201|SERVER:rotorhopper.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110201|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110201|SERVER:www.rotorhopper.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110203|SERVER:beltsandmore.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110203|SERVER:www.beltsandmore.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110204|SERVER:bostonbriefs.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110204|SERVER:bostongloves.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110204|SERVER:boyceimage.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110204|SERVER:broadwayshoebuffer.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110204|SERVER:buystonesonline.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110204|SERVER:www.bostonbriefs.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110204|SERVER:www.bostongloves.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110204|SERVER:www.boyceimage.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110204|SERVER:www.broadwayshoebuffer.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110204|SERVER:www.buystonesonline.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110205|SERVER:emiser.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110205|SERVER:ez-boston.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110205|SERVER:ghostinc.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110205|SERVER:www.emiser.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110205|SERVER:www.ez-boston.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110205|SERVER:www.ghostinc.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:gogoods.info|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:go-goods.net|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:gogoods.org|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:gogoods.tv|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:igoods.us|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:instantcoldcompresses.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:itascamoccasin.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:www.gogoods.info|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:www.go-goods.net|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:www.gogoods.org|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:www.gogoods.tv|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:www.igoods.us|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:www.instantcoldcompresses.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110206|SERVER:www.itascamoccasin.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110208|SERVER:lessmessy.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110208|SERVER:www.lessmessy.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110209|SERVER:pdpprinting.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110209|SERVER:poshuniforms.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110209|SERVER:pothia.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110209|SERVER:raku-art.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110209|SERVER:www.pdpprinting.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110209|SERVER:www.poshuniforms.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110209|SERVER:www.pothia.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110209|SERVER:www.raku-art.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110210|SERVER:rapid-direction.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110210|SERVER:www.rapid-direction.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110218|SERVER:gourmetfoodshawaii.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110218|SERVER:michaelscookies.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110218|SERVER:shirtsforbikers.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110218|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110218|SERVER:www.gourmetfoodshawaii.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110218|SERVER:www.michaelscookies.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110218|SERVER:www.shirtsforbikers.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110218|SERVER:www.specialtyfoodshawaii.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110219|SERVER:barefoottess.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110219|SERVER:thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110219|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110219|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110220|SERVER:lennovator.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110220|SERVER:www.lennovator.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110221|SERVER:bwbits.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110221|SERVER:daceenterprises.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110221|SERVER:teenlookz.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110221|SERVER:www.bwbits.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110221|SERVER:www.daceenterprises.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110221|SERVER:www.greatshopz.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110221|SERVER:www.hayspear.com|REASON:robots.txt
WATCH|IP:205.178.190.235|WHEN:20110221|SERVER:www.teenlookz.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110201|SERVER:www.yuppygift.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110201|SERVER:yuppygift.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110202|SERVER:amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110202|SERVER:www.amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110203|SERVER:atozgift.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110203|SERVER:barefoottess.co.uk|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110203|SERVER:www.atozgift.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110203|SERVER:www.barefoottess.co.uk|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:bigoutlet.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:bostonmedical.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:brascheap.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:caraccessoryguy.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:collectors-outpost.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:comfortexusa.zoovy.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:www.bostonmedical.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:www.brascheap.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:www.caraccessoryguy.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110204|SERVER:www.collectors-outpost.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110205|SERVER:daceenterprises.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110205|SERVER:easymiser.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110205|SERVER:finalegloves.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110205|SERVER:futonbedplanet.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110205|SERVER:www.daceenterprises.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110205|SERVER:www.easymiser.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110205|SERVER:www.finalegloves.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110205|SERVER:www.futonbedplanet.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:glovesboston.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:gogoods.mobi|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:gogoods.us|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:googoods.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:guardsgloves.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:hdesk.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:www.glovesboston.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:www.gogoods.mobi|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:www.gogoods.us|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:www.googoods.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:www.guardsgloves.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110206|SERVER:www.hdesk.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110207|SERVER:www.beltsandmore.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:lilslavender.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:luggage4less.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:luggage4less.net|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:palapa.bz|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:pond4u.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:pony-espresso.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:www.lilslavender.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:www.luggage4less.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:www.luggage4less.net|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:www.palapa.bz|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:www.pond4u.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110209|SERVER:www.pony-espresso.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110210|SERVER:redfordfilms.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110210|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:consumeraudiovideo.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:mensshirtshop.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:speedaddictcycles.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:summitfashions.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:traditionalbowhunterstuff.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:www.consumeraudiovideo.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:www.hayspear.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:www.mensshirtshop.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:www.speedaddictcycles.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110218|SERVER:www.traditionalbowhunterstuff.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:2bhipmens.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:2bhiptees.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:cipherstyles.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:www.2bhip.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:www.2bhipmens.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:www.2bhiptees.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:www.2bhiptshirts.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:www.cipherstyles.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:www.zephyrairsoft.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:www.zypherairsoft.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110219|SERVER:zypherairsoft.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110220|SERVER:germanpyramids.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110220|SERVER:marcelhomedecor.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110220|SERVER:rosiquewedding.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110220|SERVER:spitsadventureeyewear.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110220|SERVER:www.germanpyramids.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110220|SERVER:www.marcelhomedecor.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110220|SERVER:www.rosiquewedding.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110220|SERVER:www.spitsadventureeyewear.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110220|SERVER:www.spitsadventurewear.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110221|SERVER:edwinjzoovy.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110221|SERVER:greatteenz.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110221|SERVER:www.edwinjzoovy.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110221|SERVER:www.greatshopz.com|REASON:robots.txt
WATCH|IP:205.178.190.236|WHEN:20110221|SERVER:www.greatteenz.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110201|SERVER:nexbaytel.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110201|SERVER:www.nexbaytel.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110203|SERVER:atozgiftswholesale.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110203|SERVER:azuzu.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110203|SERVER:www.atozgiftswholesale.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110203|SERVER:www.azuzu.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110204|SERVER:brettsluggage.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110204|SERVER:cardiacwellness.biz|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110204|SERVER:computercarecenters.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110204|SERVER:www.brettsluggage.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110204|SERVER:www.cardiacwellness.biz|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110204|SERVER:www.cardiacwellness.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110204|SERVER:www.computercarecenters.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:decoratingwithlace.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:ebestsource.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:ezboston.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:fenko.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:finodisc.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:ggood.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:www.ebestsource.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:www.ezboston.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:www.fenko.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:www.finodisc.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:www.ggood.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110205|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:gloveuses.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:go-goods.us|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:gooddeals18.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:hausfortuna.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:hummeraccessoryguy.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:igoods.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:instantcoldcompress.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:www.gloveuses.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:www.go-goods.us|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:www.hausfortuna.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:www.hummeraccessoryguy.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:www.igoods.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110206|SERVER:www.instantcoldcompress.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:888knivesrus.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:allpetsolutions.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:americanguitarandband.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:mapshift.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:oworlds.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:precisiondataproducts.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:racing4sports.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:www.americanguitarandband.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:www.mapshift.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:www.oworlds.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:www.precisiondataproducts.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110209|SERVER:www.racing4sports.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110210|SERVER:reptiles4u.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110210|SERVER:rhythmfusion.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110210|SERVER:www.reptiles4u.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110210|SERVER:www.rhythmfusion.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110218|SERVER:geckocircuitboards.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110218|SERVER:myzoovy.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110218|SERVER:usavem.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110218|SERVER:www.geckocircuitboards.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110218|SERVER:www.myzoovy.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110218|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:2behip.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:cobrastitch.zoovy.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:dasbootglass.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:expeditionimports.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:oldscyene.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:www.2behip.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:www.2bhip.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:www.dasbootglass.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:www.expedition-imports.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:www.expeditionimports.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:www.oldscyene.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:www.zephersports.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:www.zephyrbackpacks.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:zephersports.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110219|SERVER:zephyrbackpacks.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110220|SERVER:aquaflopumps.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110220|SERVER:gerber-multi-tools.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110220|SERVER:secondactdeals.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110220|SERVER:www.aquaflopumps.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110220|SERVER:www.gerber-multi-tools.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110220|SERVER:www.secondactdeals.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110220|SERVER:www.spapartsdepot.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110221|SERVER:coastaldecoration.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110221|SERVER:dreamwaytrading.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110221|SERVER:dvaultsecuritymailboxes.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110221|SERVER:shoecoversonline.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110221|SERVER:www.coastaldecoration.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110221|SERVER:www.dreamwaytrading.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110221|SERVER:www.dvaultlockingmailbox.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110221|SERVER:www.dvaultsecuritymailboxes.com|REASON:robots.txt
WATCH|IP:205.178.190.237|WHEN:20110221|SERVER:www.shoecoversonline.com|REASON:robots.txt
WATCH|IP:205.248.101.85|WHEN:20110206|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:205.248.101.85|WHEN:20110207|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110202|SERVER:www.avatarcostumes.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110203|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110203|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110203|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110203|SERVER:www.leatherfurniturecenter.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110204|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110208|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110209|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110209|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110209|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110210|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110210|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110211|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110211|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110213|SERVER:www.dollhousesandmore.com|REASON:robots.txt
WATCH|IP:205.251.130.149|WHEN:20110213|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:206.113.193.50|WHEN:20110212|SERVER:www.dollhousesandmore.com|REASON:robots.txt
WATCH|IP:206.113.193.50|WHEN:20110212|SERVER:www.faeriegodmother.net|REASON:robots.txt
WATCH|IP:206.113.193.50|WHEN:20110212|SERVER:www.zephyrskateboards.com|REASON:robots.txt
WATCH|IP:206.113.193.50|WHEN:20110213|SERVER:beechmontporsche.zoovy.com|REASON:robots.txt
WATCH|IP:206.113.193.50|WHEN:20110213|SERVER:www.outofthetoybox.com|REASON:robots.txt
WATCH|IP:206.113.193.50|WHEN:20110213|SERVER:www.zephyrskateboards.com|REASON:robots.txt
WATCH|IP:206.255.1.121|WHEN:20110211|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:206.51.192.103|WHEN:20110211|SERVER:www.affordablechristianproducts.com|REASON:robots.txt
WATCH|IP:206.51.192.103|WHEN:20110212|SERVER:www.affordablechristianproducts.com|REASON:robots.txt
WATCH|IP:207.13.114.3|WHEN:20110218|SERVER:www.softnerparts.com|REASON:robots.txt
WATCH|IP:207.140.148.33|WHEN:20110221|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:207.140.148.33|WHEN:20110221|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:207.140.148.33|WHEN:20110221|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:207.140.148.33|WHEN:20110221|SERVER:www.greatshopz.com|REASON:robots.txt
WATCH|IP:207.140.148.33|WHEN:20110221|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:207.140.148.33|WHEN:20110221|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:207.140.148.33|WHEN:20110221|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:207.140.148.33|WHEN:20110222|SERVER:redfordfilms.com|REASON:robots.txt
WATCH|IP:207.140.148.33|WHEN:20110222|SERVER:ssl.zoovy.com|REASON:robots.txt
WATCH|IP:207.46.119.86|WHEN:20110201|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:207.46.119.86|WHEN:20110212|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:207.67.117.170|WHEN:20110212|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:207.67.117.170|WHEN:20110212|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:207.67.117.170|WHEN:20110213|SERVER:www.coralandjadeapparel.com|REASON:robots.txt
WATCH|IP:207.67.117.170|WHEN:20110215|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:207.67.117.170|WHEN:20110215|SERVER:www.pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:207.67.117.172|WHEN:20110207|SERVER:www.equinefashionandtack.com|REASON:robots.txt
WATCH|IP:207.67.117.172|WHEN:20110207|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:207.67.117.172|WHEN:20110210|SERVER:www.2bhiptshirts.com|REASON:robots.txt
WATCH|IP:207.67.117.172|WHEN:20110210|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:207.67.117.172|WHEN:20110210|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:207.67.117.172|WHEN:20110211|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:207.67.117.172|WHEN:20110214|SERVER:www.equinefashionandtack.com|REASON:robots.txt
WATCH|IP:207.67.117.173|WHEN:20110207|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:207.67.117.173|WHEN:20110207|SERVER:www.thespringstandardsstore.com|REASON:robots.txt
WATCH|IP:207.67.117.178|WHEN:20110216|SERVER:www.oldcookbooks.com|REASON:robots.txt
WATCH|IP:207.67.117.178|WHEN:20110217|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:207.67.117.178|WHEN:20110217|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:207.67.117.178|WHEN:20110218|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:207.67.117.178|WHEN:20110218|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:207.98.180.14|WHEN:20110207|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:208.185.214.4|WHEN:20110210|SERVER:www.gsa-marine.com|REASON:robots.txt
WATCH|IP:208.185.214.4|WHEN:20110217|SERVER:www.gsa-marine.com|REASON:robots.txt
WATCH|IP:208.68.0.2|WHEN:20110209|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:208.77.99.95|WHEN:20110204|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:208.77.99.95|WHEN:20110205|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:208.77.99.95|WHEN:20110207|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:208.77.99.95|WHEN:20110211|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:208.77.99.95|WHEN:20110212|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:208.77.99.95|WHEN:20110214|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:208.77.99.95|WHEN:20110221|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:208.92.218.168|WHEN:20110203|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:208.92.218.168|WHEN:20110205|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:208.94.63.194|WHEN:20110211|SERVER:www.thecandlemakersstore.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110207|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110207|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110208|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110210|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110210|SERVER:www.cbpots.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110211|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110212|SERVER:barefoottess.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110212|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110212|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110212|SERVER:www.ibuywoodstoves.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110212|SERVER:www.kc4d.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110212|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110212|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110215|SERVER:gunnersalley.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110217|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110217|SERVER:www.rapid-direction.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110218|SERVER:m.doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110218|SERVER:sassyassybjeans.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110218|SERVER:tattooapparel.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110218|SERVER:www.ibuybarbeques.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110218|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110219|SERVER:www.ibuyautomation.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110219|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.107|WHEN:20110219|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110205|SERVER:bedplanet.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110205|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110205|SERVER:www.purewaveaudio.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110207|SERVER:doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110207|SERVER:www.doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110208|SERVER:jaredcampbellstore.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110208|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110208|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110208|SERVER:www.covisec.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110208|SERVER:www.hotsaucehawaii.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110208|SERVER:www.ibuylumaxlighting.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110208|SERVER:www.ibuywoodstoves.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110208|SERVER:www.jaredcampbellstore.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110208|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110209|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110211|SERVER:handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110211|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110211|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:aaavacs.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:www.aaavacs.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:www.coastaldecoration.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:www.denimsquare.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:www.getfoundgps.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:www.sewkool.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110212|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110213|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110215|SERVER:sundaycolors.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110217|SERVER:bbkingstore.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110217|SERVER:toolprice.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110217|SERVER:toonstation.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110217|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110217|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110217|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110217|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110217|SERVER:www.travistrittstore.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110218|SERVER:boyceimage.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110218|SERVER:www.boyceimage.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110218|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110218|SERVER:www.sillybandzone.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110218|SERVER:www.silver-seal.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110219|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110219|SERVER:www.doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110219|SERVER:www.furniture-online.com|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110219|SERVER:www.mainlanders.org|REASON:robots.txt
WATCH|IP:209.114.36.114|WHEN:20110219|SERVER:www.pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110205|SERVER:www.elegantbed.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110205|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110205|SERVER:www.ironstoneimports.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110205|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110206|SERVER:handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110206|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110207|SERVER:m.tikimaster.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110207|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110207|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110207|SERVER:www.elegantbed.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110207|SERVER:www.kbtdirect.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110207|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110208|SERVER:handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110208|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110211|SERVER:www.accentdesks.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110211|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110211|SERVER:www.fleurdelisdirect.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110211|SERVER:www.orleansgiftshop.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110212|SERVER:www.alohamaster.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110212|SERVER:www.glassartheaven.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110212|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110212|SERVER:www.perfectpjs.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110215|SERVER:www.ibuymonessenfireplaces.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110215|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110217|SERVER:www.halebobstore.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110217|SERVER:www.irresistables.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110217|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110217|SERVER:www.shophalebob.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110217|SERVER:www.silver-seal.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110217|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110218|SERVER:shopitalian.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.116|WHEN:20110219|SERVER:www.wirelessvideocameras.net|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110205|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110205|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110206|SERVER:www.alohamaster.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110206|SERVER:www.amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110206|SERVER:www.caboots.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110206|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110206|SERVER:www.fleurdelisdirect.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110206|SERVER:www.ibuymaximlighting.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110206|SERVER:www.ibuymonessenfireplaces.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110207|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110207|SERVER:www.fleurdelisdirect.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110207|SERVER:www.ibuyinductionlighting.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110207|SERVER:www.ibuylights.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110207|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110208|SERVER:barefoottess.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110208|SERVER:www.accentdesks.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110208|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110208|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110208|SERVER:www.orleansgiftshop.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110209|SERVER:sassyassyb.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110211|SERVER:mpodesigns.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110211|SERVER:www.benchexperts.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110211|SERVER:www.cmamusicfeststore.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110211|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110211|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110212|SERVER:sharperconcepts.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110212|SERVER:stopdirt.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110212|SERVER:www.coastaldecoration.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110212|SERVER:www.evocstore.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110212|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110212|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110212|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110213|SERVER:greatlookz.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110215|SERVER:www.blitzinc.net|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110215|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110215|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110217|SERVER:loblolly.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110217|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110217|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110217|SERVER:www.pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110217|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110217|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110218|SERVER:sundaycolors.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110218|SERVER:www.accentchairselect.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110218|SERVER:www.capaper.com|REASON:robots.txt
WATCH|IP:209.114.36.118|WHEN:20110218|SERVER:www.outofthetoybox.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110207|SERVER:barefoottess.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110207|SERVER:m.gooddeals18.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110207|SERVER:www.alohamaster.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110207|SERVER:www.amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110207|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110207|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110207|SERVER:www.caboots.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110207|SERVER:www.ibuymaximlighting.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110207|SERVER:www.ibuymonessenfireplaces.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110208|SERVER:www.alohamaster.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110208|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110208|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110208|SERVER:www.lampeavenueonline.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110208|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110208|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110211|SERVER:www.prostreetlighting.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:aaavacs.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:gunnersalley.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:handsnpaws.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:www.aaavacs.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:www.boyceimage.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:www.carmobilevideo.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:www.decor411.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:www.silver-seal.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:www.speedaddictcycles.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110212|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110215|SERVER:www.pocketwatcher.org|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110215|SERVER:www.pocketwatcher.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110215|SERVER:www.purewaveaudio.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110216|SERVER:www.towguards.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110217|SERVER:mugheaven.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110217|SERVER:pawstogo.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110217|SERVER:sassyassyjeans.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110217|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110217|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110217|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110217|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110217|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110218|SERVER:nctoybox.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110218|SERVER:shopitalianwholesale.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110218|SERVER:www.ibuyautomation.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110218|SERVER:www.ibuypottery.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110218|SERVER:www.ratdogstore.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110218|SERVER:www.selectjewelryarmoires.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110218|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:209.114.36.120|WHEN:20110219|SERVER:www.partybrights.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110205|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110205|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110205|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110205|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110206|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110206|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110207|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110207|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110208|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110208|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110208|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110211|SERVER:doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110211|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110211|SERVER:www.doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110212|SERVER:babology.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110212|SERVER:barefoottess.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110212|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110212|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110212|SERVER:www.employeedevsys.theperformancereportwebstore.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110212|SERVER:www.homeaccentexperts.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110212|SERVER:www.kidscraftsplus.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110212|SERVER:www.oktoberfesthaus.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110212|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110215|SERVER:toolprice.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110215|SERVER:www.moreclocks.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110215|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110216|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110216|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110217|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110217|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110217|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110217|SERVER:www.ibuynapoleonfireplaces.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110217|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110218|SERVER:www.beachboysstore.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110218|SERVER:www.ecobottoms.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110218|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110218|SERVER:www.rob-diamond.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110219|SERVER:cubworld.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110219|SERVER:m.jamesmaddockstore.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110219|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110219|SERVER:www.bandanacool.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110219|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110219|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:209.114.36.121|WHEN:20110219|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110205|SERVER:www.carvingemporium.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110205|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110205|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110206|SERVER:barefoottess.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110206|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110208|SERVER:barefoottess.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110208|SERVER:mugheaven.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110208|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110208|SERVER:www.buddyguystore.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110208|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110209|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110210|SERVER:www.irresistables.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110211|SERVER:loblolly.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110212|SERVER:bedplanet.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110212|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110212|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110212|SERVER:www.designed2bsweet.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110212|SERVER:www.glassartheaven.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110212|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110212|SERVER:www.islandbathnbody.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110212|SERVER:www.thegiftmallonline.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110215|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110215|SERVER:www.kidsbargains.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110215|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110216|SERVER:bbkingstore.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110216|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110217|SERVER:elegantbed.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110217|SERVER:klatchroasting.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110217|SERVER:saucebossstore.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110217|SERVER:www.atlantapridestore.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110217|SERVER:www.elegantbed.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110217|SERVER:www.ibuyledlightbulbs.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110217|SERVER:www.saucebossstore.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:caboots.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:www.coastaldecoration.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:www.greatshopz.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:www.greatteenz.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:www.ibuydecorations.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:www.robdiamond.net|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110218|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:209.114.36.122|WHEN:20110219|SERVER:www.daceenterprises.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110205|SERVER:www.irresistables.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110205|SERVER:www.surfingmaster.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110206|SERVER:m.tikimaster.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110206|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110206|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110206|SERVER:www.kbtdirect.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110206|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110207|SERVER:handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110207|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110207|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110207|SERVER:www.lampeavenueonline.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110207|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110207|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110208|SERVER:loblolly.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110208|SERVER:www.ibuylights.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110212|SERVER:affordableproducts.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110212|SERVER:www.affordablechristianproducts.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110212|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110212|SERVER:www.redrive.net|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110213|SERVER:www.islandbathnbody.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110216|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110217|SERVER:mpodesigns.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110217|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110217|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110217|SERVER:www.finalegloves.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110217|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110218|SERVER:gooddeals18.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110218|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110218|SERVER:www.craftersnet.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110218|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110218|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110218|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110219|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:209.114.36.123|WHEN:20110219|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110205|SERVER:www.qcollectionjunior.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110206|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110207|SERVER:www.ticodecorations.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110208|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110208|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110208|SERVER:www.fleurdelisdirect.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110210|SERVER:www.atlanticgolfshop.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110210|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110210|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110211|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:toolprice.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.designed2bsweet.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.heavydutymats.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.ibuyinductionlighting.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.moreclocks.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.orleanscandles.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.orleansgiftshop.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110212|SERVER:www.tyler-candles.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110215|SERVER:www.homeaccentexperts.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110216|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110217|SERVER:m.totalfanshop.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110217|SERVER:www.denimsquare.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110217|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110217|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110217|SERVER:www.ronniemilsapstore.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110218|SERVER:albertcummingsstore.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110218|SERVER:www.albertcummingsstore.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110218|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110218|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110218|SERVER:www.needtobreathestore.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110218|SERVER:www.planetrenadirect.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110219|SERVER:www.dollhousesandmore.com|REASON:robots.txt
WATCH|IP:209.114.36.124|WHEN:20110219|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:209.114.36.127|WHEN:20110206|SERVER:loblolly.zoovy.com|REASON:robots.txt
WATCH|IP:209.114.36.127|WHEN:20110207|SERVER:loblolly.zoovy.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110205|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110205|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110205|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110205|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110205|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110206|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110206|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110206|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110206|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110208|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110210|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110211|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110212|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110212|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110212|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110212|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110213|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110213|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110213|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110213|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110214|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110215|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110216|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110217|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110219|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110219|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110219|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110220|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110220|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110220|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:209.116.42.194|WHEN:20110221|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:209.151.140.15|WHEN:20110216|SERVER:www.teacupgallery.com|REASON:robots.txt
WATCH|IP:209.191.82.246|WHEN:20110213|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:209.191.82.246|WHEN:20110214|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:209.249.53.37|WHEN:20110214|SERVER:beechmontporsche.zoovy.com|REASON:robots.txt
WATCH|IP:210.245.93.8|WHEN:20110216|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:210.245.93.8|WHEN:20110216|SERVER:zephyrsports.com|REASON:robots.txt
WATCH|IP:211.14.8.240|WHEN:20110201|SERVER:www.dianayvonne.com|REASON:robots.txt
WATCH|IP:211.14.8.240|WHEN:20110203|SERVER:dollssoreal.zoovy.com|REASON:robots.txt
WATCH|IP:211.14.8.240|WHEN:20110208|SERVER:liquidfashions.net|REASON:robots.txt
WATCH|IP:212.118.146.226|WHEN:20110206|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:212.125.24.158|WHEN:20110217|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:212.145.57.191|WHEN:20110215|SERVER:kidsafeinc.com|REASON:robots.txt
WATCH|IP:212.145.57.191|WHEN:20110215|SERVER:summitfashions.com|REASON:robots.txt
WATCH|IP:212.16.139.41|WHEN:20110220|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:212.227.97.253|WHEN:20110216|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110204|SERVER:888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110204|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110208|SERVER:888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110208|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110211|SERVER:888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110211|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110214|SERVER:888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110214|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110217|SERVER:888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110217|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110220|SERVER:888knivesrus.com|REASON:robots.txt
WATCH|IP:212.77.100.47|WHEN:20110220|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:212.85.183.38|WHEN:20110219|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:212.9.104.155|WHEN:20110208|SERVER:www.pimpinshoes.com|REASON:robots.txt
WATCH|IP:212.92.240.251|WHEN:20110212|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110201|SERVER:www.muzzleloadingstuff.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110201|SERVER:www.stolenpurse.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110202|SERVER:muzzleloadingstuff.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110202|SERVER:www.treestandstuff.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110203|SERVER:www.greenstreamwireless.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110203|SERVER:www.realguitaroutlet.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110204|SERVER:www.gss-store.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110204|SERVER:www.realguitaroutlet.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110205|SERVER:www.buildbikes.net|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110205|SERVER:www.realguitaroutlet.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110205|SERVER:www.tolotoysonline.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110205|SERVER:www.treestandstuff.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110206|SERVER:www.gss-store.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110206|SERVER:www.merrychristmasstuff.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110207|SERVER:bobbimailbox.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110207|SERVER:cypherstyle.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110207|SERVER:dodgerworld.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110207|SERVER:dvds4djs.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110207|SERVER:gloves-wedding.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110207|SERVER:laartworks.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110207|SERVER:www.realguitaroutlet.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110208|SERVER:www.buildbikes.net|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110208|SERVER:www.muzzleloadingstuff.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110208|SERVER:www.realguitaroutlet.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110208|SERVER:www.stolenpurse.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110209|SERVER:livehiphop.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110209|SERVER:pinnaclelockingmailboxes.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110210|SERVER:greatwholesales.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110210|SERVER:www.merrychristmasstuff.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110211|SERVER:www.buildbikes.net|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110211|SERVER:www.tolotoysonline.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110212|SERVER:aaa-broadwayvacuums.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110213|SERVER:pro-safetysupplies.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110213|SERVER:purewaverestoration.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110215|SERVER:www.gloves-prom.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110216|SERVER:www.gloves-silk.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110216|SERVER:www.pinnaclemailboxes.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110216|SERVER:www.stolenpurse.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110217|SERVER:www.buildbikes.net|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110217|SERVER:www.gloves-cotton.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110217|SERVER:www.time2spare.biz|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110217|SERVER:www.tolotoysonline.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110219|SERVER:www.gloves-metallic.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110219|SERVER:www.gloves-velvet.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110220|SERVER:italianseed.net|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110220|SERVER:www.gloves-formal.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110220|SERVER:www.thepocketwatcher.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110221|SERVER:gloves-bridal.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110221|SERVER:gloves-metallic.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110221|SERVER:gloves-prom.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110221|SERVER:gloves-sheer.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110221|SERVER:greatcatz.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110221|SERVER:greatwholesales.com|REASON:robots.txt
WATCH|IP:213.180.209.129|WHEN:20110221|SERVER:greenstreamwireless.com|REASON:robots.txt
WATCH|IP:213.203.203.68|WHEN:20110205|SERVER:raku-art.com|REASON:robots.txt
WATCH|IP:213.203.203.68|WHEN:20110206|SERVER:raku-art.com|REASON:robots.txt
WATCH|IP:213.203.203.68|WHEN:20110208|SERVER:guitarelectronics.com|REASON:robots.txt
WATCH|IP:213.203.203.68|WHEN:20110209|SERVER:raku-art.com|REASON:robots.txt
WATCH|IP:213.203.203.68|WHEN:20110210|SERVER:guitarelectronics.com|REASON:robots.txt
WATCH|IP:213.203.203.68|WHEN:20110210|SERVER:raku-art.com|REASON:robots.txt
WATCH|IP:213.203.203.68|WHEN:20110213|SERVER:guitarelectronics.com|REASON:robots.txt
WATCH|IP:213.203.203.68|WHEN:20110215|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:213.203.203.68|WHEN:20110220|SERVER:discountgunmart.com|REASON:robots.txt
WATCH|IP:213.229.109.159|WHEN:20110203|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:213.229.109.159|WHEN:20110206|SERVER:kidsafeinc.com|REASON:robots.txt
WATCH|IP:213.229.109.159|WHEN:20110206|SERVER:summitfashions.com|REASON:robots.txt
WATCH|IP:213.229.109.159|WHEN:20110206|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:213.229.109.159|WHEN:20110206|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:213.229.109.159|WHEN:20110206|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:213.229.109.159|WHEN:20110206|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:213.239.207.154|WHEN:20110220|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:213.239.207.154|WHEN:20110221|SERVER:kidsafeinc.com|REASON:robots.txt
WATCH|IP:213.239.207.154|WHEN:20110221|SERVER:summitfashions.com|REASON:robots.txt
WATCH|IP:213.239.207.154|WHEN:20110221|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:213.253.92.100|WHEN:20110201|SERVER:www.garagestyle.com|REASON:robots.txt
WATCH|IP:213.253.92.100|WHEN:20110208|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:213.55.95.32|WHEN:20110202|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:216.104.15.130|WHEN:20110204|SERVER:www.wrigleyfieldsince1914.com|REASON:robots.txt
WATCH|IP:216.104.15.134|WHEN:20110204|SERVER:www.victorianheartquilts4less.com|REASON:robots.txt
WATCH|IP:216.104.15.142|WHEN:20110210|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:216.104.15.142|WHEN:20110210|SERVER:www.wizgear.com|REASON:robots.txt
WATCH|IP:216.123.153.152|WHEN:20110216|SERVER:www.lp.halebobstore.com|REASON:robots.txt
WATCH|IP:216.123.153.152|WHEN:20110216|SERVER:www.us.halebobstore.com|REASON:robots.txt
WATCH|IP:216.151.183.35|WHEN:20110213|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:216.163.246.1|WHEN:20110211|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:216.163.247.1|WHEN:20110211|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:216.183.81.221|WHEN:20110206|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:216.183.81.221|WHEN:20110212|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:216.183.81.221|WHEN:20110214|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.nydugout.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.oakfurnitureshop.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.oktoberfesthaus.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.plumbsource.net|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110207|SERVER:www.victorianshop4u.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110208|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110208|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110208|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110208|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110208|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110208|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110208|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.blackhawksshop.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110209|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110210|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110210|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110210|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110210|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110210|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110210|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110210|SERVER:www.blackhawksshop.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110210|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110210|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.blackhawksshop.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.froggysfog.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110213|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.blackhawksshop.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.froggysfog.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.nydugout.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.oakfurnitureshop.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.oktoberfesthaus.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.photonracquets.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.plumbsource.net|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110214|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110215|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110215|SERVER:www.victorianshop4u.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.froggysfog.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.nydugout.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.oakfurnitureshop.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.oktoberfesthaus.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.photonracquets.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.plumbsource.net|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110217|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110218|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110218|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110218|SERVER:www.victorianshop4u.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.blackhawksshop.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.froggysfog.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110220|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.blackhawksshop.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.froggysfog.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.nydugout.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.oakfurnitureshop.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110221|SERVER:www.oktoberfesthaus.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110222|SERVER:www.photonracquets.com|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110222|SERVER:www.plumbsource.net|REASON:robots.txt
WATCH|IP:216.185.215.3|WHEN:20110222|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:216.189.167.5|WHEN:20110207|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:216.189.167.5|WHEN:20110209|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:216.189.167.5|WHEN:20110218|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:216.221.71.30|WHEN:20110202|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:216.221.71.30|WHEN:20110218|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:216.221.71.30|WHEN:20110219|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:216.221.71.30|WHEN:20110221|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:216.224.247.146|WHEN:20110218|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:princesscostumesonline.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.buymichaeljacksoncostumes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.goorganics.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.movieteeshirt.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110202|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110203|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110203|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:princesscostumesonline.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.buymichaeljacksoncostumes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.goorganics.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.movieteeshirt.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110204|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110206|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110206|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110206|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:princesscostumesonline.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.buymichaeljacksoncostumes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.goorganics.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.movieteeshirt.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110207|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110209|SERVER:princesscostumesonline.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110209|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110209|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110209|SERVER:www.buymichaeljacksoncostumes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110209|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110209|SERVER:www.movieteeshirt.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110209|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110209|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110209|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110209|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:princesscostumesonline.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.buymichaeljacksoncostumes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.goorganics.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.movieteeshirt.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110211|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110213|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110214|SERVER:princesscostumesonline.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110214|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110214|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110214|SERVER:www.buymichaeljacksoncostumes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110214|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110214|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110214|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110214|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110214|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:princesscostumesonline.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.buymichaeljacksoncostumes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.goorganics.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.movieteeshirt.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110216|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110217|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:princesscostumesonline.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:toynk.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.buymichaeljacksoncostumes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.goorganics.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.movieteeshirt.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110218|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110219|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110220|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:princesscostumesonline.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:toynk.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.buymichaeljacksoncostumes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.goorganics.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.movieteeshirt.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:216.34.207.6|WHEN:20110221|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:216.46.79.130|WHEN:20110215|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:217.114.217.202|WHEN:20110215|SERVER:www.jamesmaddockstore.com|REASON:robots.txt
WATCH|IP:217.114.217.202|WHEN:20110219|SERVER:bbkingstore.com|REASON:robots.txt
WATCH|IP:217.132.131.100|WHEN:20110215|SERVER:www.nyciwear.com|REASON:robots.txt
WATCH|IP:217.33.110.231|WHEN:20110221|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110201|SERVER:www.pimpinshoes.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110210|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110210|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110210|SERVER:www.mensshirtshop.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110210|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110210|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110210|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110211|SERVER:www.costumesltd.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110211|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110211|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110212|SERVER:www.americanguitarboutique.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110212|SERVER:www.laartwork.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110212|SERVER:www.summitswimsuits.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110213|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110213|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110215|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110215|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110215|SERVER:www.dolldreams.net|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110216|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:217.69.133.34|WHEN:20110216|SERVER:www.pawstogo.com|REASON:robots.txt

WATCH|IP:217.69.134.*|WHEN:20110221|SERVER:www.racewax.com|REASON:robots.txt
WATCH|IP:220.181.125.67|WHEN:20110201|SERVER:www.perennialsales.com|REASON:robots.txt
WATCH|IP:220.181.125.68|WHEN:20110201|SERVER:www.perennialsales.com|REASON:robots.txt
WATCH|IP:220.181.125.69|WHEN:20110201|SERVER:www.perennialsales.com|REASON:robots.txt
WATCH|IP:220.181.125.70|WHEN:20110201|SERVER:www.perennialsales.com|REASON:robots.txt
WATCH|IP:220.181.125.71|WHEN:20110201|SERVER:www.perennialsales.com|REASON:robots.txt
WATCH|IP:220.181.125.72|WHEN:20110219|SERVER:www.shopwrigleyville.com|REASON:robots.txt
WATCH|IP:220.181.94.212|WHEN:20110207|SERVER:www.livingwelleatery.com|REASON:robots.txt
WATCH|IP:220.181.94.213|WHEN:20110207|SERVER:www.livingwelleatery.com|REASON:robots.txt
WATCH|IP:220.181.94.214|WHEN:20110207|SERVER:www.livingwelleatery.com|REASON:robots.txt
WATCH|IP:220.181.94.215|WHEN:20110222|SERVER:www.amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:220.181.94.216|WHEN:20110222|SERVER:www.arcolamp.com|REASON:robots.txt
WATCH|IP:220.181.94.217|WHEN:20110222|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:220.181.94.218|WHEN:20110222|SERVER:www.flicker90.com|REASON:robots.txt
WATCH|IP:220.181.94.219|WHEN:20110222|SERVER:www.personalizedpotterymugheaven.com|REASON:robots.txt
WATCH|IP:220.181.94.220|WHEN:20110222|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:220.181.94.221|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.181.94.222|WHEN:20110222|SERVER:www.amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:220.181.94.223|WHEN:20110222|SERVER:www.arcolamp.com|REASON:robots.txt
WATCH|IP:220.181.94.224|WHEN:20110222|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:220.181.94.225|WHEN:20110222|SERVER:www.flicker90.com|REASON:robots.txt
WATCH|IP:220.181.94.226|WHEN:20110222|SERVER:www.personalizedpotterymugheaven.com|REASON:robots.txt
WATCH|IP:220.181.94.227|WHEN:20110222|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:220.181.94.228|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.181.94.229|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.181.94.230|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.181.94.231|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.181.94.232|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.181.94.233|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.181.94.234|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.181.94.235|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.181.94.236|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.181.94.237|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:220.245.143.168|WHEN:20110218|SERVER:www.goshotcamera.com|REASON:robots.txt
WATCH|IP:220.255.2.191|WHEN:20110218|SERVER:www.ahlersgifts.com|REASON:robots.txt
WATCH|IP:220.255.2.212|WHEN:20110220|SERVER:www.4golftraining.com|REASON:robots.txt
WATCH|IP:220.255.2.230|WHEN:20110220|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:221.1.161.204|WHEN:20110220|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:221.156.251.197|WHEN:20110207|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:222.124.198.167|WHEN:20110214|SERVER:www.redrive.net|REASON:robots.txt
WATCH|IP:222.127.118.212|WHEN:20110210|SERVER:www.smarterlight.com|REASON:robots.txt
WATCH|IP:222.228.227.196|WHEN:20110203|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:222.228.227.196|WHEN:20110205|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:222.228.227.196|WHEN:20110207|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:222.228.227.196|WHEN:20110208|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:222.228.227.196|WHEN:20110210|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:222.228.227.196|WHEN:20110213|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:222.228.227.196|WHEN:20110215|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:222.228.227.196|WHEN:20110217|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:222.228.227.196|WHEN:20110218|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:222.228.227.196|WHEN:20110220|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:223.205.0.54|WHEN:20110222|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:223.205.0.54|WHEN:20110222|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:24.107.124.53|WHEN:20110208|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:24.139.61.106|WHEN:20110221|SERVER:www.purewaveaudio.com|REASON:robots.txt
WATCH|IP:24.156.33.116|WHEN:20110217|SERVER:www.2bhip.com|REASON:robots.txt
WATCH|IP:24.182.185.155|WHEN:20110222|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:24.185.231.180|WHEN:20110208|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:24.185.231.180|WHEN:20110209|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:24.185.245.10|WHEN:20110214|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:24.211.27.206|WHEN:20110207|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:24.212.53.47|WHEN:20110219|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:24.217.50.83|WHEN:20110213|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:24.217.50.83|WHEN:20110213|SERVER:www.wildcollections.com|REASON:robots.txt
WATCH|IP:24.218.3.11|WHEN:20110202|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:24.218.3.11|WHEN:20110202|SERVER:www.stage3offroad.com|REASON:robots.txt
WATCH|IP:24.239.148.198|WHEN:20110221|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:24.248.185.5|WHEN:20110207|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:24.29.223.8|WHEN:20110208|SERVER:www.skullplanet.com|REASON:robots.txt
WATCH|IP:24.39.4.196|WHEN:20110203|SERVER:www.favorsngifts.com|REASON:robots.txt
WATCH|IP:24.39.4.196|WHEN:20110207|SERVER:www.favorsngifts.com|REASON:robots.txt
WATCH|IP:24.39.4.196|WHEN:20110211|SERVER:www.favorsngifts.com|REASON:robots.txt
WATCH|IP:24.39.4.196|WHEN:20110214|SERVER:www.favorsngifts.com|REASON:robots.txt
WATCH|IP:24.39.4.196|WHEN:20110217|SERVER:www.favorsngifts.com|REASON:robots.txt
WATCH|IP:24.45.109.42|WHEN:20110205|SERVER:www.zephyrpaintball.com|REASON:robots.txt

BOT|IP:38.99.82.*|WHEN:20110205|SERVER:www.azuzu.com|REASON:robots.txt (lots of em)
WATCH|IP:61.135.184.197|WHEN:20110221|SERVER:www.thegiftmallonline.com|REASON:robots.txt
KILL|IP:64.124.14.126|WHEN:20110208|SERVER:sitesmax.com|REASON:MarkMonitor (Brand police)




WATCH|IP:66.36.230.78|WHEN:20110203|SERVER:dealexpress.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110203|SERVER:houseintoahome.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110203|SERVER:madaboutplaid.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110203|SERVER:theauctionbooks.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110204|SERVER:brandnameluxuries.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110204|SERVER:finalegloves.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110204|SERVER:www.raincustom.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110204|SERVER:www.rockerjewelry.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110204|SERVER:www.silverfair.us|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110205|SERVER:four.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110206|SERVER:battlewagonbits.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110207|SERVER:kmjinvestments.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110208|SERVER:mccraw.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110208|SERVER:roberts01.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110209|SERVER:espressoparts.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110209|SERVER:www.luggage4less.net|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110210|SERVER:summitfashions.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110210|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110211|SERVER:www.gifts.gogoods.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110212|SERVER:parmingchince.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110212|SERVER:www.onlinedollshop.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110212|SERVER:xppassport.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110213|SERVER:www.rainbowgifts.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110214|SERVER:buttony.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110214|SERVER:cccraft.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110214|SERVER:rufusdawg.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110214|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110214|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110216|SERVER:denimsquare.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110216|SERVER:talkntel.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110216|SERVER:tiarayachts.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110217|SERVER:dynamicsurplus.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110217|SERVER:froggysfog.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110217|SERVER:www.hotlookz.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110218|SERVER:lapower.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110219|SERVER:www.steveearlestore.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110220|SERVER:humblefolk.zoovy.com|REASON:robots.txt
WATCH|IP:66.36.230.78|WHEN:20110220|SERVER:www.loudkricket.com|REASON:robots.txt
WATCH|IP:66.6.147.30|WHEN:20110201|SERVER:www.ghostinc.com|REASON:robots.txt
WATCH|IP:66.65.27.205|WHEN:20110212|SERVER:sfplanet.com|REASON:robots.txt
WATCH|IP:66.65.27.205|WHEN:20110212|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:66.65.92.106|WHEN:20110210|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:66.66.223.212|WHEN:20110202|SERVER:www.raku-art.com|REASON:robots.txt
WATCH|IP:66.66.223.212|WHEN:20110204|SERVER:www.raku-art.com|REASON:robots.txt
WATCH|IP:66.82.162.13|WHEN:20110221|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:66.87.7.177|WHEN:20110203|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110202|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110203|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110204|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110205|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110206|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110208|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110210|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110211|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110212|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110213|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110214|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110215|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110216|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110217|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110218|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110219|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110220|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.110.177.168|WHEN:20110222|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.121.115.80|WHEN:20110209|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:67.121.145.175|WHEN:20110212|SERVER:www.hausfortuna.com|REASON:robots.txt
WATCH|IP:67.139.65.189|WHEN:20110213|SERVER:www.safety-outlet.com|REASON:robots.txt
WATCH|IP:67.165.224.148|WHEN:20110203|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:67.175.10.151|WHEN:20110205|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:67.182.217.155|WHEN:20110217|SERVER:www.furniture-online.com|REASON:robots.txt
WATCH|IP:67.189.213.102|WHEN:20110203|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:67.189.213.102|WHEN:20110213|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:67.197.150.165|WHEN:20110201|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.19.79.218|WHEN:20110218|SERVER:ssl.zoovy.com|REASON:robots.txt
WATCH|IP:67.19.79.218|WHEN:20110219|SERVER:ssl.zoovy.com|REASON:robots.txt
WATCH|IP:67.19.79.218|WHEN:20110220|SERVER:vstore.zoovy.com|REASON:robots.txt
WATCH|IP:67.19.79.218|WHEN:20110221|SERVER:vstore.zoovy.com|REASON:robots.txt
WATCH|IP:67.202.1.109|WHEN:20110201|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.202.11.113|WHEN:20110220|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110202|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110202|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110203|SERVER:agandb.zoovy.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110203|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110204|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110204|SERVER:www.flenstedmobilegallery.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110204|SERVER:www.mosaictile.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110204|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110206|SERVER:www.hungerthonstore.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110207|SERVER:www.furthurstore.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110207|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110209|SERVER:www.purewaveaudio.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110210|SERVER:www.4my3boyz.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110212|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110212|SERVER:www.flenstedmobilegallery.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110212|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110212|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110213|SERVER:agandb.zoovy.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110213|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110214|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110215|SERVER:www.radusadirect.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110217|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110218|SERVER:www.beachboysstore.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110218|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110220|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110220|SERVER:www.williamfitzsimmonsstore.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110220|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110221|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110221|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:67.202.11.220|WHEN:20110222|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.202.16.5|WHEN:20110203|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.208.197.124|WHEN:20110211|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110201|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110201|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110201|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110201|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110201|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110201|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110201|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.ibuywoodstoves.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.myhotshoes.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.rcraveninc.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.s281motorsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.thespotlowrider.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110202|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:www.kidscraftsplus.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:www.mosaictile.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:www.robdiamond.net|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110203|SERVER:yocaps.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:helmethead2.zoovy.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:tikimasks.net|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.amigaz.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.partybrights.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.powerlandonline.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.racerwalsh.zoovy.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.safety-outlet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.softnerparts.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.warehousedirectusa.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110204|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110205|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110205|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:smyrnacoin.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.bathtubparts.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.bulkglitters.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.coloradocustommetal.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.costumecow.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.dutchsheets.zoovy.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.furthurstore.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.reefs2go.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.williamfitzsimmonsstore.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110206|SERVER:zestcandle.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:www.myhotshoes.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110207|SERVER:www.smyrnacoin.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:208.74.184.51|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.lilslavender.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.michaelscookies.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.nyciwear.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.perfumecenteronline.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.thegiftmallonline.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.thing1thing2costumes.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110208|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110209|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110209|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110209|SERVER:terracottaonweb.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110209|SERVER:westkycustoms.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110209|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110209|SERVER:www.reefs2go.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110209|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110209|SERVER:www.rockerjewelry.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110209|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110209|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110210|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110210|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110210|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110210|SERVER:www.qcollectionjunior.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110210|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110210|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110210|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110210|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:austinbazaar.zoovy.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.aromaspas.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.austinbazaar.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.frogpondaquatics.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.planetrenadirect.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.speedaddictcycles.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110211|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:toonstation.zoovy.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.belly9shop.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.beltsandmore.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.bonnies.zoovy.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.bowhuntingstuff.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.coloradocustommetal.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.hayspear.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.prohatsandpatches.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.prostreetlighting.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.summitfashions.zoovy.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.themahjongshop.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110212|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:helmethead2.zoovy.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.blulightning.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.cmamusicfeststore.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.coloradocustommetal.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.jakeowenstore.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.logfurnituresite.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.safety-outlet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110213|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110214|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110214|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110214|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110214|SERVER:www.piratedecoration.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110214|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110214|SERVER:www.rockmusicjewelry.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110214|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110214|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:www.americanguitarandband.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:www.reefs2go.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110215|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:sacredengraving.zoovy.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:www.ebonicorner.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:www.favorsngifts.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:www.myhotshoes.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:www.paintsprayersplus.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:www.warehousedirectusa.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110216|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:smyrnacoin.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.betterbeauty.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.s281motorsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.safety-outlet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.softnerparts.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110217|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.custompotrack.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.hillbillyknifesales.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.pocketwatcher.org|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.rapid-direction.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.reefs2go.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.savecentral.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110218|SERVER:www.zephyrsunglasses.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:smyrnacoin.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.completelykimble.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.flagsonastick.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.ghostinc.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.thespotlowrider.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.ticohomedecor.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.waterwayspapumps.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110219|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110220|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110220|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110220|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110220|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110220|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110220|SERVER:www.hbdrums.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110220|SERVER:www.prohatsandpatches.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110220|SERVER:www.zephyrairsoft.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110220|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:208.74.184.103|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:208.74.184.119|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.beltiscool.net|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.greatglovesonline.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.ironstoneimports.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110221|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110222|SERVER:208.74.184.87|REASON:robots.txt
WATCH|IP:67.220.101.136|WHEN:20110222|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:67.246.89.92|WHEN:20110209|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:67.64.158.204|WHEN:20110222|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:67.80.208.63|WHEN:20110203|SERVER:sassyassybjeans.zoovy.com|REASON:robots.txt
WATCH|IP:67.80.208.63|WHEN:20110206|SERVER:sassyassybjeans.zoovy.com|REASON:robots.txt
WATCH|IP:67.80.208.63|WHEN:20110213|SERVER:sassyassybjeans.zoovy.com|REASON:robots.txt
WATCH|IP:67.83.50.155|WHEN:20110214|SERVER:www.shelterdist.com|REASON:robots.txt
WATCH|IP:68.0.137.137|WHEN:20110217|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:68.11.125.46|WHEN:20110209|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:68.12.138.13|WHEN:20110209|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:68.122.75.201|WHEN:20110208|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:68.183.49.19|WHEN:20110219|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:68.187.208.120|WHEN:20110212|SERVER:www.blitzinc.net|REASON:robots.txt
WATCH|IP:68.2.100.57|WHEN:20110210|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:68.35.134.253|WHEN:20110201|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.35.134.253|WHEN:20110202|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.35.134.253|WHEN:20110204|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.35.134.253|WHEN:20110205|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.35.134.253|WHEN:20110208|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.35.134.253|WHEN:20110210|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.35.134.253|WHEN:20110211|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.35.134.253|WHEN:20110212|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.35.134.253|WHEN:20110215|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.35.134.253|WHEN:20110217|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.36.142.180|WHEN:20110206|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:68.36.142.180|WHEN:20110222|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:68.4.110.180|WHEN:20110215|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:68.4.114.117|WHEN:20110209|SERVER:www.pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:68.47.130.2|WHEN:20110201|SERVER:saucebossstore.com|REASON:robots.txt
WATCH|IP:68.47.130.2|WHEN:20110201|SERVER:www.saucebossstore.com|REASON:robots.txt
WATCH|IP:68.47.130.2|WHEN:20110202|SERVER:www.cmamusicfeststore.com|REASON:robots.txt
WATCH|IP:68.47.130.2|WHEN:20110202|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:68.47.130.2|WHEN:20110203|SERVER:www.funbottleopeners.com|REASON:robots.txt
WATCH|IP:68.47.130.2|WHEN:20110210|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:68.5.148.162|WHEN:20110218|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:68.53.135.136|WHEN:20110207|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:68.53.135.136|WHEN:20110215|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:68.53.135.136|WHEN:20110219|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:68.57.236.105|WHEN:20110204|SERVER:www.ironstoneimports.com|REASON:robots.txt
WATCH|IP:68.57.236.105|WHEN:20110210|SERVER:www.qcollectionjunior.com|REASON:robots.txt
WATCH|IP:68.81.193.56|WHEN:20110218|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:68.97.62.46|WHEN:20110214|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:69.108.113.97|WHEN:20110220|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:69.125.83.28|WHEN:20110202|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:69.125.83.28|WHEN:20110208|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:69.140.164.184|WHEN:20110216|SERVER:www.yourdreamizhere.com|REASON:robots.txt
WATCH|IP:69.140.164.184|WHEN:20110217|SERVER:www.yourdreamizhere.com|REASON:robots.txt
WATCH|IP:69.14.105.8|WHEN:20110204|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:69.143.249.112|WHEN:20110206|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:69.146.9.202|WHEN:20110213|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110201|SERVER:www.carvingemporium.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110202|SERVER:rightwayonline.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110202|SERVER:www.em203.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110202|SERVER:www.silverchicks.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110203|SERVER:www.oaksbatterup.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110206|SERVER:memorabiliamkt.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110206|SERVER:othergamestoo.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110206|SERVER:www.italianseedandtool.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110207|SERVER:888knivesrus.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110207|SERVER:coinsandcollectibles.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110207|SERVER:crite2000.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110208|SERVER:www.capaper.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110208|SERVER:www.closeoutdude.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110208|SERVER:www.zephyrairsoft.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110209|SERVER:angelstechnology.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110209|SERVER:boofgear.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110209|SERVER:www.cubbyhole.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110209|SERVER:www.tikioutlet.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110210|SERVER:krewkut.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110211|SERVER:renaissance.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110211|SERVER:www.leedway.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110212|SERVER:bikerwholesale.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110212|SERVER:www.bemodajewelry.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110213|SERVER:lasertekservices.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110213|SERVER:steveearlestore.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110214|SERVER:buffaloexchange.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110214|SERVER:dollstreet.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110214|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110214|SERVER:www.outofthetoybox.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110217|SERVER:100percenttoys.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110217|SERVER:discount-designers.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110217|SERVER:kahl.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110218|SERVER:carmobileaudiovideo.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110218|SERVER:www.spapartsdepot.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110220|SERVER:stealthcycling.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110221|SERVER:potteryandstuff.zoovy.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110221|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:69.147.234.122|WHEN:20110222|SERVER:ibuybarbeques.com|REASON:robots.txt
WATCH|IP:69.16.180.22|WHEN:20110204|SERVER:greathatz.com|REASON:robots.txt
WATCH|IP:69.16.180.22|WHEN:20110210|SERVER:greatlookz.com|REASON:robots.txt
WATCH|IP:69.16.180.22|WHEN:20110217|SERVER:greatlookz.com|REASON:robots.txt
WATCH|IP:69.16.180.22|WHEN:20110217|SERVER:greatparasolz.com|REASON:robots.txt
WATCH|IP:69.16.180.2|WHEN:20110211|SERVER:greathatz.com|REASON:robots.txt
WATCH|IP:69.16.180.30|WHEN:20110203|SERVER:greatlookz.com|REASON:robots.txt
WATCH|IP:69.16.180.34|WHEN:20110203|SERVER:greatglovesonline.com|REASON:robots.txt
WATCH|IP:69.16.180.34|WHEN:20110204|SERVER:greatglovesonline.com|REASON:robots.txt
WATCH|IP:69.16.180.34|WHEN:20110211|SERVER:greatshopz.com|REASON:robots.txt
WATCH|IP:69.16.180.46|WHEN:20110216|SERVER:www.tatianafashions.com|REASON:robots.txt
WATCH|IP:69.16.180.46|WHEN:20110217|SERVER:greathatz.com|REASON:robots.txt
WATCH|IP:69.16.180.46|WHEN:20110218|SERVER:greatshopz.com|REASON:robots.txt
WATCH|IP:69.16.180.50|WHEN:20110207|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:69.16.180.54|WHEN:20110209|SERVER:www.loblollyskitchen.com|REASON:robots.txt
WATCH|IP:69.16.180.54|WHEN:20110210|SERVER:greatparasolz.com|REASON:robots.txt
WATCH|IP:69.166.18.109|WHEN:20110214|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:69.168.131.83|WHEN:20110215|SERVER:www.airwaterice.com|REASON:robots.txt
WATCH|IP:69.174.152.16|WHEN:20110214|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:69.198.187.98|WHEN:20110209|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.205.187.88|WHEN:20110206|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:69.244.208.183|WHEN:20110220|SERVER:www.americanguitarboutique.com|REASON:robots.txt
WATCH|IP:69.255.197.38|WHEN:20110218|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:69.28.58.10|WHEN:20110218|SERVER:onlinedollshop.com|REASON:robots.txt
WATCH|IP:69.28.58.10|WHEN:20110221|SERVER:www.inflatableprojectionscreens.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110208|SERVER:www.aquaflospapumps.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:carolinabeachtowels.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:powerlandonline.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:rapitup.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:scalesusa.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:www.carolinabeachtowels.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:www.custompotrack.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:www.highresolutionprojector.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:www.laingcircpumps.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:www.laingspapumps.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:www.nadea.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:www.panrack.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:www.powerlandonline.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:www.precisiontamp.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110209|SERVER:www.speedbleeder.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:holsterz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:warehousedirect72.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:warehousedirectusa.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:www.hogbacktrading.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:www.holsterz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:www.logothreadz.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:www.silver-seal.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:www.standsbyriver.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:www.sweetwaterscavenger.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:www.warehousedirectusa.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110210|SERVER:www.weknowbest.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:ayoungenterprise.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:candlemakers.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:cobysfund.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:krewkut.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:maakenterprises.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:ribbontrade.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:silver-seal.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:stopdirt.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:thecandlemakersstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:tradervar.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:www.krewkut.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:www.redrive.net|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:www.ribbontrade.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:www.silver-seal.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110211|SERVER:www.thecandlemakersstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:battletestedpaintball.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:bwbits.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:capg.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:inflatablessuperstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:instantcoldcompresses.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:paintballgodz.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.battletestedpaintball.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.bwbits.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.capaper.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.capg.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.fotoadapter.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.ibuyappliances.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.inflatablessuperstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.instantcoldcompress.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.instantcoldcompresses.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.kryptapparel.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.paintballgodz.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.reefs2go.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.soccergodz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.sportsgodz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.zephyrairsoft.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:zephyrairsoft.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110212|SERVER:zephyrsports.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110213|SERVER:gameworld.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110213|SERVER:thechessstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110213|SERVER:thechessstore.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110213|SERVER:www.bathtubparts.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110213|SERVER:www.chesssetsbd.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110213|SERVER:www.gamesgaloredirect.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110213|SERVER:www.lemmyfigure.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110213|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110213|SERVER:www.thechessstore.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110214|SERVER:aniyasmagicart.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110214|SERVER:bbkingstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110214|SERVER:caboots.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110214|SERVER:consumerwholesale.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110214|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110215|SERVER:dollstreet.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110215|SERVER:envirovogue.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110215|SERVER:firefoxtechnologies.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110215|SERVER:gunnersalley.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110215|SERVER:jaredcampbellstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110215|SERVER:klatchroasting.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110215|SERVER:kseiya.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110215|SERVER:www.envirovogue.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110215|SERVER:www.jaredcampbellstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110215|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110216|SERVER:potterycorner.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110216|SERVER:racing4sports.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110216|SERVER:radusadirect.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110216|SERVER:seiyajapan.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110216|SERVER:www.racing4sports.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110216|SERVER:www.radusadirect.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110216|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110216|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110217|SERVER:shop.beechmontvolvo.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110217|SERVER:steveearlestore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110217|SERVER:talkntel.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110217|SERVER:tshirtsmall.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110217|SERVER:uspins.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110217|SERVER:www.shop.beechmontvolvo.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110217|SERVER:www.steveearlestore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110217|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110217|SERVER:www.tshirtsmall.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110217|SERVER:www.weberplasticmodels.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.agandb.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.airwaterice.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.albertcummingsstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.americanguitarboutique.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.ancientsunnutrition.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.blitzinc.net|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.boyceimage.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.buddyguystore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.caboots.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110218|SERVER:www.caboots.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.chique-plus.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.clemsonvariety.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.doodlebugandpeanut.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.employeedevsys.theperformancereportwebstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.f2ptechnologies.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ghostinc.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ghostinc.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.greatlookzjapanese.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.greatlookz.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuyfiremagicgrills.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuygrillcovers.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuylights.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuylumaxlighting.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuymaximlighting.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuymonessenfireplaces.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuynapoleonfireplaces.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuynapoleongrills.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuysolarpanels.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuytecgrills.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuyvermontgrills.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.ibuywoodstoves.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.jakeowenstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.lilslavender.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.orleanscandles.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.orleansgiftshop.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.pocketwatcher.org|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110219|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:ebestsourc.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:elvistech.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:helmethead2.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:smyrnacoin.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:thebunkhouse.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:toonstation.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.elvistech.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.elvistech.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.qcollectionjunior.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.ratdogstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.rdwholesale.net|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.smyrnacoin.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.thegiftmallonline.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110220|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:allpetsolutions.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:crite2000.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:dollssoreal.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:erinsedge.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:houseintoahome.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:instantgaragesales.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:onlineformals.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:pony.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:racerwalsh.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:toonstation.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:toynk.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:unixsurplus.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.affordablechristianproducts.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.alternativedvd.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.aromaspas.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.beachboysstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.berenguerdolls.net|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.bubbas.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.buyyogabbagabbatoys.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.campaign-printing.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.cannoligram.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.carmobileaudiovideo.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.carmobilevideo.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.coolers.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.dinnerwarepotterymugheaven.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.dolldreams.net|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.doodlebugandpeanut.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.erinsedge.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.favorsngifts.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.garagestyle.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.gilco.net|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.givemetoys.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.grapevinepotrack.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.greatlookzitaly.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.gunnersalley.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.houseware.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.housewares.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.instantgaragesales.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.irresistables.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.italianseedandtool.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.koamaster.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.mainemapleandhoney.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.naughtygirlhandbags.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.novelties.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.onlinepromgowns.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.pony.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.quiltjourney.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.rcraveninc.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.redhatshopz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.rockmusicjewelry.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.rockmusicjewelry.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.scrappersbunkhouse.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.securityvideosolutions.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.sexytopsshop.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.smyrnacoin.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.smyrnacoin.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.stewarttoys.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.supergirlcomics.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.temdee.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.thespotlowrider.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.toynk.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.toys.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110221|SERVER:www.willowtree.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:888knivesrus.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:americanguitarandband.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:barefoottess.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:bigbowling.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:buttony.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:climbingholds.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:closeoutdude.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:envirovogue.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:fairwaymarketing.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:fashionmonsters.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:gearlabs.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:golfswingtrainer.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:kelhampolishpottery.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:lasertekservices.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:luggage4less.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:pocketwatcher.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:q3artinc.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:raincustom.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:sassyassybjeans.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:seiky.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:sfplanet.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:silverchicks.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:softenerparts.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:soundsource.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:sweetwaterscavenger.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:thegoodtimber.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:toonstation.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:usmemoryfoam.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.alloceansports.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.americanguitarandband.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.amigaz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.andreasinc.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.augustartpaper.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.barefoottess.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.bedplanet.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.berniessmellsnbells.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.buttony.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.buystonesonline.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.buystonesonline.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.capsandbeanies.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.cardiacwellness.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.closeoutdude.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.colocustommetal.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.coloradocustommetal.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.crazywireguy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.custompotrack.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.envirovogue.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.etooti.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.europottery.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.expedition-imports.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.fleurdelisdirect.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.flexsteeldirect.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.flicker90.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.furniture-online.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.garyputthoffstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.geckospapacks.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.glassbeadgarden.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.golfswingtrainer.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.goorganics.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.gothlookz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.greatgemz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.greatglovesonline.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.greatparasolz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.guitarshirtshop.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.hawaiibulk.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.heavydutymats.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.ibikedoyou2.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.itascamoccasin.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.jaredcampbellstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.jasonmichaelcarrollstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.konrads.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.kraftyatkrafts.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.laartwork.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.leatherfurniturecenter.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.lisabeads.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.marcbroussardstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.medicalfurniture-online.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.mensshirtshop.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.miniatureguitaroutlet.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.miniaturesawworks.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.motorcowboy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.motorcowboy.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.myhotshoes.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.oaksbatterup.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.oldscyene.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.oworlds.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.paintballgodz.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.partybrights.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.pdpprinting.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.performancepda.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.perpetualvogue.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.personalizedpotterymugheaven.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.pocketwatcher.org|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.q3artinc.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.quemex.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.rainbowcustomcars.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.raincustom.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.rancholocoboots.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.rob-diamond.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.sarihome.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.shirtsforbikers.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.silverchicks.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.skullplanet.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.softnerparts.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.spapartsdepot.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.sundaro.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.surfcitymusic.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.thecandlemakersstore.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.thegoodtimber.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.underthesuncollectibles.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.underthesun.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.usmemoryfoam.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.utsgifts.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.worldsbestmats.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.yesterdaysthings.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.zephyrairsoft.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.zephyrslingshots.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.zephyrsunglasses.com|REASON:robots.txt
WATCH|IP:69.28.58.15|WHEN:20110222|SERVER:www.zephyrwholesale.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:onequickcup.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.capaper.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.cashmereelite.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.cmamusicfeststore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.digmodern.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.evocstore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.funbottleopeners.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.holsterz.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.hotsaucehawaii.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.ibuybarbeques.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.ironstoneimports.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.kidsbargains.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.klatchroasting.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.kseiya.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.modernmini.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.nancigriffithstore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.office-chairs-supply.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.oldcookbooks.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110219|SERVER:www.polishkitchenonline.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:4armedforces.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:tikimaster.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:toonstation.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.ebestsource.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.racing4sports.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.ribbontrade.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.robdiamond.net|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.royaltrend.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.silverfair.us|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.steveearlestore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.stingergirlz.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.ticodecorations.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.ticohomedecor.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.travistrittstore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.tshirtsmall.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.waltonandjohnson.biz|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.williamfitzsimmonsstore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.wirelessvideocameras.net|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110220|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:bierhaus.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:bubbas.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:gooddeals18.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:leos.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:rockmusicjewelry.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:stewarttoys.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:temdee.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:theh2oguru.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:willowtree.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.belly9shop.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.bierhaus.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.coastaldecoration.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.dianayvonne.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.dollhousesandmore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.dollstreet.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.duckhousedoll.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.dutchsheets.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.froggysfog.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.ghostblock.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.gifts.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.greatweddingz.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.helmethead2.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.houseintoahome.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.ibuybarbecues.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.ibuygrillparts.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.livingwelleatery.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.maddogsports.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.maureenscreations.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.misternostalgia.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.naturalcuresstore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.onlineformals.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.onlinepromgowns.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.ornamentsafe.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.outofthetoybox.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.partyhats.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.racerwalsh.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.rcusa.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.specialtyfoodshawaii.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.teacupgallery.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.theauto.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.thesecurebox.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.toonstation.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.vitalshops.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110221|SERVER:www.wildcollections.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:allansjewelry.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:bbrothersc.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:blueheadsets.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:buystonesonline.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:carolinaparakeet.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:cashmereelite.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:cbpots.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:colocustommetal.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:crunruh.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:decoratingwithlace.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:djimprinting.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:envisiontek.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:etooti.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:fairyfinery.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:flamedancerbeads.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:kraftyatkrafts.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:lilslavender.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:motorcowboy.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:mountaincrafts.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:puremoda.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:raku.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:refinergolf.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:rhythmfusion.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:summitfashions.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:surfcitymusic.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:underthesun.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.1880sboots.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.4golftraining.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.4my3boyz.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.aaavacs.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.ahlersgifts.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.allans.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.bambooandthatch.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.boostmobilecellphone.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.bootstoo.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.bowhuntingstuff.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.celtictenorsstore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.cfisd.biz|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.chiquelife.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.cindyscharms.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.cmaawardsstore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.coloradocustommetal.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.craftersnet.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.crunruh.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.crunruh.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.decor411.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.denimsquare.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.elegantbed.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.fancytiebacks.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.finalegloves.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.flamedancerbeads.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.gearlabs.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.glassartheaven.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.gloves-fingerless.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.gloves.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.greatglovesonline.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.greatlinenz.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.greatsockz.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.greatstockingz.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.hbdrums.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.instrumentsexpress.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.jdhines.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.krewkut.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.leadersforless.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.leisureforwomen.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.licenseplateframes.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.logfurnituresite.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.luggage4less.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.luggage4less.net|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.marcelhomedecor.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.mosaictile.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.mountaincrafts.net|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.mountaincrafts.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.nwsalesconnection.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.office.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.oktoberfesthaus.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.outdoornrg.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.pimpinshoes.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.pocketwatcher.org|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.pocketwatcher.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.powerlandonline.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.precisiondata.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.proforgeknives.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.racewax.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.rainbowcustomcars.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.rainbowgifts.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.raku-art.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.rayscustomtackle.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.rhythmfusion.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.rockerjewelry.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.rufusdawg.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.sacredengraving.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.safetyproductsmarketplace.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.saricurtain.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.sewkool.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.sfplanet.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.shelterdist.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.shopvelvethanger.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.softenerparts.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.softnerparts.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.sonsofwilliamstore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.spa.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.spapartsdepot.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.spapumps.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.speedaddictcycles.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.stealthcycling.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.summitfashions.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.surfingmaster.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.theoverstockedkitchen.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.topgearleather.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.trainingsmoke.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.wallsthatspeak.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.warehousedirectusa.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.womensyogasportsapparel.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:www.yourdreamizhere.com|REASON:robots.txt
WATCH|IP:69.28.58.16|WHEN:20110222|SERVER:yesterdaysthings.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.17|WHEN:20110205|SERVER:barefoottess.com|REASON:robots.txt
WATCH|IP:69.28.58.17|WHEN:20110205|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:69.28.58.17|WHEN:20110206|SERVER:barefoottess.com|REASON:robots.txt
WATCH|IP:69.28.58.17|WHEN:20110206|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:69.28.58.17|WHEN:20110208|SERVER:barefoottess.com|REASON:robots.txt
WATCH|IP:69.28.58.17|WHEN:20110208|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:69.28.58.17|WHEN:20110209|SERVER:barefoottess.com|REASON:robots.txt
WATCH|IP:69.28.58.33|WHEN:20110219|SERVER:www.communitymailboxes.com|REASON:robots.txt
WATCH|IP:69.28.58.33|WHEN:20110220|SERVER:www.ibuyinductionlighting.com|REASON:robots.txt
WATCH|IP:69.28.58.33|WHEN:20110220|SERVER:www.ibuyoutdoorgrills.com|REASON:robots.txt
WATCH|IP:69.28.58.33|WHEN:20110220|SERVER:www.molly-p-original-dolls.com|REASON:robots.txt
WATCH|IP:69.28.58.35|WHEN:20110220|SERVER:www.icsiparts.com|REASON:robots.txt
WATCH|IP:69.28.58.35|WHEN:20110221|SERVER:www.tailedfoxstore.com|REASON:robots.txt
WATCH|IP:69.28.58.37|WHEN:20110210|SERVER:m.pajamasgirls.com|REASON:robots.txt
WATCH|IP:69.28.58.37|WHEN:20110210|SERVER:sassyassybjeans.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.37|WHEN:20110210|SERVER:summithosiery.com|REASON:robots.txt
WATCH|IP:69.28.58.37|WHEN:20110210|SERVER:www.pajamasgirls.com|REASON:robots.txt
WATCH|IP:69.28.58.37|WHEN:20110210|SERVER:www.summithosiery.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:rainbowgifts.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:sacredengraving.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:weknowbest.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.ariheststore.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.espressoparts2.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.ezmiser.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.jimsbigstore.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.ksrhoadsstore.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.lilslavender.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.protectmycamera.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.pulsartech.net|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.spittys.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.virgoelectronics.com|REASON:robots.txt
WATCH|IP:69.28.58.41|WHEN:20110222|SERVER:www.yuppygift.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:performancepda.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:precisiondata.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:wildemats.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.cbpots.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.cupidmusicstore.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.djimprinting.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.flagsonastick.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.ginblossomsstore.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.girlfriendgalas.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.great4giftz.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.jewelville.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.jewelvillegeneralstore.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.needtobreathestore.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.shop.beechmontvolvo.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.thecubanshop.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.thespringstandardsstore.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.toolusa.com|REASON:robots.txt
WATCH|IP:69.28.58.42|WHEN:20110222|SERVER:www.warmers.gogoods.com|REASON:robots.txt
WATCH|IP:69.28.58.9|WHEN:20110209|SERVER:www.firepitsltd.com|REASON:robots.txt
WATCH|IP:69.43.160.118|WHEN:20110222|SERVER:www.custompotrack.com|REASON:robots.txt
WATCH|IP:69.43.160.96|WHEN:20110222|SERVER:custompotrack.com|REASON:robots.txt
WATCH|IP:69.43.160.96|WHEN:20110222|SERVER:www.custompotrack.com|REASON:robots.txt
WATCH|IP:69.47.236.144|WHEN:20110221|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:69.51.161.170|WHEN:20110208|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:69.51.163.156|WHEN:20110221|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:69.58.178.56|WHEN:20110203|SERVER:m.2behip.com|REASON:robots.txt
WATCH|IP:69.58.178.57|WHEN:20110214|SERVER:m.alaskatropicalfish.com|REASON:robots.txt
WATCH|IP:69.58.178.58|WHEN:20110211|SERVER:www.wt6000windturbines.com|REASON:robots.txt
WATCH|IP:69.58.178.58|WHEN:20110211|SERVER:www.zephrairguns.com|REASON:robots.txt
WATCH|IP:69.58.178.59|WHEN:20110203|SERVER:m.bigbowling.com|REASON:robots.txt
WATCH|IP:69.58.178.59|WHEN:20110218|SERVER:www.skinshoprx.com|REASON:robots.txt
WATCH|IP:69.58.178.59|WHEN:20110218|SERVER:www.themelodyclockchoice.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110208|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110218|SERVER:www.hotsaucehawaii.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110218|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110218|SERVER:www.motorcowboy.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110218|SERVER:www.nyciwear.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110218|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110218|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110218|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110218|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110219|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110219|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110219|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110219|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110219|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110222|SERVER:www.americanguitarandband.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110222|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110222|SERVER:www.oktoberfesthaus.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110222|SERVER:www.outdoorgearcompany.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110222|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110222|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:69.63.177.121|WHEN:20110222|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110207|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110208|SERVER:www.beachboysstore.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110208|SERVER:www.westkycustoms.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110208|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110209|SERVER:www.irresistables.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110209|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110213|SERVER:www.beachboysstore.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110213|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110214|SERVER:www.beltsdirect.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110215|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110215|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110215|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110215|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110216|SERVER:sassyassybjeans.zoovy.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110216|SERVER:www.furthurstore.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110216|SERVER:www.inflatablessuperstore.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110216|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110216|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110216|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110216|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110217|SERVER:agandb.zoovy.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110217|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110217|SERVER:www.bradrobertsag.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110217|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110217|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110217|SERVER:www.irresistables.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110217|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110217|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110217|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110217|SERVER:www.yocaps.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110218|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110218|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110218|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110218|SERVER:www.surfingmaster.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110219|SERVER:www.bikinimo.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110219|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110219|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110222|SERVER:americanguitarandband.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110222|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:69.63.177.122|WHEN:20110222|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110209|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110209|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110209|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110210|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110210|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110212|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110215|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110215|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110215|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110215|SERVER:www.mainemapleandhoney.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110215|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110215|SERVER:www.speedaddictcycles.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110215|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:agandb.zoovy.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:orangeonions.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.finalegloves.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.kidscraftsplus.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.passionfirediamonds.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.shelterdist.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.zephyrskateboards.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110216|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110217|SERVER:sassyassybjeans.zoovy.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110217|SERVER:www.austinbazaar.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110217|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110217|SERVER:www.furthurstore.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110217|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110217|SERVER:www.speedaddictcycles.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110218|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110218|SERVER:www.caboots.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110218|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110218|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110218|SERVER:www.speedygoods.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110218|SERVER:www.topgearleather.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110219|SERVER:caboots.zoovy.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110219|SERVER:www.alanagracestore.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110219|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110219|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110222|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110222|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110222|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:69.63.177.123|WHEN:20110222|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:69.64.130.34|WHEN:20110216|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:69.64.67.33|WHEN:20110204|SERVER:www.topgearleather.com|REASON:robots.txt
WATCH|IP:69.96.68.103|WHEN:20110202|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:69.96.68.103|WHEN:20110202|SERVER:www.holsterz.com|REASON:robots.txt
WATCH|IP:70.102.216.250|WHEN:20110211|SERVER:www.shelterdist.com|REASON:robots.txt
WATCH|IP:70.130.171.229|WHEN:20110216|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:70.143.95.189|WHEN:20110202|SERVER:www.blitzinc.net|REASON:robots.txt
WATCH|IP:70.143.95.189|WHEN:20110202|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:70.143.95.189|WHEN:20110202|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:70.143.95.189|WHEN:20110202|SERVER:www.furniture-online.com|REASON:robots.txt
WATCH|IP:70.143.95.189|WHEN:20110202|SERVER:www.itascamoccasin.com|REASON:robots.txt
WATCH|IP:70.148.243.204|WHEN:20110202|SERVER:www.blitzinc.net|REASON:robots.txt
WATCH|IP:70.154.194.154|WHEN:20110216|SERVER:racerwalsh.zoovy.com|REASON:robots.txt
WATCH|IP:70.154.194.154|WHEN:20110218|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:70.154.194.154|WHEN:20110221|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:70.166.105.143|WHEN:20110210|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:70.166.119.235|WHEN:20110221|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:70.166.89.59|WHEN:20110207|SERVER:www.aromaspa.net|REASON:robots.txt
WATCH|IP:70.166.89.59|WHEN:20110207|SERVER:www.aromaspas.com|REASON:robots.txt
WATCH|IP:70.166.89.59|WHEN:20110207|SERVER:www.michaelscookies.com|REASON:robots.txt
WATCH|IP:70.171.135.243|WHEN:20110214|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:70.176.9.87|WHEN:20110218|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110219|SERVER:www.froggysfog.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110219|SERVER:www.orleanscandles.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110219|SERVER:www.raku-art.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110219|SERVER:www.specialtyfoodshawaii.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:instantgaragesales.zoovy.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.4golftraining.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.ahlersgifts.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.beincogneato.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.campaign-printing.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.chiquelife.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.chique-plus.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.daceenterprises.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.envirovogue.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.riascrazydeals.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.riderswraps.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.riderswrapswholesale.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.round2store.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.smarterlight.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.sourcetropical.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.thebabycompany.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.trainingsmoke.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.tshirtsmall.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.wallsthatspeak.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110220|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110221|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110221|SERVER:www.fleurdelisdirect.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110221|SERVER:www.goorganics.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110221|SERVER:www.greatloanz.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110221|SERVER:www.hotsaucehawaii.com|REASON:robots.txt
WATCH|IP:70.183.106.55|WHEN:20110221|SERVER:www.hotwaterstuff.com|REASON:robots.txt
WATCH|IP:70.188.61.166|WHEN:20110201|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:70.22.251.242|WHEN:20110206|SERVER:www.amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:70.252.56.174|WHEN:20110201|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:70.26.89.73|WHEN:20110206|SERVER:ironwinecellardoors.com|REASON:robots.txt
WATCH|IP:70.60.90.83|WHEN:20110222|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:70.79.139.242|WHEN:20110210|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:70.89.94.237|WHEN:20110210|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:71.100.136.27|WHEN:20110203|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:71.100.136.27|WHEN:20110204|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:71.121.242.114|WHEN:20110215|SERVER:www.christmasstorage.com|REASON:robots.txt
WATCH|IP:71.146.22.115|WHEN:20110206|SERVER:www.boyceimage.com|REASON:robots.txt
WATCH|IP:71.146.22.115|WHEN:20110210|SERVER:www.boyceimage.com|REASON:robots.txt
WATCH|IP:71.196.10.254|WHEN:20110203|SERVER:www.caboots.com|REASON:robots.txt
WATCH|IP:71.196.10.254|WHEN:20110204|SERVER:www.reefs2go.com|REASON:robots.txt
WATCH|IP:71.197.70.169|WHEN:20110205|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:71.200.208.234|WHEN:20110220|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:71.207.58.28|WHEN:20110213|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:71.217.75.173|WHEN:20110205|SERVER:www.lanfairsystems.com|REASON:robots.txt
WATCH|IP:71.217.75.173|WHEN:20110205|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:71.217.75.173|WHEN:20110206|SERVER:www.lanfairsystems.com|REASON:robots.txt
WATCH|IP:71.217.75.173|WHEN:20110206|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:71.221.142.4|WHEN:20110207|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:71.221.142.4|WHEN:20110210|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:71.225.117.123|WHEN:20110214|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:71.227.155.47|WHEN:20110207|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:71.227.41.91|WHEN:20110218|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:71.35.174.125|WHEN:20110214|SERVER:outpost.zoovy.com|REASON:robots.txt
WATCH|IP:71.35.175.251|WHEN:20110201|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:71.36.109.203|WHEN:20110215|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:71.40.244.69|WHEN:20110214|SERVER:www.airwaterice.com|REASON:robots.txt
WATCH|IP:71.42.153.33|WHEN:20110206|SERVER:www.paintsprayersplus.com|REASON:robots.txt
WATCH|IP:71.50.55.64|WHEN:20110211|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:71.50.55.64|WHEN:20110211|SERVER:www.italianseedandtool.com|REASON:robots.txt
WATCH|IP:71.71.207.163|WHEN:20110209|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:71.71.207.163|WHEN:20110218|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:71.77.38.8|WHEN:20110202|SERVER:www.rcusa.com|REASON:robots.txt
WATCH|IP:71.88.113.146|WHEN:20110213|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:71.88.113.146|WHEN:20110214|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:71.91.216.104|WHEN:20110222|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:72.129.249.21|WHEN:20110208|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:72.129.249.21|WHEN:20110217|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110203|SERVER:affordableproducts.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110203|SERVER:allpetsolutions.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110203|SERVER:www.affordablechristianproducts.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110206|SERVER:affordableproducts.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110206|SERVER:bigbowling.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110206|SERVER:gkworld.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110206|SERVER:greatlookz.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110206|SERVER:www.affordablechristianproducts.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110206|SERVER:www.finalegloves.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110206|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110206|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110207|SERVER:creme.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110207|SERVER:electronics4u.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110207|SERVER:fairwaymarketing.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110207|SERVER:frontierleathers.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110207|SERVER:kelhampolishpottery.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110207|SERVER:potterycorner.zoovy.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110207|SERVER:www.affordablechristianproducts.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110207|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:72.13.84.94|WHEN:20110207|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:72.14.164.129|WHEN:20110215|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:72.14.164.131|WHEN:20110210|SERVER:www.furniture-online.com|REASON:robots.txt
WATCH|IP:72.14.164.131|WHEN:20110221|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:72.14.164.132|WHEN:20110204|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:72.14.164.136|WHEN:20110210|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:72.14.164.137|WHEN:20110216|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:72.14.164.139|WHEN:20110205|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:72.14.164.143|WHEN:20110222|SERVER:www.2bhipgifts.com|REASON:robots.txt
WATCH|IP:72.14.164.148|WHEN:20110208|SERVER:www.bikinimo.com|REASON:robots.txt
WATCH|IP:72.14.164.148|WHEN:20110216|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.14.164.148|WHEN:20110222|SERVER:www.heavydutymats.com|REASON:robots.txt
WATCH|IP:72.14.164.150|WHEN:20110220|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:72.14.164.154|WHEN:20110218|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:72.14.164.155|WHEN:20110218|SERVER:www.elegantquilling.com|REASON:robots.txt
WATCH|IP:72.14.164.157|WHEN:20110204|SERVER:www.bikinimo.com|REASON:robots.txt
WATCH|IP:72.14.164.158|WHEN:20110204|SERVER:www.europottery.com|REASON:robots.txt
WATCH|IP:72.14.164.158|WHEN:20110221|SERVER:www.worldsbestmats.com|REASON:robots.txt
WATCH|IP:72.14.164.160|WHEN:20110210|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:72.14.164.163|WHEN:20110203|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:72.14.164.164|WHEN:20110220|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:72.14.164.166|WHEN:20110206|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:72.14.164.169|WHEN:20110207|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:72.14.164.172|WHEN:20110204|SERVER:www.costumesltd.com|REASON:robots.txt
WATCH|IP:72.14.164.172|WHEN:20110206|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:72.14.164.172|WHEN:20110217|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:72.14.164.172|WHEN:20110221|SERVER:www.furniture-online.com|REASON:robots.txt
WATCH|IP:72.14.164.179|WHEN:20110206|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:72.14.164.181|WHEN:20110216|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:72.14.164.181|WHEN:20110217|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:72.14.164.181|WHEN:20110220|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:72.14.164.185|WHEN:20110212|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:72.14.164.186|WHEN:20110215|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:72.14.164.187|WHEN:20110219|SERVER:www.custompotrack.com|REASON:robots.txt
WATCH|IP:72.14.164.191|WHEN:20110221|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:72.14.164.193|WHEN:20110204|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:72.14.164.194|WHEN:20110201|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:72.14.164.194|WHEN:20110205|SERVER:www.flagsonastick.com|REASON:robots.txt
WATCH|IP:72.14.164.195|WHEN:20110205|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:72.14.164.195|WHEN:20110208|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:72.14.164.200|WHEN:20110219|SERVER:www.buyoktoberfestcostumes.com|REASON:robots.txt
WATCH|IP:72.174.165.179|WHEN:20110222|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:72.187.160.128|WHEN:20110212|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:72.187.160.128|WHEN:20110214|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:72.187.160.128|WHEN:20110222|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110202|SERVER:secondact.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110202|SERVER:softenerparts.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110202|SERVER:www.softnerparts.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110203|SERVER:diamondpenterprises.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110203|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110204|SERVER:bestdealsontheplanet.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110204|SERVER:thechessstore.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110205|SERVER:www.gss-store.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110205|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110205|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110206|SERVER:logicbox.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110206|SERVER:nubrain.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110206|SERVER:toolprice.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110206|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110206|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110208|SERVER:bluelightning.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110208|SERVER:thecandlemakersstore.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110208|SERVER:tjformal.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110208|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110208|SERVER:www.thecandlemakersstore.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110209|SERVER:performancepda.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110209|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110210|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110212|SERVER:pacificpetshop.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110212|SERVER:www.oldcookbooks.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110212|SERVER:www.softenerparts.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110212|SERVER:www.softnerparts.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110213|SERVER:www.dianayvonne.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110213|SERVER:www.dreamwaytrading.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110213|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110214|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110214|SERVER:www.carmobileaudiovideo.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110218|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110218|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110219|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110220|SERVER:floattech.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.44|WHEN:20110222|SERVER:thechessstore.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110201|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110203|SERVER:www.hdesk.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110205|SERVER:mytexaswarehouse.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110205|SERVER:theauto.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110205|SERVER:www.naturalcuresstore.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110206|SERVER:fibermaven.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110206|SERVER:nubrain.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110206|SERVER:www.bargaincds.biz|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110210|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110211|SERVER:www.bargaincds.biz|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110212|SERVER:caboots.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110212|SERVER:smyrnacoin.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110212|SERVER:www.smyrnacoin.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110212|SERVER:www.theoverstockedkitchen.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110213|SERVER:judysnet.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110213|SERVER:www.laartwork.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110213|SERVER:www.laartwork.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110219|SERVER:blueheadsets.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110219|SERVER:cashmereelite.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110219|SERVER:tekdeal.zoovy.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110220|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:72.19.185.45|WHEN:20110220|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:72.204.92.231|WHEN:20110204|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:72.219.231.42|WHEN:20110206|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:72.223.45.18|WHEN:20110221|SERVER:www.rainbowcustomcars.com|REASON:robots.txt
WATCH|IP:72.36.114.4|WHEN:20110204|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.4|WHEN:20110205|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.4|WHEN:20110205|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:72.36.114.4|WHEN:20110205|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.4|WHEN:20110206|SERVER:www.alternativedvd.com|REASON:robots.txt
WATCH|IP:72.36.114.4|WHEN:20110206|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.4|WHEN:20110206|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:72.36.114.4|WHEN:20110206|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.4|WHEN:20110209|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:72.36.114.4|WHEN:20110212|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110202|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110205|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110205|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110206|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110206|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110206|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110206|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110207|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110209|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110210|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110212|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110212|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110213|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110213|SERVER:www.completecarecenters.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110213|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110213|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110216|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110216|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110217|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110218|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110219|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110220|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110220|SERVER:www.completecarecenters.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110220|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110220|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110220|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110220|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110221|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.5|WHEN:20110222|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110202|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110203|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110204|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110204|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110205|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110205|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110205|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110205|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110206|SERVER:www.completecarecenters.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110206|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110206|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110206|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110206|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110208|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110209|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110209|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110212|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110212|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110213|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110213|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110213|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110213|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110213|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110214|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110214|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110214|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110215|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110216|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110216|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110216|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110217|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110217|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110219|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110219|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110219|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110220|SERVER:www.alternativedvd.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110220|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110220|SERVER:www.completecarecenters.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110220|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110220|SERVER:www.electronicsdirectusa.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110220|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110220|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110220|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110221|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110221|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110222|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:72.36.114.6|WHEN:20110222|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110204|SERVER:therestlessmouse.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110204|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110206|SERVER:therestlessmouse.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110206|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110211|SERVER:therestlessmouse.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110211|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110212|SERVER:therestlessmouse.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110212|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110213|SERVER:therestlessmouse.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110213|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110214|SERVER:silverpcs.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110217|SERVER:silverpcs.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110217|SERVER:therestlessmouse.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110217|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110221|SERVER:silverpcs.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110221|SERVER:therestlessmouse.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110221|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110222|SERVER:silverpcs.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110222|SERVER:therestlessmouse.zoovy.com|REASON:robots.txt
WATCH|IP:72.36.94.20|WHEN:20110222|SERVER:www.thatrestlessmouse.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110202|SERVER:skatebrake.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110202|SERVER:www.celtictenorsstore.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110203|SERVER:bigbowling.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110203|SERVER:m.kidsafeinc.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110203|SERVER:thebbstore.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110203|SERVER:youpackyousave.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110204|SERVER:truckaccessoryguy.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110205|SERVER:www.greatwholesalez.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110207|SERVER:courtneybrooke.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110207|SERVER:garnett122.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110207|SERVER:www.quemex.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110207|SERVER:www.rettacarol.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110208|SERVER:www.thebeltbucklestore.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110209|SERVER:ghostinc.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110209|SERVER:www.protectmycamera.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110210|SERVER:inkjetcloseouts.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110210|SERVER:itascamoccasin.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110210|SERVER:www.teramasu-scarf.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110211|SERVER:klatchroasting.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110211|SERVER:sundaros.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110211|SERVER:www.standsbyriver.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110212|SERVER:www.dynamicsurplus.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110212|SERVER:www.nahobbies.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110212|SERVER:www.toolprice.net|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110213|SERVER:www.smyrnacoin.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110213|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110214|SERVER:guitarelectronics.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110214|SERVER:lifebookkeepsakes.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110215|SERVER:bbbauctions.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110215|SERVER:qcollectionjunior.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110215|SERVER:surfcityinstruments.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110215|SERVER:www.lisabeads.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110216|SERVER:www.carmobilevideo.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110218|SERVER:missdeb1125.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110218|SERVER:www.sneakercloset.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110220|SERVER:amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110220|SERVER:gkworld.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110220|SERVER:mailboxmusic.zoovy.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110220|SERVER:shelterdist.com|REASON:robots.txt
WATCH|IP:72.51.47.138|WHEN:20110222|SERVER:www.naturalcuresstore.com|REASON:robots.txt
WATCH|IP:72.5.29.5|WHEN:20110202|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:72.5.29.5|WHEN:20110208|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:72.5.29.5|WHEN:20110212|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:72.5.29.5|WHEN:20110215|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:74.102.193.203|WHEN:20110217|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:74.106.226.109|WHEN:20110204|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110201|SERVER:www.agandb.zoovy.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110201|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110202|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110202|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110202|SERVER:www.usavem.zoovy.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110203|SERVER:www.licenseplateframes.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110203|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110204|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110204|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110204|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110206|SERVER:www.shopvelvethanger.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110207|SERVER:www.2bhip.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110207|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110208|SERVER:www.securityvideosolutions.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110208|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110209|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110209|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110210|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110210|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110211|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110211|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110211|SERVER:www.shopvelvethanger.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110211|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110211|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110212|SERVER:www.nyciwear.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110213|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110214|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110214|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110214|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110215|SERVER:orangeonions.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110215|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110216|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110216|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110216|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110216|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110216|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110217|SERVER:www.bibshoppe.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110218|SERVER:www.agandb.zoovy.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110218|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110218|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110219|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110222|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:74.112.128.60|WHEN:20110222|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110201|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110201|SERVER:www.radusadirect.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110202|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110203|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110203|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110203|SERVER:www.licenseplateframes.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110203|SERVER:www.nyciwear.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110205|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110207|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110208|SERVER:www.marcelhomedecor.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110209|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110210|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110210|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110210|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110210|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110212|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110214|SERVER:orangeonions.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110214|SERVER:www.thecandlemakersstore.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110215|SERVER:spa.gogoods.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110215|SERVER:www.spa.gogoods.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110215|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110216|SERVER:www.2bhiptshirts.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110216|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110216|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110217|SERVER:www.bibshoppe.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110217|SERVER:www.columbiasportsonline.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110218|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110218|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110218|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110218|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110218|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110220|SERVER:www.froggysfog.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110221|SERVER:www.4my3boyz.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110221|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110221|SERVER:www.shopvelvethanger.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110221|SERVER:www.skullplanet.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110221|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110222|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110222|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110222|SERVER:www.racewax.com|REASON:robots.txt
WATCH|IP:74.112.128.61|WHEN:20110222|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110201|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110202|SERVER:www.doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110202|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110203|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110203|SERVER:www.licenseplateframes.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110204|SERVER:www.shopvelvethanger.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110204|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110204|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110207|SERVER:www.columbiasportsonline.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110208|SERVER:studiohut.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110208|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110208|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110208|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110209|SERVER:www.agandb.zoovy.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110209|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110210|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110210|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110210|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110210|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110210|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110211|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110211|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110211|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110213|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110214|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110214|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110214|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110215|SERVER:www.bikinimo.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110215|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110215|SERVER:www.radusadirect.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110215|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110216|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110216|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110216|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110216|SERVER:www.zephyrairsoft.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110216|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110217|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110218|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110218|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110218|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110219|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110220|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110220|SERVER:www.securityvideosolutions.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110221|SERVER:eaglelight.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110221|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110222|SERVER:racewax.com|REASON:robots.txt
WATCH|IP:74.112.128.62|WHEN:20110222|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:74.115.209.185|WHEN:20110202|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:74.140.12.113|WHEN:20110211|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:74.164.207.202|WHEN:20110202|SERVER:www.speedaddictcycles.com|REASON:robots.txt
WATCH|IP:74.177.89.172|WHEN:20110219|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:74.178.170.188|WHEN:20110203|SERVER:www.4my3boyz.com|REASON:robots.txt
WATCH|IP:74.184.184.54|WHEN:20110219|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:74.185.12.24|WHEN:20110214|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:74.201.220.49|WHEN:20110209|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:74.53.124.232|WHEN:20110209|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:74.60.209.185|WHEN:20110218|SERVER:www.replaceyourcell.com|REASON:robots.txt
WATCH|IP:74.96.236.154|WHEN:20110215|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:74.97.96.188|WHEN:20110212|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:74.98.230.237|WHEN:20110213|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:75.127.194.123|WHEN:20110208|SERVER:www.f2ptechnologies.com|REASON:robots.txt
WATCH|IP:75.127.65.162|WHEN:20110203|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:75.134.180.173|WHEN:20110209|SERVER:www.stmparts.com|REASON:robots.txt
WATCH|IP:75.134.97.81|WHEN:20110206|SERVER:heavydutymats.com|REASON:robots.txt
WATCH|IP:75.134.97.81|WHEN:20110206|SERVER:www.heavydutymats.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110220|SERVER:www.blitzinc.net|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110220|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110220|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110220|SERVER:www.furniture-online.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110220|SERVER:www.ironstoneimports.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110220|SERVER:www.kidsbargains.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110220|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110220|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110220|SERVER:www.womensyogasportsapparel.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:crunruh.zoovy.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:furniture-online.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:leos.zoovy.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:www.flagsonastick.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:www.ironstoneimports.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:www.outofthetoybox.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:www.polishkitchenonline.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110221|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110222|SERVER:www.blitzinc.net|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110222|SERVER:www.furniture-online.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110222|SERVER:www.ironstoneimports.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110222|SERVER:www.logfurnituresite.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110222|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110222|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:75.141.195.195|WHEN:20110222|SERVER:www.womensyogasportsapparel.com|REASON:robots.txt
WATCH|IP:75.141.235.150|WHEN:20110215|SERVER:www.kcint2.com|REASON:robots.txt
WATCH|IP:75.141.235.150|WHEN:20110217|SERVER:ssl.zoovy.com|REASON:robots.txt
WATCH|IP:75.141.235.150|WHEN:20110217|SERVER:www.kcint2.com|REASON:robots.txt
WATCH|IP:75.146.107.238|WHEN:20110210|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:75.16.181.80|WHEN:20110219|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:75.199.8.232|WHEN:20110208|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:75.199.8.232|WHEN:20110208|SERVER:www.holsterz.com|REASON:robots.txt
WATCH|IP:75.205.19.107|WHEN:20110215|SERVER:www.oldcookbooks.com|REASON:robots.txt
WATCH|IP:75.222.19.44|WHEN:20110203|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:75.222.19.44|WHEN:20110203|SERVER:www.holsterz.com|REASON:robots.txt
WATCH|IP:75.38.62.78|WHEN:20110222|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:75.42.190.142|WHEN:20110202|SERVER:www.greatgemz.com|REASON:robots.txt
WATCH|IP:75.42.190.142|WHEN:20110205|SERVER:www.completecarecenters.com|REASON:robots.txt
WATCH|IP:75.42.190.142|WHEN:20110205|SERVER:www.ctechnologies.net|REASON:robots.txt
WATCH|IP:75.42.190.142|WHEN:20110205|SERVER:www.rcusa.com|REASON:robots.txt
WATCH|IP:75.42.190.142|WHEN:20110206|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:75.76.207.102|WHEN:20110215|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:75.80.198.154|WHEN:20110201|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:75.80.8.222|WHEN:20110208|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:76.104.23.210|WHEN:20110204|SERVER:www.kcint2.com|REASON:robots.txt
WATCH|IP:76.105.98.17|WHEN:20110212|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:76.11.107.22|WHEN:20110214|SERVER:www.tatianafashions.com|REASON:robots.txt
WATCH|IP:76.113.100.82|WHEN:20110214|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:76.122.22.236|WHEN:20110207|SERVER:www.westkycustoms.com|REASON:robots.txt
WATCH|IP:76.122.5.74|WHEN:20110201|SERVER:www.paintsprayersplus.com|REASON:robots.txt
WATCH|IP:76.122.5.74|WHEN:20110203|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:76.168.5.211|WHEN:20110206|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110202|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110203|SERVER:www.hausfortuna.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110203|SERVER:www.zephyrairsoft.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110204|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110204|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110204|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110205|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110207|SERVER:www.allvelvet.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110207|SERVER:www.dianayvonne.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110209|SERVER:www.bellydancefabric.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110210|SERVER:www.2bhip.com|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110210|SERVER:www.coolstuff4u.net|REASON:robots.txt
WATCH|IP:76.173.15.221|WHEN:20110211|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110212|SERVER:www.michaelscookies.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110213|SERVER:www.doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110213|SERVER:www.ktapeonline.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110213|SERVER:www.oldcookbooks.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110213|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110214|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110214|SERVER:www.furniture-online.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110214|SERVER:www.redrive.net|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110214|SERVER:www.thescrapqueen.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110215|SERVER:www.daceenterprises.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110215|SERVER:www.dollhousesandmore.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110215|SERVER:www.f2ptechnologies.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110215|SERVER:www.rhythmfusion.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110218|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110219|SERVER:www.blackhawksshop.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110219|SERVER:www.denimsquare.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110219|SERVER:www.zephyrairguns.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110219|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:76.173.15.53|WHEN:20110221|SERVER:www.spapumps.com|REASON:robots.txt
WATCH|IP:76.173.204.158|WHEN:20110209|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:76.173.204.158|WHEN:20110210|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:76.174.222.170|WHEN:20110218|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:76.199.1.81|WHEN:20110201|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:76.25.53.112|WHEN:20110218|SERVER:www.plumbsource.net|REASON:robots.txt
WATCH|IP:76.73.159.117|WHEN:20110203|SERVER:www.hbdrums.com|REASON:robots.txt
WATCH|IP:76.84.20.132|WHEN:20110212|SERVER:www.toolprice.net|REASON:robots.txt
WATCH|IP:76.94.176.194|WHEN:20110211|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:76.94.176.194|WHEN:20110219|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:76.97.117.56|WHEN:20110203|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:76.97.117.56|WHEN:20110205|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:76.97.117.56|WHEN:20110209|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:77.103.152.142|WHEN:20110217|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:77.233.225.110|WHEN:20110201|SERVER:www.alternativedvd.com|REASON:robots.txt
WATCH|IP:77.255.101.1|WHEN:20110206|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:77.44.4.90|WHEN:20110203|SERVER:www.smarterlight.com|REASON:robots.txt
WATCH|IP:77.51.250.2|WHEN:20110213|SERVER:crunruh.com|REASON:robots.txt
WATCH|IP:77.51.250.2|WHEN:20110213|SERVER:www.crunruh.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110202|SERVER:www.perfumecenteronline.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110203|SERVER:www.perfumecenteronline.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110206|SERVER:leos.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110209|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110209|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110209|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110209|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110209|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110209|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110209|SERVER:www.miniatureguitaroutlet.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110209|SERVER:www.ornamentsafe.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.austinbazaar.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.berniessmellsnbells.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.naturalcuresstore.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.oldcookbooks.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.polishkitchenonline.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.prostreetlighting.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.silverfair.us|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.speedaddictcycles.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.wallsthatspeak.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110210|SERVER:www.zephyrairsoft.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:amplified.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:audiovideo.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:brandnamebeauty.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:gearlabs.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:jordanindustrial.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:partyhats.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:scheerwholesale.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:silvermoonjewlery.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:thesavewave.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:tidewatersports.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:titanglobal.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.4golftraining.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.blitzinc.net|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.cbpots.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.cdphonehome.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.coastalbaycompany.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.collectors-outpost.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.costumesurplus.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.covisec.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.custompotrack.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.dealz4real.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.denimway.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.ezmiser.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.fashionmonsters.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.firefoxtechnologies.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.flagsonastick.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.froggysfog.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.goshotcamera.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.independent.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.instantgaragesales.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.kiwikidsgear.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.loblollyskitchen.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.outdoorgearcompany.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.paintballgodz.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.powersportsoutletstore.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.pulsartech.net|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.qualityprice.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.quantumjewelry.zoovy.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.robdiamond.net|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.rockmusiccreations.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.stewarttoys.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.tatianabras.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.wildcollections.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110211|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110217|SERVER:www.perfumecenteronline.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110218|SERVER:www.perfumecenteronline.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110219|SERVER:www.perfumecenteronline.com|REASON:robots.txt
WATCH|IP:77.68.105.51|WHEN:20110220|SERVER:leos.zoovy.com|REASON:robots.txt
WATCH|IP:78.101.74.172|WHEN:20110220|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:78.101.74.172|WHEN:20110220|SERVER:zestcandle.com|REASON:robots.txt
WATCH|IP:78.12.165.1|WHEN:20110208|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:78.179.181.101|WHEN:20110203|SERVER:soundmart.zoovy.com|REASON:robots.txt
WATCH|IP:78.2.8.27|WHEN:20110215|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:78.50.20.40|WHEN:20110214|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110201|SERVER:rays.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110203|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110203|SERVER:www.konrads.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110204|SERVER:www.beltsdirect.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110205|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110205|SERVER:www.raku-art.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110207|SERVER:www.europottery.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110211|SERVER:fairwaymarketing.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110211|SERVER:sacredengraving.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110211|SERVER:www.hotsaucehawaii.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110211|SERVER:www.jimsbigstore.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110212|SERVER:www.amigaz.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110212|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110212|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110213|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110214|SERVER:affordableproducts.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110214|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110214|SERVER:www.italianseedandtool.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110214|SERVER:www.powerlandonline.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110215|SERVER:dollssoreal.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110215|SERVER:www.mosaictile.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110215|SERVER:www.ornamentsafe.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110215|SERVER:www.spapartsdepot.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110215|SERVER:yesterdaysthings.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110216|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110216|SERVER:smyrnacoin.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110216|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110216|SERVER:www.stewarttoys.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110216|SERVER:www.tatianabras.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110217|SERVER:greatlookz.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110217|SERVER:www.digmodern.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110217|SERVER:www.ibuysolarpanels.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110217|SERVER:www.itascamoccasin.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110217|SERVER:www.leisureforwomen.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110217|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110218|SERVER:www.blitzinc.net|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110218|SERVER:www.dhsproducts.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110218|SERVER:www.sewkool.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110219|SERVER:thebunkhouse.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110220|SERVER:allpetsolutions.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110220|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110220|SERVER:www.amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110220|SERVER:www.cbpots.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110220|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110220|SERVER:www.qcollectionjunior.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110221|SERVER:rays.zoovy.com|REASON:robots.txt
WATCH|IP:78.5.250.218|WHEN:20110221|SERVER:www.berniessmellsnbells.com|REASON:robots.txt
WATCH|IP:78.92.40.100|WHEN:20110216|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:79.11.56.142|WHEN:20110218|SERVER:www.dolldreams.net|REASON:robots.txt
WATCH|IP:79.116.77.17|WHEN:20110207|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:79.117.29.221|WHEN:20110202|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:79.117.35.130|WHEN:20110202|SERVER:allpetsolutions.zoovy.com|REASON:robots.txt
WATCH|IP:79.160.180.21|WHEN:20110208|SERVER:www.cmamusicfeststore.com|REASON:robots.txt
WATCH|IP:79.166.108.115|WHEN:20110222|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:79.166.87.84|WHEN:20110219|SERVER:kidsafeinc.com|REASON:robots.txt
WATCH|IP:79.166.87.84|WHEN:20110219|SERVER:summitfashions.com|REASON:robots.txt
WATCH|IP:79.166.87.84|WHEN:20110222|SERVER:www.prostreetlighting.com|REASON:robots.txt
WATCH|IP:79.167.113.41|WHEN:20110222|SERVER:soundmart.zoovy.com|REASON:robots.txt
WATCH|IP:79.167.113.41|WHEN:20110222|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:79.172.193.105|WHEN:20110205|SERVER:www.jdhines.com|REASON:robots.txt
WATCH|IP:79.176.36.32|WHEN:20110214|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:79.180.8.164|WHEN:20110202|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:79.254.22.129|WHEN:20110202|SERVER:www.motorcowboy.com|REASON:robots.txt
WATCH|IP:79.85.53.29|WHEN:20110210|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:79.85.53.29|WHEN:20110211|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:79.85.53.29|WHEN:20110212|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:79.85.53.29|WHEN:20110213|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:80.123.113.166|WHEN:20110219|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:80.162.54.39|WHEN:20110217|SERVER:www.handsnpaws.com|REASON:robots.txt
WATCH|IP:80.252.171.68|WHEN:20110213|SERVER:beechmontporsche.zoovy.com|REASON:robots.txt
WATCH|IP:80.66.89.148|WHEN:20110208|SERVER:www.thegiftmallonline.com|REASON:robots.txt
WATCH|IP:80.79.202.10|WHEN:20110220|SERVER:ssl.zoovy.com|REASON:robots.txt
WATCH|IP:80.79.202.10|WHEN:20110220|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:80.79.202.10|WHEN:20110220|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:80.79.202.10|WHEN:20110221|SERVER:www.babology.com|REASON:robots.txt
WATCH|IP:80.79.202.10|WHEN:20110221|SERVER:www.oldcookbooks.com|REASON:robots.txt
WATCH|IP:80.96.67.77|WHEN:20110206|SERVER:thatchandbamboo.com|REASON:robots.txt
WATCH|IP:80.96.67.77|WHEN:20110206|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:80.96.67.77|WHEN:20110207|SERVER:thatchandbamboo.com|REASON:robots.txt
WATCH|IP:80.96.67.77|WHEN:20110207|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:81.144.182.244|WHEN:20110209|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:81.144.182.244|WHEN:20110210|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:81.144.182.244|WHEN:20110211|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:81.187.221.120|WHEN:20110218|SERVER:kidsafeinc.com|REASON:robots.txt
WATCH|IP:81.187.221.120|WHEN:20110218|SERVER:summitfashions.com|REASON:robots.txt
WATCH|IP:81.187.221.120|WHEN:20110218|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:81.187.221.120|WHEN:20110218|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:81.187.221.120|WHEN:20110219|SERVER:m.kidsafeinc.com|REASON:robots.txt
WATCH|IP:81.187.221.120|WHEN:20110219|SERVER:m.summitfashions.com|REASON:robots.txt
WATCH|IP:81.187.221.120|WHEN:20110219|SERVER:www.buddyguystore.com|REASON:robots.txt
WATCH|IP:81.187.221.120|WHEN:20110219|SERVER:www.jakeowenstore.com|REASON:robots.txt
WATCH|IP:81.187.221.120|WHEN:20110219|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:81.187.221.120|WHEN:20110219|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110201|SERVER:jadeboutique.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110202|SERVER:gkworld.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110202|SERVER:jadeboutique.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110203|SERVER:www.dollhousesandmore.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110205|SERVER:gkworld.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110207|SERVER:jadeboutique.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110211|SERVER:gkworld.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110212|SERVER:jadeboutique.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110213|SERVER:gkworld.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110214|SERVER:gkworld.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110220|SERVER:gkworld.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110221|SERVER:gkworld.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110221|SERVER:jadeboutique.com|REASON:robots.txt
WATCH|IP:81.19.67.243|WHEN:20110222|SERVER:gkworld.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:bigbowling.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:caboots.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:crite2000.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:dollssoreal.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:dollstreet.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:quantumjewelry.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:rockfetish.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:surfcityinstruments.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:surfcitymusic.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:toyoursuccess.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:unicorngifts.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.airwaterice.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.arjanusa.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.atlanticgolfshop.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.austinbazaar.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.battlewagon-bits.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.bladesandgear.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.buddyguystore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.crite2000.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.euro.halebobstore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.irresistables.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.jimsbigstore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.kryptapparel.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.mosaictile.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.rufusdawg.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.shop.beechmontmotors.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.shopvelvethanger.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.skullplanet.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.surfcityinstruments.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.thecandlemakersstore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110205|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:espressoparts2.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:fairwaymarketing.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:firefoxtechnologies.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:greatlookz.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:larsenracing.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:nerdgear.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:www.dollstreet.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:www.greatwholesalez.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:www.kiwikidsgear.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:www.speedaddictcycles.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110206|SERVER:zephyrpaintball.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:888knivesrus.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:bigbowling.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:caboots.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:colocustommetal.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:crite2000.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:dollssoreal.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:dollstreet.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:firefoxtechnologies.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:kyledesign.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:thebunkhouse.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:wirelessvideocameras.net|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.atlanticgolfshop.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.battlewagon-bits.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.bboyworldshop.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.bladesandgear.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.crite2000.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.euro.halebobstore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.guitarelectronics.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.irresistables.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.jimsbigstore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.konrads.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.modernmini.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.mosaictile.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.robdiamond.net|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.rufusdawg.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.shopvelvethanger.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.surfcityinstruments.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.thecandlemakersstore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.usavem.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:www.xtremedeal4u.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110212|SERVER:zephyrpaintball.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:allpetsolutions.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:cbpots.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:espressoparts2.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:fairwaymarketing.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:greatlookz.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:larsenracing.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:nerdgear.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:oaktree.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:sacredengraving.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:www.berenguerdolls.net|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:www.craftersnet.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:www.dollstreet.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:www.greatwholesalez.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:www.kiwikidsgear.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:www.underthesuncollectibles.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110213|SERVER:yesterdaysthings.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:caboots.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:crite2000.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:dollssoreal.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:furniture-online.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:guitarelectronics.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:incipiodirect.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:outofthetoybox.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:surfcitymusic.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:thebunkhouse.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:toolprice.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:toynk.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.amigaz.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.bboyworldshop.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.bloomersnbows.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.bwbits.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.caboots.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.crite2000.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.elegantbed.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.expedition-imports.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.jewelville.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.konrads.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.luggage4less.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.modernmini.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.riascrazydeals.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.ribbontrade.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.robdiamond.net|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.sewkool.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.silverchicks.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.speedygoods.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.spruebrothers.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.tting.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.xtremedeal4u.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110219|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:888knivesrus.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:allpetsolutions.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:cbpots.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:dollstreet.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:espressoparts2.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:fairwaymarketing.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:firefoxtechnologies.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:greatlookz.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:nerdgear.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:oaktree.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:sacredengraving.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:www.berenguerdolls.net|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:www.craftersnet.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:www.dollstreet.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:www.greatwholesalez.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:www.rcusa.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:www.underthesuncollectibles.com|REASON:robots.txt
WATCH|IP:81.19.79.209|WHEN:20110220|SERVER:yesterdaysthings.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110202|SERVER:bedplanet.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110202|SERVER:www.dominicksbakerycafe.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110204|SERVER:michaelkellyguitars.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110204|SERVER:www.bootstoo.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110206|SERVER:www.caboots.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110209|SERVER:garagesalesally.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110209|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110211|SERVER:snuka.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110211|SERVER:stopdirt.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110211|SERVER:www.whizardworks.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110212|SERVER:mymoonandstar.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110212|SERVER:www.wildcollections.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110213|SERVER:allpetsolutions.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110213|SERVER:speedbleeder.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110213|SERVER:www.handcart.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110213|SERVER:www.klatchroasting.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110214|SERVER:capricorn.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110215|SERVER:acejackets.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110215|SERVER:secondact.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110218|SERVER:jewelriverart.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110222|SERVER:discountsoftware.zoovy.com|REASON:robots.txt
WATCH|IP:81.223.254.34|WHEN:20110222|SERVER:www.tshirtsmall.com|REASON:robots.txt
WATCH|IP:81.240.55.59|WHEN:20110211|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:81.52.143.17|WHEN:20110201|SERVER:battlewagonbits.zoovy.com|REASON:robots.txt
WATCH|IP:81.52.143.17|WHEN:20110201|SERVER:mpodesigns.com|REASON:robots.txt
WATCH|IP:81.52.143.17|WHEN:20110201|SERVER:mpodesigns.zoovy.com|REASON:robots.txt
WATCH|IP:81.52.143.17|WHEN:20110201|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:81.52.143.17|WHEN:20110207|SERVER:mpodesigns.com|REASON:robots.txt
WATCH|IP:81.52.143.17|WHEN:20110207|SERVER:mpodesigns.zoovy.com|REASON:robots.txt
WATCH|IP:81.52.143.17|WHEN:20110207|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:81.52.143.17|WHEN:20110208|SERVER:battlewagonbits.zoovy.com|REASON:robots.txt
WATCH|IP:82.128.53.234|WHEN:20110207|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:82.147.11.62|WHEN:20110201|SERVER:m.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:82.181.242.203|WHEN:20110210|SERVER:www.reefs2go.com|REASON:robots.txt
WATCH|IP:8.26.103.67|WHEN:20110214|SERVER:www.flagsonastick.com|REASON:robots.txt
WATCH|IP:8.26.103.67|WHEN:20110219|SERVER:www.flagsonastick.com|REASON:robots.txt
WATCH|IP:82.94.176.158|WHEN:20110202|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:82.94.176.158|WHEN:20110207|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:82.94.176.158|WHEN:20110214|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:82.94.176.158|WHEN:20110220|SERVER:www.skullplanet.com|REASON:robots.txt
WATCH|IP:82.94.190.242|WHEN:20110213|SERVER:www.blitzinc.net|REASON:robots.txt
WATCH|IP:82.94.190.242|WHEN:20110213|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:82.94.190.242|WHEN:20110214|SERVER:www.skullplanet.com|REASON:robots.txt
WATCH|IP:83.101.55.97|WHEN:20110201|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:83.15.215.74|WHEN:20110211|SERVER:www.redrive.net|REASON:robots.txt
WATCH|IP:83.175.204.210|WHEN:20110212|SERVER:www.denimsquare.com|REASON:robots.txt
WATCH|IP:83.222.125.210|WHEN:20110204|SERVER:www.leedway.com|REASON:robots.txt
WATCH|IP:83.30.91.72|WHEN:20110213|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:83.70.33.116|WHEN:20110215|SERVER:www.affordablechristianproducts.com|REASON:robots.txt
WATCH|IP:84.12.179.66|WHEN:20110208|SERVER:www.thechessstore.com|REASON:robots.txt
WATCH|IP:84.132.202.17|WHEN:20110211|SERVER:www.tattooapparel.com|REASON:robots.txt
WATCH|IP:84.222.74.193|WHEN:20110216|SERVER:www.warehousedirectusa.com|REASON:robots.txt
WATCH|IP:84.228.250.202|WHEN:20110216|SERVER:robdiamond.net|REASON:robots.txt
WATCH|IP:85.10.36.100|WHEN:20110203|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:85.121.125.113|WHEN:20110217|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:85.125.32.90|WHEN:20110209|SERVER:www.steveearlestore.com|REASON:robots.txt
WATCH|IP:85.125.32.90|WHEN:20110209|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:85.175.172.26|WHEN:20110206|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:85.197.199.60|WHEN:20110215|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:85.225.79.219|WHEN:20110216|SERVER:soundmart.zoovy.com|REASON:robots.txt
WATCH|IP:85.225.79.219|WHEN:20110216|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:85.54.70.130|WHEN:20110220|SERVER:www.luvmy3toys.com|REASON:robots.txt
WATCH|IP:85.72.221.194|WHEN:20110207|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:86.128.39.171|WHEN:20110203|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:86.128.64.4|WHEN:20110203|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:86.28.241.82|WHEN:20110204|SERVER:www.thegiftmallonline.com|REASON:robots.txt
WATCH|IP:87.101.18.232|WHEN:20110205|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:87.121.78.97|WHEN:20110210|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:87.159.45.137|WHEN:20110219|SERVER:www.elegantbed.com|REASON:robots.txt
WATCH|IP:87.216.176.140|WHEN:20110209|SERVER:www.pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:87.216.176.140|WHEN:20110214|SERVER:www.robdiamond.net|REASON:robots.txt
WATCH|IP:87.219.10.117|WHEN:20110217|SERVER:jaredcampbellstore.com|REASON:robots.txt
WATCH|IP:87.236.242.142|WHEN:20110216|SERVER:www.spapartsdepot.com|REASON:robots.txt
WATCH|IP:87.236.242.243|WHEN:20110209|SERVER:www.ironstoneimports.com|REASON:robots.txt
WATCH|IP:87.249.193.28|WHEN:20110208|SERVER:www.glassbeadgarden.com|REASON:robots.txt
WATCH|IP:87.249.193.28|WHEN:20110209|SERVER:www.furniture-online.com|REASON:robots.txt
WATCH|IP:87.249.196.8|WHEN:20110202|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:87.249.196.8|WHEN:20110203|SERVER:www.2bhiptshirts.com|REASON:robots.txt
WATCH|IP:87.249.196.8|WHEN:20110205|SERVER:www.naturalcuresstore.com|REASON:robots.txt
WATCH|IP:87.249.196.8|WHEN:20110217|SERVER:www.capaper.com|REASON:robots.txt
WATCH|IP:87.249.196.8|WHEN:20110218|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:87.249.196.8|WHEN:20110219|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:87.249.196.8|WHEN:20110220|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:87.249.196.8|WHEN:20110222|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:87.7.128.229|WHEN:20110213|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:88.126.182.186|WHEN:20110205|SERVER:www.softnerparts.com|REASON:robots.txt
WATCH|IP:88.153.137.53|WHEN:20110213|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:88.172.145.11|WHEN:20110210|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:88.173.169.111|WHEN:20110216|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:88.173.169.111|WHEN:20110219|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110203|SERVER:www.tatianafashions.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110207|SERVER:www.italianseedandtool.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110208|SERVER:www.abbysplace.us|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110212|SERVER:www.polishkitchenonline.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110213|SERVER:smyrnacoin.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110213|SERVER:www.smyrnacoin.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110216|SERVER:bigbowling.zoovy.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110216|SERVER:www.europottery.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110218|SERVER:www.underthesuncollectibles.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110219|SERVER:www.amuletsbymerlin.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110219|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110220|SERVER:cbpots.zoovy.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110220|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110221|SERVER:www.thebeltbucklestore.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110222|SERVER:thegreekboutique.zoovy.com|REASON:robots.txt
WATCH|IP:88.198.2.105|WHEN:20110222|SERVER:www.wirelessvideocameras.net|REASON:robots.txt
WATCH|IP:88.198.23.139|WHEN:20110202|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:88.198.38.230|WHEN:20110202|SERVER:2bhip.com|REASON:robots.txt
WATCH|IP:88.198.38.230|WHEN:20110202|SERVER:www.bwbits.com|REASON:robots.txt
WATCH|IP:88.198.38.230|WHEN:20110202|SERVER:www.expeditionimports.com|REASON:robots.txt
WATCH|IP:88.198.38.230|WHEN:20110202|SERVER:www.thegiftmallonline.com|REASON:robots.txt
WATCH|IP:88.198.38.230|WHEN:20110202|SERVER:www.zephyrairsoft.com|REASON:robots.txt
WATCH|IP:88.198.38.230|WHEN:20110207|SERVER:www.ascotauto.com|REASON:robots.txt
WATCH|IP:88.198.38.230|WHEN:20110207|SERVER:www.shopattag.com|REASON:robots.txt
WATCH|IP:88.198.38.230|WHEN:20110207|SERVER:www.underthesuncollectibles.com|REASON:robots.txt
WATCH|IP:88.198.38.230|WHEN:20110207|SERVER:www.utsgifts.com|REASON:robots.txt
WATCH|IP:88.198.38.230|WHEN:20110207|SERVER:www.zasde.com|REASON:robots.txt
WATCH|IP:88.198.43.177|WHEN:20110205|SERVER:www.ibuywoodstoves.com|REASON:robots.txt
WATCH|IP:88.198.43.177|WHEN:20110213|SERVER:www.pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:88.198.43.177|WHEN:20110214|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:88.198.43.177|WHEN:20110218|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:88.198.43.177|WHEN:20110218|SERVER:www.tikioutlet.com|REASON:robots.txt
WATCH|IP:88.198.43.177|WHEN:20110219|SERVER:www.finalegloves.com|REASON:robots.txt
WATCH|IP:88.198.43.177|WHEN:20110222|SERVER:luggage4less.zoovy.com|REASON:robots.txt
WATCH|IP:88.246.243.14|WHEN:20110205|SERVER:kidsafeinc.com|REASON:robots.txt
WATCH|IP:88.246.243.14|WHEN:20110205|SERVER:summitfashions.com|REASON:robots.txt
WATCH|IP:88.246.243.14|WHEN:20110206|SERVER:www.qcollectionjunior.com|REASON:robots.txt
WATCH|IP:88.26.210.155|WHEN:20110222|SERVER:thatchandbamboo.com|REASON:robots.txt
WATCH|IP:88.26.210.155|WHEN:20110222|SERVER:www.plumbsource.net|REASON:robots.txt
WATCH|IP:88.26.210.155|WHEN:20110222|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110202|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110204|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110206|SERVER:guitarelectronics.zoovy.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110206|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110207|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110209|SERVER:raku.zoovy.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110209|SERVER:snuka.zoovy.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110209|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110210|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110211|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110212|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110212|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110214|SERVER:kseiya.zoovy.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110215|SERVER:mailboxmusic.zoovy.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110215|SERVER:www.4my3boyz.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110219|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110220|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110221|SERVER:guitarelectronics.zoovy.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110221|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:88.80.205.116|WHEN:20110222|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:88.9.37.165|WHEN:20110203|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:89.112.80.222|WHEN:20110222|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:89.143.229.100|WHEN:20110205|SERVER:www.garagestyle.com|REASON:robots.txt
WATCH|IP:89.143.229.100|WHEN:20110207|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110201|SERVER:crazydiscounts.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110203|SERVER:www.lemmyfigure.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110205|SERVER:www.pawprints.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110206|SERVER:www.laartwork.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110206|SERVER:www.pulsartech.net|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110206|SERVER:www.whiskey-rock.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110207|SERVER:1stproweddingalbums.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110207|SERVER:atgoodman.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110207|SERVER:golfswingtrainer.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110207|SERVER:www.piratedecoration.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110208|SERVER:augustartpaper.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110209|SERVER:dsvintage.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110210|SERVER:www.duggan.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110210|SERVER:yourdreamizhere.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110211|SERVER:absolutepda.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110212|SERVER:ptouchtape.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110213|SERVER:www.crescentclock.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110218|SERVER:atozgifts.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110218|SERVER:craftersnet.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110218|SERVER:www.gloves-prom.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110220|SERVER:sandjonline.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110221|SERVER:batterup.zoovy.com|REASON:robots.txt
WATCH|IP:89.16.161.9|WHEN:20110221|SERVER:electronics4u.zoovy.com|REASON:robots.txt
WATCH|IP:89.241.198.184|WHEN:20110214|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:90.156.178.45|WHEN:20110215|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:90.156.178.45|WHEN:20110215|SERVER:www.kidscraftsplus.com|REASON:robots.txt
WATCH|IP:90.156.178.45|WHEN:20110216|SERVER:www.slowrunnerstore.com|REASON:robots.txt
WATCH|IP:90.156.178.45|WHEN:20110217|SERVER:frontierleathers.zoovy.com|REASON:robots.txt
WATCH|IP:90.156.178.45|WHEN:20110217|SERVER:www.thespotlowrider.com|REASON:robots.txt
WATCH|IP:90.218.108.20|WHEN:20110218|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:90.59.254.185|WHEN:20110218|SERVER:www.sassyassyjeans.com|REASON:robots.txt
WATCH|IP:91.109.79.241|WHEN:20110221|SERVER:www.stealthcycling.com|REASON:robots.txt
WATCH|IP:91.121.204.98|WHEN:20110211|SERVER:www.antifatiguemat.com|REASON:robots.txt
WATCH|IP:91.185.194.122|WHEN:20110206|SERVER:hdesk.com|REASON:robots.txt
WATCH|IP:91.185.194.122|WHEN:20110206|SERVER:www.hdesk.com|REASON:robots.txt
WATCH|IP:91.185.194.122|WHEN:20110216|SERVER:amigaz.com|REASON:robots.txt
WATCH|IP:91.185.194.122|WHEN:20110216|SERVER:www.amigaz.com|REASON:robots.txt
WATCH|IP:91.185.194.122|WHEN:20110218|SERVER:rufusdawg.com|REASON:robots.txt
WATCH|IP:91.185.194.122|WHEN:20110218|SERVER:www.rufusdawg.com|REASON:robots.txt
WATCH|IP:91.185.194.122|WHEN:20110220|SERVER:abbysplace.us|REASON:robots.txt
WATCH|IP:91.185.194.122|WHEN:20110220|SERVER:www.abbysplace.us|REASON:robots.txt
WATCH|IP:91.185.194.122|WHEN:20110221|SERVER:jadeboutique.com|REASON:robots.txt
WATCH|IP:91.185.194.122|WHEN:20110221|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:91.199.212.132|WHEN:20110218|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:91.203.174.3|WHEN:20110205|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110201|SERVER:jdhines.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110201|SERVER:l.zoovy.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110201|SERVER:totalfanshop.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110202|SERVER:jdhines.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110202|SERVER:l.zoovy.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110202|SERVER:totalfanshop.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110203|SERVER:jdhines.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110203|SERVER:l.zoovy.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110203|SERVER:totalfanshop.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110203|SERVER:www.dasbootglass.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110203|SERVER:www.enneagraminstitute.biz|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110204|SERVER:jdhines.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110204|SERVER:l.zoovy.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110204|SERVER:totalfanshop.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110204|SERVER:www.tikiwholesale.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:bedplanet.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:flymode.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:jdhines.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:justifieddefiance.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:l.zoovy.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:round2store.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:totalfanshop.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:www.buyelastogel.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:www.easyauctioncheckout.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:www.justifieddefiance.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110205|SERVER:www.round2store.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110206|SERVER:discountgunmart.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110206|SERVER:jdhines.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110206|SERVER:l.zoovy.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110206|SERVER:totalfanshop.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110207|SERVER:l.zoovy.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110207|SERVER:nerdgear.zoovy.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110207|SERVER:www.bandswag.net|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110207|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110208|SERVER:jdhines.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110208|SERVER:l.zoovy.com|REASON:robots.txt
WATCH|IP:91.212.12.60|WHEN:20110209|SERVER:ancientsun.zoovy.com|REASON:robots.txt
WATCH|IP:91.218.117.8|WHEN:20110204|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:91.218.117.8|WHEN:20110204|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:91.218.117.8|WHEN:20110217|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:91.67.144.158|WHEN:20110203|SERVER:www.bigbowling.com|REASON:robots.txt
WATCH|IP:91.67.144.158|WHEN:20110203|SERVER:www.evocstore.com|REASON:robots.txt
WATCH|IP:91.67.144.158|WHEN:20110203|SERVER:www.flamedancerbeads.zoovy.com|REASON:robots.txt
WATCH|IP:91.67.144.158|WHEN:20110204|SERVER:www.josefeliciano.zoovy.com|REASON:robots.txt
WATCH|IP:91.67.144.158|WHEN:20110204|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:91.67.144.158|WHEN:20110204|SERVER:www.rosiqueflowers.com|REASON:robots.txt
WATCH|IP:91.67.144.158|WHEN:20110204|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:92.201.195.143|WHEN:20110216|SERVER:www.skullplanet.com|REASON:robots.txt
WATCH|IP:92.226.111.127|WHEN:20110201|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:93.109.213.245|WHEN:20110203|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:93.130.83.92|WHEN:20110204|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:93.172.166.31|WHEN:20110201|SERVER:kidsafeinc.com|REASON:robots.txt
WATCH|IP:93.172.166.31|WHEN:20110201|SERVER:summitfashions.com|REASON:robots.txt
WATCH|IP:93.172.166.31|WHEN:20110201|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:93.172.166.31|WHEN:20110201|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110201|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110202|SERVER:www.dollhousesandmore.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110202|SERVER:www.funbottleopeners.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110202|SERVER:www.jewelriverart.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110202|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110203|SERVER:www.equinefashionandtack.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110203|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110203|SERVER:www.paintsprayersplus.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110207|SERVER:gkworld.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110207|SERVER:www.gardensbyolivia.zoovy.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110207|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110209|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110210|SERVER:froggysfog.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110210|SERVER:pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110210|SERVER:www.froggysfog.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110210|SERVER:www.pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110212|SERVER:crite2000.zoovy.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110217|SERVER:www.woodlandimport.com|REASON:robots.txt
WATCH|IP:93.186.179.83|WHEN:20110218|SERVER:www.raku-art.com|REASON:robots.txt
WATCH|IP:93.41.18.65|WHEN:20110215|SERVER:www.qcollectionjunior.com|REASON:robots.txt
WATCH|IP:93.87.35.73|WHEN:20110218|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:94.109.49.158|WHEN:20110205|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:94.155.89.55|WHEN:20110210|SERVER:www.bigoutlet.com|REASON:robots.txt
WATCH|IP:94.208.80.206|WHEN:20110214|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:94.220.251.111|WHEN:20110202|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:94.220.251.111|WHEN:20110202|SERVER:www.rdwholesale.net|REASON:robots.txt
WATCH|IP:94.220.251.111|WHEN:20110202|SERVER:www.robdiamond.net|REASON:robots.txt
WATCH|IP:94.220.251.111|WHEN:20110215|SERVER:www.chiquelife.com|REASON:robots.txt
WATCH|IP:94.220.251.111|WHEN:20110217|SERVER:www.rdwholesale.net|REASON:robots.txt
WATCH|IP:94.220.251.15|WHEN:20110216|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:94.220.251.32|WHEN:20110202|SERVER:www.rdwholesale.net|REASON:robots.txt
WATCH|IP:94.220.251.32|WHEN:20110217|SERVER:www.robdiamond.net|REASON:robots.txt
WATCH|IP:94.220.251.65|WHEN:20110217|SERVER:www.rdwholesale.net|REASON:robots.txt
WATCH|IP:94.220.251.65|WHEN:20110220|SERVER:www.toolprice.com|REASON:robots.txt
WATCH|IP:94.23.222.96|WHEN:20110203|SERVER:barefoottess.com|REASON:robots.txt
WATCH|IP:94.23.222.96|WHEN:20110203|SERVER:greatscarves.com|REASON:robots.txt
WATCH|IP:94.23.222.96|WHEN:20110203|SERVER:modernmini.com|REASON:robots.txt
WATCH|IP:94.23.222.96|WHEN:20110203|SERVER:oldcookbooks.com|REASON:robots.txt
WATCH|IP:94.23.222.96|WHEN:20110203|SERVER:studiohut.com|REASON:robots.txt
WATCH|IP:94.23.222.96|WHEN:20110203|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:94.23.222.96|WHEN:20110203|SERVER:www.greatscarves.com|REASON:robots.txt
WATCH|IP:94.23.222.96|WHEN:20110203|SERVER:www.modernmini.com|REASON:robots.txt
WATCH|IP:94.23.222.96|WHEN:20110203|SERVER:www.oldcookbooks.com|REASON:robots.txt
WATCH|IP:94.23.222.96|WHEN:20110203|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:94.23.234.175|WHEN:20110210|SERVER:www.needtobreathestore.com|REASON:robots.txt
WATCH|IP:94.23.234.175|WHEN:20110216|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:94.23.234.175|WHEN:20110216|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:94.54.179.37|WHEN:20110202|SERVER:www.zephyrsports.com|REASON:robots.txt
WATCH|IP:94.69.26.253|WHEN:20110213|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.105.110.213|WHEN:20110207|SERVER:www.bowhuntingstuff.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110202|SERVER:www.bobbybarejrstore.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110202|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110202|SERVER:www.outofthetoybox.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110202|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110203|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110203|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110203|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110203|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110203|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110203|SERVER:www.smyrnacoin.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110203|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110203|SERVER:www.watchmasterusa.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110203|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110204|SERVER:www.bobbybarejrstore.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110204|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110204|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110204|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110204|SERVER:www.smyrnacoin.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110204|SERVER:www.watchmasterusa.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110204|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110205|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110205|SERVER:www.bobbybarejrstore.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110205|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110205|SERVER:www.luggage4less.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110205|SERVER:www.smyrnacoin.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110205|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110206|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110206|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110206|SERVER:www.luggage4less.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110206|SERVER:www.watchmasterusa.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110206|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110207|SERVER:www.bobbybarejrstore.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110207|SERVER:www.digmodern.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110207|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110207|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110207|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110208|SERVER:www.bloomindesigns.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110208|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110208|SERVER:www.italianseedandtool.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110208|SERVER:www.luggage4less.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110208|SERVER:www.pastgenerationtoys.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110208|SERVER:www.watchmasterusa.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110208|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110209|SERVER:www.bobbybarejrstore.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110209|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110209|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110209|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110210|SERVER:www.decor411.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110210|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110210|SERVER:www.watchmasterusa.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110210|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110211|SERVER:www.4armedforces.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110211|SERVER:www.blackhawksshop.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110211|SERVER:www.bobbybarejrstore.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110211|SERVER:www.decor411.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110211|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110211|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110211|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110211|SERVER:www.watchmasterusa.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110211|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110213|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110214|SERVER:www.decor411.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110214|SERVER:www.watchmasterusa.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110214|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110215|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110215|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.acworldtoys.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.buyanythingnow.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.chiquelife.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.crescentclock.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.glasstileexpress.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.gss-store.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.halebobstore.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.hdesk.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.ironwinecellardoors.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.lisabeads.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.lisabeadsonline.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.maureenscreations.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.michaelscookies.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.morganicclimbing.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.nydugout.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.oasismailbox.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.palmersnowboards.us|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.riderswraps.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.toys.gogoods.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110221|SERVER:www.tscapstore.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110222|SERVER:www.caboots.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110222|SERVER:www.envirovogue.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110222|SERVER:www.modernenglishstore.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110222|SERVER:www.prosafetysupplies.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110222|SERVER:www.thecandlemakersstore.com|REASON:robots.txt
WATCH|IP:95.108.151.5|WHEN:20110222|SERVER:www.woodlandimport.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110202|SERVER:www.beach-signs.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110202|SERVER:www.gourmetislandfoods.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110202|SERVER:www.hawaiianjewelrymaster.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110202|SERVER:www.piratedecoration.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110202|SERVER:www.surfing-monkey.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110202|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110202|SERVER:www.tikioutlet.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.beergardentables.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.hbdrums.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.lilslavender.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.nutcrackerhaus.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.piratedecoration.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.surfcityinstruments.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110203|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.artprintandposter.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.beach-signs.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.beergardentables.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.dinnerwarepotterymugheaven.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.europottery.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.gourmetislandfoods.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.hbdrums.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.islandbathnbody.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.lilslavender.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.nautical-signs.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.nutcrackerhaus.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.piratedecoration.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.purewaveaudio.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.surfcityinstruments.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.tikioutlet.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110204|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.4my3boyz.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.artprintandposter.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.beach-signs.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.doobiebrothersstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.europottery.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.gourmetislandfoods.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.islandbathnbody.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.nancigriffithstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.nautical-signs.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.purewaveaudio.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.tikioutlet.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110205|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.beergardentables.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.coolstuff4u.net|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.dinnerwarepotterymugheaven.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.hbdrums.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.lilslavender.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.nutcrackerhaus.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.purewaveaudio.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.surfcityinstruments.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110206|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110207|SERVER:www.beach-signs.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110207|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110207|SERVER:www.gourmetislandfoods.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110207|SERVER:www.purewaveaudio.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110207|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110207|SERVER:www.tikioutlet.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.dinnerwarepotterymugheaven.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.hbdrums.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.lilslavender.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.purewaveaudio.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.shopvelvethanger.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.surfcityinstruments.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110208|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110209|SERVER:www.beach-signs.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110209|SERVER:www.bierboothaus.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110209|SERVER:www.gourmetislandfoods.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110209|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110209|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110209|SERVER:www.tikioutlet.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110209|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.bbkingstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.coolstuff4u.net|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.dinnerwarepotterymugheaven.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.elegantbed.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.garagestyle.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.hbdrums.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.ibuybathroomvanities.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.ibuyholiday.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.orleanscandles.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.polishkitchenonline.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.purewaveaudio.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.racewax.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.ribbontrade.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.surfcityinstruments.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.wildcollections.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110210|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.beach-signs.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.dinnerwarepotterymugheaven.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.gourmetislandfoods.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.hbdrums.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.surfcityinstruments.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.tikioutlet.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.wallsthatspeak.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110211|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110213|SERVER:www.beach-signs.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110213|SERVER:www.gourmetislandfoods.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110213|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110213|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110213|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110213|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110213|SERVER:www.tikioutlet.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110213|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.dinnerwarepotterymugheaven.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.hbdrums.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.surfcityinstruments.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.toddsniderstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.wallsthatspeak.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110214|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110215|SERVER:www.beach-signs.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110215|SERVER:www.gourmetislandfoods.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110215|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110215|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110215|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110215|SERVER:www.thatchandbamboo.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110215|SERVER:www.theotherworlds.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110215|SERVER:www.tikioutlet.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.beautystoredepot.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.completecarecenters.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.dreamwaytrading.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.elegantquilling.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.f2ptechnologies.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.hausfortuna.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.hotwaterstuff.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.hydroquipspapack.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.isellneatstuff.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.keybrandsinternational.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.leatherfurniturecenter.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.liquidfashions.net|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.nautical360.net|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.planetrenadirect.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.ralphiemaystore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.rapid-direction.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.rayscustomtackle.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.rcusa.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.reefs2go.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.seashellmaster.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.surfcitymusic.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.teacupgallery.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.themahjongshop.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.toolusa.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.tshirtsmall.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:www.warehousedirectusa.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110221|SERVER:zestcandles.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.2bhipbabies.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.allsantasuits.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.bluecollarwear.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.custompotrack.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.dolldreams.net|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.forevertoys.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.glam4games.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.konradskids.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.lukereynoldsstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.tractorgps.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.tsbagstore.com|REASON:robots.txt
WATCH|IP:95.108.151.6|WHEN:20110222|SERVER:www.zestcandles.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110201|SERVER:www.racewax.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110202|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110202|SERVER:www.dolldreams.net|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110202|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110202|SERVER:www.leisuretimechemicals.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110202|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110203|SERVER:www.racewax.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110203|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110204|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110204|SERVER:www.racewax.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110204|SERVER:www.surfcityinstruments.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110204|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110205|SERVER:www.racewax.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110205|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110206|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110207|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110208|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110209|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110210|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110211|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110211|SERVER:www.elegantaudiovideo.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110211|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110211|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110212|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110212|SERVER:www.dolldreams.net|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110213|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110213|SERVER:www.dolldreams.net|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110213|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110214|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110215|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110215|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110216|SERVER:www.dolldreams.net|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110216|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110217|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110218|SERVER:www.seiyajapan.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110218|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110219|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110219|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110220|SERVER:www.decoratingwithlace.com|REASON:robots.txt
WATCH|IP:95.108.158.232|WHEN:20110221|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110201|SERVER:www.bullsshit.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110201|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110201|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110201|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:www.americanguitarboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:www.envirovogue.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:www.ornamentsafe.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:www.surfcitymusic.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:www.tatianabras.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:www.totalfanshop.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110202|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110203|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110203|SERVER:www.bullsshit.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110203|SERVER:www.envirovogue.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110203|SERVER:www.ornamentsafe.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110203|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110203|SERVER:www.speedaddictcycles.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110203|SERVER:www.tatianabras.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110203|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110204|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110204|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110204|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110204|SERVER:www.beltsandmore.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110204|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110204|SERVER:www.bullsshit.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110204|SERVER:www.envirovogue.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110204|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110204|SERVER:www.surfcitymusic.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110204|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110205|SERVER:www.americanguitarboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110205|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110205|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110205|SERVER:www.ornamentsafe.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110205|SERVER:www.tatianabras.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110206|SERVER:www.americanguitarboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110206|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110206|SERVER:www.mountaincrafts.net|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110206|SERVER:www.tatianabras.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110207|SERVER:bargaincds.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110207|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110207|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110207|SERVER:www.americanguitarboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110207|SERVER:www.aromaspas.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110207|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110207|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110207|SERVER:www.mountaincrafts.net|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110207|SERVER:www.tatianabras.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110208|SERVER:bargaincds.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110208|SERVER:proshop.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110208|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110208|SERVER:www.aromaspas.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110208|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110208|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110208|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110209|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110209|SERVER:www.bullsshit.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110209|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110210|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110210|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110210|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110210|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110210|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110211|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110211|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110211|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110212|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110212|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110212|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110212|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110213|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110213|SERVER:www.decoratingwithlaceoutlet.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110213|SERVER:www.foreverflorals.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110213|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110213|SERVER:www.raku-art.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110213|SERVER:www.tatianabras.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110213|SERVER:www.urlichdecorations.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110213|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110214|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110214|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110214|SERVER:www.raku-art.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110214|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110214|SERVER:www.tatianabras.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110214|SERVER:www.thebullsshop.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110214|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110214|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110214|SERVER:www.urlichdecorations.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110214|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110215|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110215|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110215|SERVER:www.beltsandmore.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110215|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110215|SERVER:www.envirovogue.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110215|SERVER:www.source-tropical.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110215|SERVER:www.thebullsshop.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110216|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110216|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110216|SERVER:www.envirovogue.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110217|SERVER:satin.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110217|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110217|SERVER:www.ornamentsafe.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110218|SERVER:www.ornamentsafe.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110218|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110219|SERVER:colocustommetal.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110219|SERVER:kseiya.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110219|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110219|SERVER:www.gooddeals18.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110219|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110219|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110219|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110219|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110219|SERVER:www.watchzilla.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110220|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110220|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110220|SERVER:www.tatianabras.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110220|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110220|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110220|SERVER:www.watchzilla.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110221|SERVER:colocustommetal.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110221|SERVER:kseiya.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110221|SERVER:www.americanguitarboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110221|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:95.108.158.233|WHEN:20110221|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110202|SERVER:bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110202|SERVER:www.challengethis.net|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110202|SERVER:www.craftersnet.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110202|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110202|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110202|SERVER:www.rhythmfusion.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.arcolamp.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.craftersnet.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.massagechairplanet.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.pdpprinting.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.rhythmfusion.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.silverchicks.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110204|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110205|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110205|SERVER:www.aaavacs.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110205|SERVER:www.arcolamp.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110205|SERVER:www.craftersnet.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110205|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110205|SERVER:www.pdpprinting.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110205|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110207|SERVER:www.halo-works.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110207|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110209|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110209|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110209|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110209|SERVER:www.studiohut.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110211|SERVER:bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110211|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110211|SERVER:www.buygmperformance.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110211|SERVER:www.rhythmfusion.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110211|SERVER:www.stage3offroad.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110213|SERVER:kcint.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110213|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110213|SERVER:www.buygmperformance.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110213|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110213|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110213|SERVER:www.mugheaven.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110213|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110214|SERVER:kcint.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110214|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110214|SERVER:www.kidsafeinc.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110214|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110215|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110215|SERVER:www.rhythmfusion.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110216|SERVER:kcint.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110216|SERVER:www.1quickcup.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110217|SERVER:www.craftersnet.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110217|SERVER:www.rhythmfusion.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110218|SERVER:www.pawstogo.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110218|SERVER:www.rhythmfusion.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110219|SERVER:www.shopvelvethanger.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110220|SERVER:onequickcup.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110220|SERVER:www.shopvelvethanger.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110221|SERVER:onequickcup.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110221|SERVER:www.craftersnet.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110221|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:95.108.158.234|WHEN:20110222|SERVER:www.discountgunmart.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110203|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110203|SERVER:www.ghostinc.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110203|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110203|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110203|SERVER:www.myhotshoes.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110203|SERVER:www.round2store.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110203|SERVER:www.s281motorsports.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110203|SERVER:www.southmissiononline.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110203|SERVER:www.teacupgallery.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110203|SERVER:www.ticohomedecor.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:racerwalsh.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.airwaterice.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.beltsdirect.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.equinefashionandtack.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.expedition-imports.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.futonbedplanet.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.italianseedandtool.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.kcint2.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.prostreetlighting.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110204|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:racerwalsh.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:round2store.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.airwaterice.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.beltiscool.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.cbpots.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.equinefashionandtack.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.expedition-imports.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.futonbedplanet.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.kcint2.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.modernmini.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.myhotshoes.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.round2store.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110205|SERVER:www.ticohomedecor.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110206|SERVER:offroadrecovery.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110206|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110206|SERVER:www.cbpots.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110206|SERVER:www.expedition-imports.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110206|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110206|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110206|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110206|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110206|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110206|SERVER:www.luvmy3toys.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110207|SERVER:round2store.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110207|SERVER:www.airwaterice.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110207|SERVER:www.bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110207|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110207|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110207|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110207|SERVER:www.italianseedandtool.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110207|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110208|SERVER:offroadrecovery.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110208|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110208|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110208|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110208|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110208|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110209|SERVER:www.instrumentsofinspiration.net|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110210|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110210|SERVER:www.equinefashionandtack.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110210|SERVER:www.instrumentsofinspiration.net|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110210|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110210|SERVER:www.mpodesigns.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110210|SERVER:www.myhotshoes.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110211|SERVER:www.bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110211|SERVER:www.beltsdirect.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110211|SERVER:www.covisec.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110212|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110212|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110212|SERVER:www.expedition-imports.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110212|SERVER:www.myhotshoes.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110213|SERVER:www.bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110213|SERVER:www.beltsdirect.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110213|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110213|SERVER:www.expedition-imports.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110213|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110213|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110213|SERVER:www.italianseedandtool.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110213|SERVER:www.kcint2.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110213|SERVER:www.prostreetlighting.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110214|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110214|SERVER:www.kcint2.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110215|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110215|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110215|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110215|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110216|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110216|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110216|SERVER:www.funbottleopeners.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110216|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110217|SERVER:www.bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110217|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110217|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110217|SERVER:www.modernmini.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110217|SERVER:www.myhotshoes.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110218|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110218|SERVER:www.finodisc.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.airwaterice.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.covisec.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.cypherstyles.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.finodisc.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.jadeboutique.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110219|SERVER:www.redfordfilms.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110221|SERVER:1stproweddingalbums.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110221|SERVER:www.bat-houses.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110221|SERVER:www.beadone.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110221|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110221|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110221|SERVER:www.funbottleopeners.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110221|SERVER:www.guitarelectronics.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110221|SERVER:www.gunnersalley.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110222|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110222|SERVER:www.funbottleopeners.com|REASON:robots.txt
WATCH|IP:95.108.158.236|WHEN:20110222|SERVER:www.oworlds.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110202|SERVER:reliabuilt3612.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110202|SERVER:static-b.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110202|SERVER:www.kunjethy.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110204|SERVER:reliabuilt3612.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110204|SERVER:www.kunjethy.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110205|SERVER:reliabuilt3612.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110206|SERVER:reliabuilt3612.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110207|SERVER:reliabuilt3612.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110211|SERVER:static-b.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110215|SERVER:static-b.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110216|SERVER:www.kunjethy.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110218|SERVER:www.kunjethy.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110220|SERVER:static-b.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.239|WHEN:20110221|SERVER:static-b.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110201|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110201|SERVER:www.lembarstool.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110201|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110202|SERVER:www.arcohost.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110202|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110202|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110202|SERVER:www.dirndls.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110202|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110202|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110203|SERVER:www.caliperpaints.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110203|SERVER:www.shophalebob.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.bejeweledhooks.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.chiquelife.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.dirndls.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.shophalebob.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110204|SERVER:www.ticodecorations.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110205|SERVER:www.acworldtoys.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110205|SERVER:www.bejeweledhooks.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110205|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110205|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110205|SERVER:www.refinergolf.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110205|SERVER:www.rufusdawg.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110206|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110206|SERVER:www.rufusdawg.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110206|SERVER:www.towguards.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110207|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110208|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110209|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110209|SERVER:www.halebobstore.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110210|SERVER:www.arcohost.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110210|SERVER:www.lembarstool.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110211|SERVER:www.alloceansports.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110211|SERVER:www.arcohost.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110211|SERVER:www.chiquelife.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110211|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110211|SERVER:www.lembarstool.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110211|SERVER:www.rainbowcustomcars.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110212|SERVER:www.arcohost.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110212|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110213|SERVER:www.arcohost.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110213|SERVER:www.chiquelife.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110213|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110213|SERVER:www.highpointscientific.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110214|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110215|SERVER:www.dirndls.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110215|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110216|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110216|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110217|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110218|SERVER:www.amigaz.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110218|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110219|SERVER:www.allpetsolutions.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110219|SERVER:www.oldscyene.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110219|SERVER:www.shophalebob.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110220|SERVER:coastalbay.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110220|SERVER:deals2all.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110220|SERVER:www.amigaz.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110220|SERVER:www.cellphoneslord.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110220|SERVER:www.christianlicenseplateframes.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110220|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110220|SERVER:www.oldscyene.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110221|SERVER:coastalbay.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110221|SERVER:deals2all.zoovy.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110221|SERVER:www.climbingholds.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110221|SERVER:www.halebobstore.com|REASON:robots.txt
WATCH|IP:95.108.158.243|WHEN:20110221|SERVER:www.leos.zoovy.com|REASON:robots.txt
WATCH|IP:95.209.12.230|WHEN:20110217|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:95.240.253.62|WHEN:20110221|SERVER:www.greatlookz.com|REASON:robots.txt
WATCH|IP:95.240.253.62|WHEN:20110221|SERVER:www.greatlookzitaly.com|REASON:robots.txt
WATCH|IP:95.49.166.246|WHEN:20110218|SERVER:www.tikimaster.com|REASON:robots.txt
WATCH|IP:95.76.226.63|WHEN:20110211|SERVER:www.racewax.com|REASON:robots.txt
WATCH|IP:96.239.168.29|WHEN:20110211|SERVER:www.designed2bsweet.com|REASON:robots.txt
WATCH|IP:96.250.230.198|WHEN:20110221|SERVER:www.lp.halebobstore.com|REASON:robots.txt
WATCH|IP:96.255.133.80|WHEN:20110214|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:96.47.11.110|WHEN:20110203|SERVER:www.perfumecenteronline.com|REASON:robots.txt
WATCH|IP:96.48.229.116|WHEN:20110222|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:96.61.143.75|WHEN:20110209|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:96.61.143.75|WHEN:20110209|SERVER:www.tlstuff.com|REASON:robots.txt
WATCH|IP:97.123.43.247|WHEN:20110216|SERVER:www.ralphiemaystore.com|REASON:robots.txt
WATCH|IP:98.112.98.145|WHEN:20110217|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:98.118.142.102|WHEN:20110214|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:98.149.151.56|WHEN:20110202|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:98.151.23.50|WHEN:20110217|SERVER:www.2bhip.com|REASON:robots.txt
WATCH|IP:98.158.206.111|WHEN:20110209|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:98.160.249.154|WHEN:20110216|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:98.175.173.82|WHEN:20110206|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:98.175.173.82|WHEN:20110214|SERVER:www.zephyrpaintball.com|REASON:robots.txt
WATCH|IP:98.182.35.105|WHEN:20110210|SERVER:www.mandwsupply.com|REASON:robots.txt
WATCH|IP:98.193.51.222|WHEN:20110202|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:98.193.51.222|WHEN:20110203|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:98.193.51.222|WHEN:20110204|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:98.193.51.222|WHEN:20110205|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:98.193.51.222|WHEN:20110206|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:98.193.51.222|WHEN:20110207|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:98.193.51.222|WHEN:20110210|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:98.193.51.222|WHEN:20110211|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:98.194.233.214|WHEN:20110218|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:98.204.213.51|WHEN:20110218|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:98.219.176.187|WHEN:20110211|SERVER:www.gkworld.com|REASON:robots.txt
WATCH|IP:98.222.182.220|WHEN:20110222|SERVER:www.sfplanet.com|REASON:robots.txt
WATCH|IP:98.223.34.85|WHEN:20110201|SERVER:www.cubworld.com|REASON:robots.txt
WATCH|IP:98.225.147.32|WHEN:20110217|SERVER:www.gogoods.com|REASON:robots.txt
WATCH|IP:98.240.72.222|WHEN:20110206|SERVER:www.zestcandle.com|REASON:robots.txt
WATCH|IP:98.240.72.222|WHEN:20110220|SERVER:www.beachmall.com|REASON:robots.txt
WATCH|IP:98.243.88.63|WHEN:20110221|SERVER:www.coolstuff4u.net|REASON:robots.txt
WATCH|IP:98.69.168.199|WHEN:20110222|SERVER:www.avatarcostumes.com|REASON:robots.txt
WATCH|IP:98.77.188.96|WHEN:20110214|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:98.82.10.87|WHEN:20110205|SERVER:www.2bhipbuckles.com|REASON:robots.txt
WATCH|IP:98.92.163.249|WHEN:20110211|SERVER:www.ghostinc.com|REASON:robots.txt
WATCH|IP:98.92.3.82|WHEN:20110211|SERVER:www.avatarcostumes.com|REASON:robots.txt
WATCH|IP:98.95.151.196|WHEN:20110202|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:98.95.151.196|WHEN:20110222|SERVER:www.musclextreme.com|REASON:robots.txt
WATCH|IP:99.100.250.101|WHEN:20110210|SERVER:www.dianayvonne.com|REASON:robots.txt
WATCH|IP:99.106.6.243|WHEN:20110202|SERVER:www.riascrazydeals.com|REASON:robots.txt
WATCH|IP:99.108.122.198|WHEN:20110202|SERVER:www.homebrewers.com|REASON:robots.txt
WATCH|IP:99.108.141.105|WHEN:20110204|SERVER:www.gourmetseed.com|REASON:robots.txt
WATCH|IP:99.108.141.105|WHEN:20110204|SERVER:www.italianseedandtool.com|REASON:robots.txt
WATCH|IP:99.1.109.89|WHEN:20110221|SERVER:www.pricematters.ca|REASON:robots.txt
WATCH|IP:99.138.147.30|WHEN:20110202|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:99.141.84.95|WHEN:20110221|SERVER:www.hangingmobilegallery.com|REASON:robots.txt
WATCH|IP:99.162.52.200|WHEN:20110221|SERVER:www.888knivesrus.com|REASON:robots.txt
WATCH|IP:99.177.86.196|WHEN:20110217|SERVER:www.stage3motorsports.com|REASON:robots.txt
WATCH|IP:99.179.99.205|WHEN:20110214|SERVER:www.austinbazaar.com|REASON:robots.txt
WATCH|IP:99.183.190.24|WHEN:20110221|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:99.183.190.24|WHEN:20110222|SERVER:www.orangeonions.com|REASON:robots.txt
WATCH|IP:99.184.62.172|WHEN:20110205|SERVER:www.toynk.com|REASON:robots.txt
WATCH|IP:99.224.113.103|WHEN:20110218|SERVER:www.summitfashions.com|REASON:robots.txt
WATCH|IP:99.242.135.246|WHEN:20110202|SERVER:www.wlanparts.com|REASON:robots.txt
WATCH|IP:99.242.181.195|WHEN:20110212|SERVER:homebrewers.com|REASON:robots.txt
WATCH|IP:99.242.181.195|WHEN:20110216|SERVER:homebrewers.com|REASON:robots.txt
WATCH|IP:99.246.255.94|WHEN:20110220|SERVER:www.lp.halebobstore.com|REASON:robots.txt
WATCH|IP:99.246.255.94|WHEN:20110220|SERVER:www.us.halebobstore.com|REASON:robots.txt
WATCH|IP:99.27.150.40|WHEN:20110215|SERVER:www.kyledesigns.com|REASON:robots.txt
WATCH|IP:99.38.118.208|WHEN:20110211|SERVER:www.dominicksbakerycafe.com|REASON:robots.txt
WATCH|IP:99.66.223.116|WHEN:20110209|SERVER:www.barefoottess.com|REASON:robots.txt
WATCH|IP:99.74.169.33|WHEN:20110213|SERVER:www.chiquelife.com|REASON:robots.txt
WATCH|IP:99.74.79.233|WHEN:20110209|SERVER:www.riascrazydeals.com|REASON:robots.txt
WATCH|IP:99.99.232.224|WHEN:20110202|SERVER:www.replaceyourcell.com|REASON:robots.txt

## make sure we treat our users right!
SAFE|IP:108.0.239.73|WHEN:20110223|USER:pacificpetshop*ADMIN
SAFE|IP:108.102.208.132|WHEN:20110223|USER:gssstore*ADMIN
SAFE|IP:108.14.99.31|WHEN:20110223|USER:nyciwear*nikki
SAFE|IP:108.16.6.59|WHEN:20110223|USER:harleysvillemotorcyc*ADMIN
SAFE|IP:108.21.111.24|WHEN:20110223|USER:qualityoverstock*ADMIN
SAFE|IP:108.23.151.90|WHEN:20110223|USER:beltiscool*ajax
SAFE|IP:108.23.182.36|WHEN:20110223|USER:sjpacific*lisa
SAFE|IP:108.27.62.228|WHEN:20110223|USER:domino*lisa
SAFE|IP:108.3.183.77|WHEN:20110223|USER:johnwb63*ADMIN
SAFE|IP:108.5.123.19|WHEN:20110223|USER:chiquelife*
SAFE|IP:108.6.162.171|WHEN:20110223|USER:beltsdirect*ADMIN
SAFE|IP:109.169.63.32|WHEN:20110223|USER:wildcollections*john
SAFE|IP:109.169.72.61|WHEN:20110223|USER:wildcollections*john
SAFE|IP:109.64.184.177|WHEN:20110223|USER:onequickcup*jason
SAFE|IP:110.36.10.26|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.36.115.183|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.36.118.202|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.36.124.17|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.36.124.87|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.36.1.82|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.36.45.249|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.36.60.75|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.36.62.11|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.36.64.134|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.36.7.67|WHEN:20110223|USER:warehousedirect72*komal
SAFE|IP:110.37.128.119|WHEN:20110223|USER:warehousedirect72*ahmed
SAFE|IP:110.37.129.184|WHEN:20110223|USER:warehousedirect72*ahmed
SAFE|IP:110.37.3.32|WHEN:20110223|USER:warehousedirect72*ahmed
SAFE|IP:111.68.40.206|WHEN:20110223|USER:no1collectibles*don
SAFE|IP:112.104.65.175|WHEN:20110223|USER:jeco*tim
SAFE|IP:113.203.128.86|WHEN:20110223|USER:sasydeals*mansoor
SAFE|IP:113.203.148.20|WHEN:20110223|USER:sasydeals*mansoor
SAFE|IP:113.203.162.35|WHEN:20110223|USER:sasydeals*mansoor
SAFE|IP:113.203.166.104|WHEN:20110223|USER:sasydeals*mansoor
SAFE|IP:113.203.168.45|WHEN:20110223|USER:sasydeals*mansoor
SAFE|IP:113.203.172.69|WHEN:20110223|USER:sasydeals*mansoor
SAFE|IP:114.143.114.228|WHEN:20110223|USER:gooddeals18*1
SAFE|IP:115.134.85.75|WHEN:20110223|USER:sfplanet*csr
SAFE|IP:115.186.64.102|WHEN:20110223|USER:watchzilla*safdar
SAFE|IP:115.186.64.108|WHEN:20110223|USER:watchzilla*safdar
SAFE|IP:115.186.64.98|WHEN:20110223|USER:watchzilla*safdar
SAFE|IP:115.186.65.84|WHEN:20110223|USER:watchzilla*safdar
SAFE|IP:115.186.67.194|WHEN:20110223|USER:watchzilla*safdar
SAFE|IP:115.186.68.0|WHEN:20110223|USER:sasydeals*mansoor
SAFE|IP:115.186.68.14|WHEN:20110223|USER:sasydeals*rashid
SAFE|IP:115.186.68.218|WHEN:20110223|USER:watchzilla*safdar
SAFE|IP:115.186.69.138|WHEN:20110223|USER:sasydeals*rashid
SAFE|IP:115.186.69.42|WHEN:20110223|USER:watchzilla*safdar
SAFE|IP:115.186.70.168|WHEN:20110223|USER:sasydeals*rashid
SAFE|IP:115.186.71.40|WHEN:20110223|USER:sasydeals*mansoor
SAFE|IP:115.186.72.126|WHEN:20110223|USER:sasydeals*rashid
SAFE|IP:115.186.72.147|WHEN:20110223|USER:sasydeals*mansoor
SAFE|IP:115.186.72.211|WHEN:20110223|USER:sasydeals*adnan
SAFE|IP:115.186.72.6|WHEN:20110223|USER:watchzilla*safdar
SAFE|IP:115.186.74.187|WHEN:20110223|USER:watchzilla*safdar
SAFE|IP:115.186.75.55|WHEN:20110223|USER:sasydeals*mansoor
SAFE|IP:115.42.77.182|WHEN:20110223|USER:sasydeals*rashid
SAFE|IP:117.204.143.77|WHEN:20110223|USER:woodlandimports*ADMIN
SAFE|IP:119.152.149.41|WHEN:20110223|USER:warehousedirect72*ahmed
SAFE|IP:119.152.35.81|WHEN:20110223|USER:warehousedirect72*ahmed
SAFE|IP:119.73.47.107|WHEN:20110223|USER:hakamdins*ADMIN
SAFE|IP:12.109.29.63|WHEN:20110223|USER:leos*ADMIN
SAFE|IP:121.242.76.194|WHEN:20110223|USER:gooddeals18*1
SAFE|IP:12.130.117.15|WHEN:20110223|USER:barefoottess*alison
SAFE|IP:12.130.118.187|WHEN:20110223|USER:barefoottess*katie
SAFE|IP:12.130.124.19|WHEN:20110223|USER:pricematters*zaslam
SAFE|IP:12.139.233.130|WHEN:20110223|USER:guitarelectronics*ADMIN
SAFE|IP:121.54.2.149|WHEN:20110223|USER:no1collectibles*don
SAFE|IP:12.164.28.114|WHEN:20110223|USER:jeco*tim
SAFE|IP:12.196.202.2|WHEN:20110223|USER:ledinsider*rand
SAFE|IP:12.200.24.90|WHEN:20110223|USER:4armedforces*ADMIN
SAFE|IP:12.201.86.2|WHEN:20110223|USER:guitarelectronics*ADMIN
SAFE|IP:122.147.89.200|WHEN:20110223|USER:jeco*tim
SAFE|IP:122.168.33.159|WHEN:20110223|USER:sjpacific*maynak
SAFE|IP:124.125.154.74|WHEN:20110223|USER:4armedforces*SUPPORT
SAFE|IP:12.41.26.3|WHEN:20110223|USER:redrive*lister3
SAFE|IP:12.52.42.130|WHEN:20110223|USER:pricematters*zaslam
SAFE|IP:129.6.99.50|WHEN:20110223|USER:racewax*ADMIN
SAFE|IP:131.107.0.69|WHEN:20110223|USER:envirovogue*ADMIN
SAFE|IP:134.74.48.31|WHEN:20110223|USER:watchzilla*ADMIN
SAFE|IP:134.84.45.236|WHEN:20110223|USER:bamtar*elizabeth
SAFE|IP:137.54.2.147|WHEN:20110223|USER:motorcowboy*ADMIN
SAFE|IP:138.210.106.130|WHEN:20110223|USER:teramasu*ADMIN
SAFE|IP:140.211.24.86|WHEN:20110223|USER:makepono*ADMIN
SAFE|IP:143.111.249.218|WHEN:20110223|USER:lilslavender*ADMIN
SAFE|IP:154.20.20.19|WHEN:20110223|USER:malhitrading*ADMIN
SAFE|IP:161.107.1.137|WHEN:20110223|USER:tcanyon*ADMIN
SAFE|IP:161.107.18.136|WHEN:20110223|USER:tcanyon*ADMIN
SAFE|IP:161.225.129.111|WHEN:20110223|USER:bamtar*jeff
SAFE|IP:161.225.196.111|WHEN:20110223|USER:bamtar*jeff
SAFE|IP:166.129.225.138|WHEN:20110223|USER:toynk*s
SAFE|IP:166.137.10.159|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:166.137.10.54|WHEN:20110223|USER:racewax*ADMIN
SAFE|IP:166.137.11.180|WHEN:20110223|USER:teramasu*ADMIN
SAFE|IP:166.137.11.212|WHEN:20110223|USER:coolstuff4u*bethel
SAFE|IP:166.137.11.3|WHEN:20110223|USER:pure4you*ADMIN
SAFE|IP:166.137.12.110|WHEN:20110223|USER:honeybabee*ADMIN
SAFE|IP:166.137.12.125|WHEN:20110223|USER:honeybabee*ADMIN
SAFE|IP:166.137.12.221|WHEN:20110223|USER:barefoottess*katie
SAFE|IP:166.137.12.37|WHEN:20110223|USER:fcwstores*jason
SAFE|IP:166.137.137.104|WHEN:20110223|USER:indianselections*anurag
SAFE|IP:166.137.137.158|WHEN:20110223|USER:pure4you*ADMIN
SAFE|IP:166.137.137.159|WHEN:20110223|USER:pure4you*ADMIN
SAFE|IP:166.137.137.172|WHEN:20110223|USER:indianselections*anurag
SAFE|IP:166.137.137.189|WHEN:20110223|USER:indianselections*anurag
SAFE|IP:166.137.137.229|WHEN:20110223|USER:indianselections*anurag
SAFE|IP:166.137.137.78|WHEN:20110223|USER:indianselections*anurag
SAFE|IP:166.137.138.119|WHEN:20110223|USER:indianselections*anurag
SAFE|IP:166.137.138.188|WHEN:20110223|USER:pure4you*ADMIN
SAFE|IP:166.137.138.217|WHEN:20110223|USER:indianselections*anurag
SAFE|IP:166.137.139.205|WHEN:20110223|USER:indianselections*anurag
SAFE|IP:166.137.140.125|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:166.137.140.249|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:166.137.141.145|WHEN:20110223|USER:justifieddefiance*ADMIN
SAFE|IP:166.137.141.30|WHEN:20110223|USER:justifieddefiance*edm
SAFE|IP:166.137.142.12|WHEN:20110223|USER:orangeonions*heather
SAFE|IP:166.137.142.148|WHEN:20110223|USER:justifieddefiance*edm
SAFE|IP:166.137.142.236|WHEN:20110223|USER:kool*ADMIN
SAFE|IP:166.137.15.115|WHEN:20110223|USER:toolsolutions*ADMIN
SAFE|IP:166.137.15.11|WHEN:20110223|USER:fcwstores*jason
SAFE|IP:166.137.15.240|WHEN:20110223|USER:fcwstores*jason
SAFE|IP:166.137.8.93|WHEN:20110223|USER:coolstuff4u*bethel
SAFE|IP:166.203.88.239|WHEN:20110223|USER:toynk*s
SAFE|IP:166.204.114.40|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.204.136.233|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.204.161.136|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.204.40.216|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.204.4.113|WHEN:20110223|USER:ghostinc*ADMIN
SAFE|IP:166.204.88.48|WHEN:20110223|USER:ghostinc*ADMIN
SAFE|IP:166.205.10.16|WHEN:20110223|USER:spangirl*ADMIN
SAFE|IP:166.205.10.180|WHEN:20110223|USER:caboots*joey
SAFE|IP:166.205.10.220|WHEN:20110223|USER:caboots*joey
SAFE|IP:166.205.11.170|WHEN:20110223|USER:spangirl*ADMIN
SAFE|IP:166.205.11.96|WHEN:20110223|USER:spangirl*ADMIN
SAFE|IP:166.205.12.120|WHEN:20110223|USER:beautystore*ADMIN
SAFE|IP:166.205.13.142|WHEN:20110223|USER:beautystore*aly
SAFE|IP:166.205.13.222|WHEN:20110223|USER:barefoottess*katie
SAFE|IP:166.205.136.111|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.136.15|WHEN:20110223|USER:beltiscool*bo
SAFE|IP:166.205.136.167|WHEN:20110223|USER:beltiscool*ajax
SAFE|IP:166.205.136.170|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.136.173|WHEN:20110223|USER:beltiscool*ajax
SAFE|IP:166.205.136.252|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.136.34|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.136.54|WHEN:20110223|USER:ledinsider*rand
SAFE|IP:166.205.136.72|WHEN:20110223|USER:beltiscool*ajax
SAFE|IP:166.205.137.226|WHEN:20110223|USER:ledinsider*lindy
SAFE|IP:166.205.137.230|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.137.41|WHEN:20110223|USER:beltiscool*ajax
SAFE|IP:166.205.138.100|WHEN:20110223|USER:beltiscool*ajax
SAFE|IP:166.205.138.206|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.138.231|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.138.232|WHEN:20110223|USER:beltiscool*ajax
SAFE|IP:166.205.138.253|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.138.99|WHEN:20110223|USER:beltiscool*ajax
SAFE|IP:166.205.139.10|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.139.142|WHEN:20110223|USER:beltiscool*bo
SAFE|IP:166.205.139.177|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.139.41|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.139.49|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:166.205.139.8|WHEN:20110223|USER:beltiscool*ajax
SAFE|IP:166.205.14.114|WHEN:20110223|USER:beautystore*aly
SAFE|IP:166.205.143.254|WHEN:20110223|USER:hangingm*ADMIN
SAFE|IP:166.205.14.5|WHEN:20110223|USER:beautystore*ADMIN
SAFE|IP:166.205.9.107|WHEN:20110223|USER:caboots*joey
SAFE|IP:166.205.9.147|WHEN:20110223|USER:caboots*joey
SAFE|IP:166.205.9.29|WHEN:20110223|USER:spangirl*ADMIN
SAFE|IP:166.214.106.8|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.214.113.131|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.214.115.67|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.214.132.32|WHEN:20110223|USER:ghostinc*ADMIN
SAFE|IP:166.214.172.208|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.214.189.136|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.214.250.54|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.214.45.102|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.214.73.84|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:166.249.121.239|WHEN:20110223|USER:rufusdawg*ADMIN
SAFE|IP:166.249.96.146|WHEN:20110223|USER:rufusdawg*ADMIN
SAFE|IP:167.165.53.161|WHEN:20110223|USER:espressoparts2*ADMIN
SAFE|IP:170.201.172.69|WHEN:20110223|USER:polishkitchenonline*ADMIN
SAFE|IP:170.201.180.137|WHEN:20110223|USER:polishkitchenonline*ADMIN
SAFE|IP:172.129.145.12|WHEN:20110223|USER:loblolly*
SAFE|IP:172.129.151.228|WHEN:20110223|USER:loblolly*ADMIN
SAFE|IP:172.129.157.170|WHEN:20110223|USER:loblolly*
SAFE|IP:172.129.180.245|WHEN:20110223|USER:loblolly*ADMIN
SAFE|IP:172.131.15.169|WHEN:20110223|USER:loblolly*ADMIN
SAFE|IP:172.162.213.225|WHEN:20110223|USER:diamondpenterprises*ADMIN
SAFE|IP:172.164.168.154|WHEN:20110223|USER:diamondpenterprises*ADMIN
SAFE|IP:172.164.66.188|WHEN:20110223|USER:diamondpenterprises*ADMIN
SAFE|IP:172.164.85.87|WHEN:20110223|USER:loblolly*ADMIN
SAFE|IP:172.190.126.74|WHEN:20110223|USER:diamondpenterprises*ADMIN
SAFE|IP:172.190.14.252|WHEN:20110223|USER:diamondpenterprises*ADMIN
SAFE|IP:172.190.65.206|WHEN:20110223|USER:diamondpenterprises*ADMIN
SAFE|IP:172.191.89.26|WHEN:20110223|USER:diamondpenterprises*ADMIN
SAFE|IP:173.115.248.146|WHEN:20110223|USER:yourdreamizhere*ADMIN
SAFE|IP:173.117.211.142|WHEN:20110223|USER:terracotta*ADMIN
SAFE|IP:173.118.207.220|WHEN:20110223|USER:outdoorgearco*ADMIN
SAFE|IP:173.12.176.202|WHEN:20110223|USER:kool*ADMIN
SAFE|IP:173.126.97.204|WHEN:20110223|USER:stage3motorsports*
SAFE|IP:173.128.147.0|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:173.128.18.208|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:173.13.108.162|WHEN:20110223|USER:instantgaragesales*ADMIN
SAFE|IP:173.136.6.186|WHEN:20110223|USER:4armedforces*ADMIN
SAFE|IP:173.14.185.105|WHEN:20110223|USER:performancereport*donna
SAFE|IP:173.151.235.69|WHEN:20110223|USER:spaparts*ron
SAFE|IP:173.151.65.107|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:173.153.112.86|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:173.15.59.113|WHEN:20110223|USER:bulldog*ADMIN
SAFE|IP:173.158.57.116|WHEN:20110223|USER:outdoorgearco*ADMIN
SAFE|IP:173.16.187.195|WHEN:20110223|USER:fixfind*ADMIN
SAFE|IP:173.166.183.51|WHEN:20110223|USER:barefoottess*ryan
SAFE|IP:173.180.47.119|WHEN:20110223|USER:pricematters*jsaris
SAFE|IP:173.186.54.233|WHEN:20110223|USER:dannyscollectables*ADMIN
SAFE|IP:173.200.176.45|WHEN:20110223|USER:kyledesign*orders
SAFE|IP:173.240.19.3|WHEN:20110223|USER:fixfind*steve
SAFE|IP:173.3.150.192|WHEN:20110223|USER:beltsdirect*ADMIN
SAFE|IP:173.50.120.76|WHEN:20110223|USER:onlineformals*michelle
SAFE|IP:173.51.142.97|WHEN:20110223|USER:sjpacific*
SAFE|IP:173.60.171.212|WHEN:20110223|USER:toolusa*punit
SAFE|IP:173.60.88.14|WHEN:20110223|USER:rockmusicjewelry*ADMIN
SAFE|IP:173.61.158.169|WHEN:20110223|USER:camdenbar*ADMIN
SAFE|IP:173.64.145.217|WHEN:20110223|USER:therestlessmouse*ADMIN
SAFE|IP:173.68.59.112|WHEN:20110223|USER:cannolig*ADMIN
SAFE|IP:173.72.85.158|WHEN:20110223|USER:camdenbar*ADMIN
SAFE|IP:173.72.88.36|WHEN:20110223|USER:mondaescollectibles*ADMIN
SAFE|IP:173.78.195.5|WHEN:20110223|USER:tatiana*cyndee
SAFE|IP:173.85.14.171|WHEN:20110223|USER:speedytarp*
SAFE|IP:174.1.123.22|WHEN:20110223|USER:pricematters*zaslam
SAFE|IP:174.1.120.234|WHEN:20110223|USER:pricematters*zaslam
SAFE|IP:174.129.209.37|WHEN:20110223|USER:user10328*ADMIN
SAFE|IP:174.137.10.232|WHEN:20110223|USER:beautymart*csr
SAFE|IP:174.145.159.191|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:174.150.62.79|WHEN:20110223|USER:logothreadz*clair
SAFE|IP:174.206.134.179|WHEN:20110223|USER:johnwb63*ADMIN
SAFE|IP:174.206.148.62|WHEN:20110223|USER:johnwb63*ADMIN
SAFE|IP:174.21.252.250|WHEN:20110223|USER:continental2*ADMIN
SAFE|IP:174.24.209.7|WHEN:20110223|USER:continental2*
SAFE|IP:174.252.101.244|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:174.252.102.5|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:174.252.104.173|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:174.252.112.196|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:174.252.139.101|WHEN:20110223|USER:dealz4real*ADMIN
SAFE|IP:174.252.24.195|WHEN:20110223|USER:nyciwear*ADMIN
SAFE|IP:174.252.7.124|WHEN:20110223|USER:qualityoverstock*ADMIN
SAFE|IP:174.252.97.79|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:174.253.161.132|WHEN:20110223|USER:mountaincrafts*ADMIN
SAFE|IP:174.253.179.124|WHEN:20110223|USER:mountaincrafts*ADMIN
SAFE|IP:174.253.192.135|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.192.195|WHEN:20110223|USER:naturalcures*
SAFE|IP:174.253.192.2|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.192.88|WHEN:20110223|USER:naturalcures*hoda
SAFE|IP:174.253.193.141|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.193.217|WHEN:20110223|USER:naturalcures*hoda
SAFE|IP:174.253.193.248|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.193.249|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.193.34|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.193.57|WHEN:20110223|USER:naturalcures*
SAFE|IP:174.253.194.50|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.195.206|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.195.36|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.208.160|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.209.72|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:174.253.214.128|WHEN:20110223|USER:naturalcures*hoda
SAFE|IP:174.253.228.108|WHEN:20110223|USER:homebrewer*ADMIN
SAFE|IP:174.253.72.24|WHEN:20110223|USER:beautymart*csr
SAFE|IP:174.254.0.203|WHEN:20110223|USER:homebrewer*ADMIN
SAFE|IP:174.254.16.162|WHEN:20110223|USER:homebrewer*ADMIN
SAFE|IP:174.254.19.139|WHEN:20110223|USER:paintspray*ADMIN
SAFE|IP:174.254.21.139|WHEN:20110223|USER:homebrewer*ADMIN
SAFE|IP:174.254.21.173|WHEN:20110223|USER:greatlookz*anastasia
SAFE|IP:174.254.3.75|WHEN:20110223|USER:paintspray*ADMIN
SAFE|IP:174.254.4.105|WHEN:20110223|USER:homebrewer*ADMIN
SAFE|IP:174.254.55.123|WHEN:20110223|USER:yocaps*john
SAFE|IP:174.254.55.168|WHEN:20110223|USER:yocaps*john
SAFE|IP:174.254.56.205|WHEN:20110223|USER:stealthcycling*ADMIN
SAFE|IP:174.254.57.168|WHEN:20110223|USER:pacificpetshop*ADMIN
SAFE|IP:174.254.61.65|WHEN:20110223|USER:yocaps*john
SAFE|IP:174.254.64.11|WHEN:20110223|USER:yocaps*john
SAFE|IP:174.254.65.78|WHEN:20110223|USER:yocaps*john
SAFE|IP:174.254.67.147|WHEN:20110223|USER:yocaps*john
SAFE|IP:174.254.72.127|WHEN:20110223|USER:yocaps*john
SAFE|IP:174.254.82.223|WHEN:20110223|USER:stealthcycling*ADMIN
SAFE|IP:174.26.195.41|WHEN:20110223|USER:homebrewer*stephen
SAFE|IP:174.26.196.181|WHEN:20110223|USER:homebrewer*shop
SAFE|IP:174.30.130.125|WHEN:20110223|USER:purewave*buyit
SAFE|IP:174.30.131.203|WHEN:20110223|USER:purewave*buyit
SAFE|IP:174.30.133.39|WHEN:20110223|USER:purewave*buyit
SAFE|IP:174.45.57.109|WHEN:20110223|USER:dhsproducts*dallas
SAFE|IP:174.50.219.92|WHEN:20110223|USER:totalfanshop*ADMIN
SAFE|IP:174.54.97.44|WHEN:20110223|USER:racewax*ADMIN
SAFE|IP:174.54.99.66|WHEN:20110223|USER:racewax*
SAFE|IP:174.61.48.213|WHEN:20110223|USER:thecubanshop*ADMIN
SAFE|IP:174.6.35.66|WHEN:20110223|USER:malhitrading*
SAFE|IP:174.65.133.67|WHEN:20110223|USER:thesavewave*kchin
SAFE|IP:174.79.254.30|WHEN:20110223|USER:bandt*1
SAFE|IP:184.12.88.19|WHEN:20110223|USER:gkworld*karen
SAFE|IP:184.189.231.199|WHEN:20110223|USER:epsparts*ADMIN
SAFE|IP:184.192.117.37|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:184.192.209.23|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:184.192.23.200|WHEN:20110223|USER:stage3motorsports*ADMIN
SAFE|IP:184.192.33.168|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:184.193.152.9|WHEN:20110223|USER:spaparts*ron
SAFE|IP:184.194.134.34|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:184.195.73.91|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:184.200.194.252|WHEN:20110223|USER:totalfanshop*ADMIN
SAFE|IP:184.218.120.73|WHEN:20110223|USER:yourdreamizhere*ADMIN
SAFE|IP:184.218.146.21|WHEN:20110223|USER:yourdreamizhere*ADMIN
SAFE|IP:184.232.59.118|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:184.235.73.13|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:184.252.241.44|WHEN:20110223|USER:softenerparts*kate
SAFE|IP:184.36.182.65|WHEN:20110223|USER:user10330*ADMIN
SAFE|IP:184.38.57.56|WHEN:20110223|USER:fcwstores*jason
SAFE|IP:184.52.152.106|WHEN:20110223|USER:smyrnacoin*guy
SAFE|IP:184.52.45.102|WHEN:20110223|USER:alloceansports*ADMIN
SAFE|IP:184.75.52.66|WHEN:20110223|USER:qcollection*lauren
SAFE|IP:184.97.133.214|WHEN:20110223|USER:agandb*sayer
SAFE|IP:184.97.138.91|WHEN:20110223|USER:agandb*sayer
SAFE|IP:184.9.98.230|WHEN:20110223|USER:abbys*ADMIN
SAFE|IP:190.159.194.196|WHEN:20110223|USER:speedaddictcycles*ADMIN
SAFE|IP:192.12.13.2|WHEN:20110223|USER:yourdreamizhere*rifky
SAFE|IP:192.122.244.237|WHEN:20110223|USER:underthesun*ADMIN
SAFE|IP:192.160.117.147|WHEN:20110223|USER:buystonesonline*ADMIN
SAFE|IP:192.168.2.240|WHEN:20110223|USER:polishkitchenonline*SUPPORT
SAFE|IP:196.201.203.83|WHEN:20110223|USER:silverchicks*catie
SAFE|IP:198.202.202.21|WHEN:20110223|USER:gssstore*ADMIN
SAFE|IP:198.45.18.20|WHEN:20110223|USER:jheveran*ADMIN
SAFE|IP:199.227.23.218|WHEN:20110223|USER:racerwalsh*ADMIN
SAFE|IP:199.36.244.21|WHEN:20110223|USER:toynk*s
SAFE|IP:202.131.112.57|WHEN:20110223|USER:4armedforces*SUPPORT
SAFE|IP:203.81.194.230|WHEN:20110223|USER:denimsquare*nomaan
SAFE|IP:204.77.224.2|WHEN:20110223|USER:barefoottess*alison
SAFE|IP:204.9.111.230|WHEN:20110223|USER:scalesusa*ADMIN
SAFE|IP:205.188.116.135|WHEN:20110223|USER:europottery*ADMIN
SAFE|IP:205.188.116.138|WHEN:20110223|USER:candlemakers*steve
SAFE|IP:205.188.116.209|WHEN:20110223|USER:candlemakers*steve
SAFE|IP:205.188.117.19|WHEN:20110223|USER:irresistables*ADMIN
SAFE|IP:205.188.117.6|WHEN:20110223|USER:irresistables*ADMIN
SAFE|IP:205.201.170.136|WHEN:20110223|USER:pacificpetshop*ADMIN
SAFE|IP:206.111.100.130|WHEN:20110223|USER:sallyrdhd*ADMIN
SAFE|IP:206.29.188.186|WHEN:20110223|USER:gembeadmall*ADMIN
SAFE|IP:207.172.172.154|WHEN:20110223|USER:chiquelife*ADMIN
SAFE|IP:207.200.112.43|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.112.66|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.112.71|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.10|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.11|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.130|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.131|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.132|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.133|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.134|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.135|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.136|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.137|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.138|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.139|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.13|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.14|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.5|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.65|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.66|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.67|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.68|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.69|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.6|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.71|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.72|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.74|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.7|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.8|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.200.116.9|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:207.224.127.253|WHEN:20110223|USER:oaktree*ADMIN
SAFE|IP:207.230.82.162|WHEN:20110223|USER:frogpondaquatics*ADMIN
SAFE|IP:207.237.171.225|WHEN:20110223|USER:indianselections*anurag
SAFE|IP:207.250.52.225|WHEN:20110223|USER:jdhines*ADMIN
SAFE|IP:207.254.242.239|WHEN:20110223|USER:mosaictilegroup*haleigh
SAFE|IP:208.100.137.93|WHEN:20110223|USER:makepono*ADMIN
SAFE|IP:208.105.5.246|WHEN:20110223|USER:onequickcup*tara
SAFE|IP:208.127.128.156|WHEN:20110223|USER:trophywifeclothing*ADMIN
SAFE|IP:208.186.151.134|WHEN:20110223|USER:pawstogo*monique
SAFE|IP:208.54.4.36|WHEN:20110223|USER:toynk*s
SAFE|IP:208.54.7.189|WHEN:20110223|USER:toynk*s
SAFE|IP:208.57.87.220|WHEN:20110223|USER:discountgunmart*jabie
SAFE|IP:208.94.80.78|WHEN:20110223|USER:naturalcures*carla
SAFE|IP:209.191.217.194|WHEN:20110223|USER:itascamoccasin*ADMIN
SAFE|IP:209.193.111.96|WHEN:20110223|USER:bamtar*jeff
SAFE|IP:209.248.150.246|WHEN:20110223|USER:thomassales*ADMIN
SAFE|IP:209.255.156.130|WHEN:20110223|USER:andreasinc*ADMIN
SAFE|IP:209.26.36.146|WHEN:20110223|USER:babology*macy
SAFE|IP:209.30.93.210|WHEN:20110223|USER:aaavacs*ADMIN
SAFE|IP:209.33.213.251|WHEN:20110223|USER:dhsproducts*info
SAFE|IP:211.8.119.133|WHEN:20110223|USER:kseiya*ADMIN
SAFE|IP:216.127.127.194|WHEN:20110223|USER:marcel*celinda
SAFE|IP:216.131.100.174|WHEN:20110223|USER:replaceyourcell*elaine
SAFE|IP:216.224.247.146|WHEN:20110223|USER:stage3motorsports*web
SAFE|IP:216.228.88.14|WHEN:20110223|USER:bbrothersc*ashleyb04
SAFE|IP:216.228.88.5|WHEN:20110223|USER:bbrothersc*ADMIN
SAFE|IP:216.24.198.240|WHEN:20110223|USER:wildcollections*john
SAFE|IP:216.24.201.60|WHEN:20110223|USER:wildcollections*john
SAFE|IP:216.45.232.2|WHEN:20110223|USER:bamtar*elizabeth
SAFE|IP:216.45.232.38|WHEN:20110223|USER:bamtar*elizabeth
SAFE|IP:216.45.233.197|WHEN:20110223|USER:bamtar*elizabeth
SAFE|IP:216.45.233.21|WHEN:20110223|USER:bamtar*elizabeth
SAFE|IP:216.47.59.230|WHEN:20110223|USER:thebunkhouse*ADMIN
SAFE|IP:216.70.177.251|WHEN:20110223|USER:discountgunmart*willh
SAFE|IP:216.87.237.218|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:216.96.42.223|WHEN:20110223|USER:dannyscollectables*ADMIN
SAFE|IP:218.225.184.99|WHEN:20110223|USER:kseiya*ADMIN
SAFE|IP:24.10.140.152|WHEN:20110223|USER:thegoodtimber*ADMIN
SAFE|IP:24.10.140.167|WHEN:20110223|USER:thegoodtimber*sec1
SAFE|IP:24.115.119.51|WHEN:20110223|USER:rittersgifts*ADMIN
SAFE|IP:24.119.244.34|WHEN:20110223|USER:beautymart*
SAFE|IP:24.12.154.85|WHEN:20110223|USER:redrive*lister1
SAFE|IP:24.123.197.246|WHEN:20110223|USER:rapiddirection*ADMIN
SAFE|IP:24.126.170.251|WHEN:20110223|USER:etooti*ADMIN
SAFE|IP:24.12.98.194|WHEN:20110223|USER:cdphonehome*leo
SAFE|IP:24.13.148.32|WHEN:20110223|USER:cubworld*ADMIN
SAFE|IP:24.14.149.230|WHEN:20110223|USER:woodlandimports*ADMIN
SAFE|IP:24.153.223.123|WHEN:20110223|USER:beautystore*aly
SAFE|IP:24.16.165.137|WHEN:20110223|USER:lilslavender*ADMIN
SAFE|IP:24.16.166.110|WHEN:20110223|USER:lilslavender*ADMIN
SAFE|IP:24.162.197.251|WHEN:20110223|USER:caboots*joey
SAFE|IP:24.163.5.100|WHEN:20110223|USER:mugheaven*ADMIN
SAFE|IP:24.170.227.252|WHEN:20110223|USER:trd*ADMIN
SAFE|IP:24.17.199.109|WHEN:20110223|USER:envirovogue*
SAFE|IP:24.172.129.33|WHEN:20110223|USER:candlemakers*laura
SAFE|IP:24.172.156.130|WHEN:20110223|USER:candlemakers*marketing
SAFE|IP:24.176.96.54|WHEN:20110223|USER:froggysfog*ADMIN
SAFE|IP:24.180.26.90|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:24.186.126.164|WHEN:20110223|USER:fairdeals*ADMIN
SAFE|IP:24.189.162.195|WHEN:20110223|USER:yourdreamizhere*gitty
SAFE|IP:24.191.114.156|WHEN:20110223|USER:uaamerica*ADMIN
SAFE|IP:24.20.103.194|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:24.20.126.133|WHEN:20110223|USER:saasexpertsintlinc*ADMIN
SAFE|IP:24.20.238.163|WHEN:20110223|USER:hangingm*ADMIN
SAFE|IP:24.20.238.22|WHEN:20110223|USER:hangingm*ADMIN
SAFE|IP:24.207.170.60|WHEN:20110223|USER:elegantbed*jeff
SAFE|IP:24.215.39.103|WHEN:20110223|USER:musclextreme*ADMIN
SAFE|IP:24.215.8.238|WHEN:20110223|USER:musclextreme*ADMIN
SAFE|IP:24.227.246.21|WHEN:20110223|USER:studiohut*ADMIN
SAFE|IP:24.228.217.107|WHEN:20110223|USER:tting*chirag
SAFE|IP:24.228.223.114|WHEN:20110223|USER:tting*bo_rsong
SAFE|IP:24.23.73.4|WHEN:20110223|USER:geoffhavens*geff
SAFE|IP:24.242.225.196|WHEN:20110223|USER:yellowrose*ADMIN
SAFE|IP:24.249.48.63|WHEN:20110223|USER:designwraps*jan
SAFE|IP:24.251.109.80|WHEN:20110223|USER:purewave*joe
SAFE|IP:24.251.183.62|WHEN:20110223|USER:greatlookz*ADMIN
SAFE|IP:24.253.25.126|WHEN:20110223|USER:jdhines*ADMIN
SAFE|IP:24.255.43.19|WHEN:20110223|USER:greatlookz*anastasia
SAFE|IP:24.34.193.108|WHEN:20110223|USER:mypolishpottery*ADMIN
SAFE|IP:24.43.47.143|WHEN:20110223|USER:shop4toyz*ADMIN
SAFE|IP:24.47.146.138|WHEN:20110223|USER:creative*ADMIN
SAFE|IP:24.5.157.123|WHEN:20110223|USER:dcitti*ADMIN
SAFE|IP:24.52.42.6|WHEN:20110223|USER:pocketwatcher*
SAFE|IP:24.56.19.25|WHEN:20110223|USER:guitarelectronics*ADMIN
SAFE|IP:24.7.116.235|WHEN:20110223|USER:greencig*ADMIN
SAFE|IP:24.7.25.113|WHEN:20110223|USER:finchremarketing*
SAFE|IP:24.92.169.177|WHEN:20110223|USER:golfswingtrainer*ADMIN
SAFE|IP:24.92.64.239|WHEN:20110223|USER:rays*ADMIN
SAFE|IP:24.94.80.147|WHEN:20110223|USER:tikimaster*ava
SAFE|IP:24.99.14.68|WHEN:20110223|USER:mccoypress*ADMIN
SAFE|IP:24.99.161.234|WHEN:20110223|USER:warehousedirect72*ADMIN
SAFE|IP:32.179.101.48|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:32.179.129.155|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:32.179.173.63|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:32.179.179.4|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:32.179.225.118|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:32.179.251.141|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:32.179.36.226|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:32.179.40.186|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:32.179.58.31|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:32.179.66.94|WHEN:20110223|USER:bonnies*ADMIN
SAFE|IP:38.117.192.246|WHEN:20110223|USER:fairdeals*ADMIN
SAFE|IP:38.117.192.27|WHEN:20110223|USER:perfumecenteronline*ADMIN
SAFE|IP:38.117.214.195|WHEN:20110223|USER:watchmaster*ADMIN
SAFE|IP:38.98.36.178|WHEN:20110223|USER:zephyrsports*ymacias
SAFE|IP:41.189.232.234|WHEN:20110223|USER:silverchicks*catie
SAFE|IP:41.189.235.60|WHEN:20110223|USER:silverchicks*catie
SAFE|IP:50.14.181.169|WHEN:20110223|USER:perfumecenteronline*ADMIN
SAFE|IP:50.88.163.248|WHEN:20110223|USER:coolstuff4u*jeff
SAFE|IP:50.88.166.220|WHEN:20110223|USER:moetown55*ADMIN
SAFE|IP:50.9.159.81|WHEN:20110223|USER:autrysports*ADMIN
SAFE|IP:50.9.8.106|WHEN:20110223|USER:cdphonehome*ADMIN
SAFE|IP:59.90.34.224|WHEN:20110223|USER:gooddeals18*1
SAFE|IP:59.95.64.113|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.64.149|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.64.180|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.65.201|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.67.159|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.67.169|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.68.10|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.69.234|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.70.156|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.70.95|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.71.229|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.74.173|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.74.208|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.95.77.209|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:59.96.176.31|WHEN:20110223|USER:indianselections*ADMIN
SAFE|IP:63.163.109.112|WHEN:20110223|USER:amigaz*joel
SAFE|IP:63.202.225.121|WHEN:20110223|USER:gembeadmall*ADMIN
SAFE|IP:63.202.225.126|WHEN:20110223|USER:gembeadmall*ADMIN
SAFE|IP:63.229.113.207|WHEN:20110223|USER:homebrewer*dottie
SAFE|IP:63.230.204.11|WHEN:20110223|USER:homebrewer*dottie
SAFE|IP:63.235.11.2|WHEN:20110223|USER:gssstore*ADMIN
SAFE|IP:63.239.219.98|WHEN:20110223|USER:icsicontrols*ADMIN
SAFE|IP:63.248.32.143|WHEN:20110223|USER:thegoodtimber*web
SAFE|IP:63.78.73.130|WHEN:20110223|USER:designed2bsweet*apple
SAFE|IP:63.86.120.161|WHEN:20110223|USER:fixfind*
SAFE|IP:64.12.116.76|WHEN:20110223|USER:irresistables*ADMIN
SAFE|IP:64.12.116.78|WHEN:20110223|USER:irresistables*ADMIN
SAFE|IP:64.12.117.16|WHEN:20110223|USER:irresistables*ADMIN
SAFE|IP:64.12.117.73|WHEN:20110223|USER:irresistables*ADMIN
SAFE|IP:64.12.117.7|WHEN:20110223|USER:europottery*ADMIN
SAFE|IP:64.121.86.178|WHEN:20110223|USER:2bhip*brian
SAFE|IP:64.122.192.54|WHEN:20110223|USER:thechessstore*jon
SAFE|IP:64.122.217.154|WHEN:20110223|USER:bamtar*miles
SAFE|IP:64.122.245.148|WHEN:20110223|USER:leedor*ADMIN
SAFE|IP:64.130.66.93|WHEN:20110223|USER:gourmet*ADMIN
SAFE|IP:64.134.226.241|WHEN:20110223|USER:webstrings*ADMIN
SAFE|IP:64.179.187.21|WHEN:20110223|USER:girlfriendgalas*ADMIN
SAFE|IP:64.197.8.107|WHEN:20110223|USER:exportinghome*lauren
SAFE|IP:64.234.86.148|WHEN:20110223|USER:helmethead2*ADMIN
SAFE|IP:64.234.89.160|WHEN:20110223|USER:helmethead2*ADMIN
SAFE|IP:64.253.139.163|WHEN:20110223|USER:pricematters*crystal
SAFE|IP:64.255.164.39|WHEN:20110223|USER:panrack*dave
SAFE|IP:64.255.180.168|WHEN:20110223|USER:panrack*dave
SAFE|IP:64.255.180.234|WHEN:20110223|USER:panrack*dave
SAFE|IP:64.37.183.97|WHEN:20110223|USER:pacificpetshop*ADMIN
SAFE|IP:64.58.179.74|WHEN:20110223|USER:sallyrdhd*ADMIN
SAFE|IP:64.60.209.74|WHEN:20110223|USER:zephyrsports*rpm
SAFE|IP:64.73.238.90|WHEN:20110223|USER:ledinsider*lindy
SAFE|IP:64.77.199.129|WHEN:20110223|USER:pocketwatcher*ADMIN
SAFE|IP:64.81.47.106|WHEN:20110223|USER:halebob*concierge
SAFE|IP:64.89.246.84|WHEN:20110223|USER:springbreak*ADMIN
SAFE|IP:65.102.157.114|WHEN:20110223|USER:espressoparts2*darin
SAFE|IP:65.107.99.165|WHEN:20110223|USER:gogoods*cmakris
SAFE|IP:65.119.4.32|WHEN:20110223|USER:ctech*ADMIN
SAFE|IP:65.15.19.76|WHEN:20110223|USER:ghostinc*ADMIN
SAFE|IP:65.182.48.185|WHEN:20110223|USER:honeybabee*ADMIN
SAFE|IP:65.185.179.158|WHEN:20110223|USER:kcint*kevin
SAFE|IP:65.185.58.89|WHEN:20110223|USER:justifieddefiance*edm
SAFE|IP:65.243.151.188|WHEN:20110223|USER:atozgifts*sam
SAFE|IP:65.35.73.39|WHEN:20110223|USER:andreasinc*ADMIN
SAFE|IP:65.40.199.146|WHEN:20110223|USER:highpointscientific*gporter
SAFE|IP:65.42.208.133|WHEN:20110223|USER:espressoparts2*ADMIN
SAFE|IP:66.114.39.194|WHEN:20110223|USER:pricematters*zaslam
SAFE|IP:66.118.223.226|WHEN:20110223|USER:davidcombs*ADMIN
SAFE|IP:66.119.9.207|WHEN:20110223|USER:thomassales*ADMIN
SAFE|IP:66.134.76.34|WHEN:20110223|USER:gkworld*SUPPORT
SAFE|IP:66.15.3.222|WHEN:20110223|USER:surfcitymusic*ADMIN
SAFE|IP:66.155.189.2|WHEN:20110223|USER:espressoparts2*
SAFE|IP:66.161.134.98|WHEN:20110223|USER:shopdownlite*ADMIN
SAFE|IP:66.177.180.151|WHEN:20110223|USER:beachmart*nitin
SAFE|IP:66.182.4.82|WHEN:20110223|USER:dcitti*ADMIN
SAFE|IP:66.183.50.196|WHEN:20110223|USER:pricematters*nadeem
SAFE|IP:66.195.185.218|WHEN:20110223|USER:naturalcures*ADMIN
SAFE|IP:66.196.207.68|WHEN:20110223|USER:inovar*ADMIN
SAFE|IP:66.220.110.228|WHEN:20110223|USER:spitsadventurewear*carrie
SAFE|IP:66.220.96.62|WHEN:20110223|USER:spitsadventurewear*david
SAFE|IP:66.240.244.217|WHEN:20110223|USER:ramh*SUPPORT
SAFE|IP:66.36.112.8|WHEN:20110223|USER:mountaincrafts*ADMIN
SAFE|IP:66.55.54.106|WHEN:20110223|USER:colocustommetal*ppseo
SAFE|IP:66.61.43.43|WHEN:20110223|USER:bargaincds*ADMIN
SAFE|IP:66.67.22.210|WHEN:20110223|USER:equinefashionandtack*linda
SAFE|IP:66.69.254.34|WHEN:20110223|USER:austinbazaar*ADMIN
SAFE|IP:66.76.239.50|WHEN:20110223|USER:cardiacwellness*ship
SAFE|IP:66.78.202.165|WHEN:20110223|USER:leisure*ADMIN
SAFE|IP:67.103.169.74|WHEN:20110223|USER:blitz*laurad
SAFE|IP:67.1.29.39|WHEN:20110223|USER:purewave*buyit
SAFE|IP:67.142.130.19|WHEN:20110223|USER:gourmet*ADMIN
SAFE|IP:67.142.130.40|WHEN:20110223|USER:gourmet*ADMIN
SAFE|IP:67.142.172.20|WHEN:20110223|USER:alloceansports*ADMIN
SAFE|IP:67.142.172.24|WHEN:20110223|USER:alloceansports*ADMIN
SAFE|IP:67.142.173.22|WHEN:20110223|USER:smyrnacoin*bonnie
SAFE|IP:67.142.173.25|WHEN:20110223|USER:smyrnacoin*guy
SAFE|IP:67.142.173.26|WHEN:20110223|USER:smyrnacoin*bonnie
SAFE|IP:67.142.173.27|WHEN:20110223|USER:smyrnacoin*bonnie
SAFE|IP:67.160.40.44|WHEN:20110223|USER:espressoparts2*ADMIN
SAFE|IP:67.173.164.167|WHEN:20110223|USER:irresistables*ADMIN
SAFE|IP:67.173.53.0|WHEN:20110223|USER:cubworld*sean
SAFE|IP:67.182.209.154|WHEN:20110223|USER:wildemats*ADMIN
SAFE|IP:67.182.43.184|WHEN:20110223|USER:rcraven*ADMIN
SAFE|IP:67.186.84.147|WHEN:20110223|USER:toynk*tim
SAFE|IP:67.188.18.175|WHEN:20110223|USER:expeditionimports*ADMIN
SAFE|IP:67.201.86.8|WHEN:20110223|USER:indianselections*anurag
SAFE|IP:67.204.155.239|WHEN:20110223|USER:makepono*
SAFE|IP:67.220.27.177|WHEN:20110223|USER:bamtar*smith
SAFE|IP:67.238.98.130|WHEN:20110223|USER:tooltaker*ADMIN
SAFE|IP:67.240.245.206|WHEN:20110223|USER:equinefashionandtack*
SAFE|IP:67.247.41.144|WHEN:20110223|USER:sasydeals*ADMIN
SAFE|IP:67.40.231.90|WHEN:20110223|USER:allpetsolutions*ADMIN
SAFE|IP:67.41.181.103|WHEN:20110223|USER:furnitureonline*angela
SAFE|IP:67.47.90.29|WHEN:20110223|USER:gourmet*ADMIN
SAFE|IP:67.49.122.84|WHEN:20110223|USER:surfcitymusic*ADMIN
SAFE|IP:67.49.70.30|WHEN:20110223|USER:amphidex*ADMIN
SAFE|IP:67.60.46.13|WHEN:20110223|USER:thunderprint*ADMIN
SAFE|IP:67.60.72.173|WHEN:20110223|USER:pony*ADMIN
SAFE|IP:67.78.117.128|WHEN:20110223|USER:austinbazaar*chris
SAFE|IP:67.78.250.50|WHEN:20110223|USER:coolstuff4u*gparker
SAFE|IP:67.80.203.98|WHEN:20110223|USER:ibuystores*mariopasq
SAFE|IP:67.81.141.102|WHEN:20110223|USER:sassyassybjeans*kristen
SAFE|IP:67.82.4.29|WHEN:20110223|USER:tting*hyunkim
SAFE|IP:67.82.55.154|WHEN:20110223|USER:ibuystores*ADMIN
SAFE|IP:68.0.136.199|WHEN:20110223|USER:pawstogo*monique
SAFE|IP:68.110.229.57|WHEN:20110223|USER:froggysfog*ADMIN
SAFE|IP:68.127.148.110|WHEN:20110223|USER:ayoungenterprise*ADMIN
SAFE|IP:68.127.171.191|WHEN:20110223|USER:ayoungenterprise*ADMIN
SAFE|IP:68.13.209.39|WHEN:20110223|USER:amulets*ADMIN
SAFE|IP:68.13.238.241|WHEN:20110223|USER:sweetwaterscavenger*ADMIN
SAFE|IP:68.14.237.38|WHEN:20110223|USER:monsterrebate*ADMIN
SAFE|IP:68.157.212.200|WHEN:20110223|USER:jewelriver*ADMIN
SAFE|IP:68.161.112.69|WHEN:20110223|USER:qualityoverstock*draisy
SAFE|IP:68.167.107.46|WHEN:20110223|USER:johnwb63*ADMIN
SAFE|IP:68.167.82.130|WHEN:20110223|USER:partylytes*sam
SAFE|IP:68.173.32.74|WHEN:20110223|USER:pure4you*ADMIN
SAFE|IP:68.175.108.9|WHEN:20110223|USER:pure4you*ADMIN
SAFE|IP:68.183.121.119|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:68.185.195.190|WHEN:20110223|USER:autrysports*ADMIN
SAFE|IP:68.189.8.32|WHEN:20110223|USER:cobysfund*ADMIN
SAFE|IP:68.190.26.90|WHEN:20110223|USER:bubbas*ADMIN
SAFE|IP:68.192.23.16|WHEN:20110223|USER:ibuystores*ADMIN
SAFE|IP:68.192.235.68|WHEN:20110223|USER:tting*service
SAFE|IP:68.192.37.236|WHEN:20110223|USER:tting*jeremiahl
SAFE|IP:68.193.188.26|WHEN:20110223|USER:partylytes*
SAFE|IP:68.224.138.144|WHEN:20110223|USER:lasvegasfurniture*ADMIN
SAFE|IP:68.225.69.59|WHEN:20110223|USER:fcwstores*ADMIN
SAFE|IP:68.228.75.152|WHEN:20110223|USER:goshotcamera*op
SAFE|IP:68.231.145.192|WHEN:20110223|USER:huckleberryib*ADMIN
SAFE|IP:68.231.83.81|WHEN:20110223|USER:pranahealingarts*ADMIN
SAFE|IP:68.238.140.175|WHEN:20110223|USER:dinkysduds*ADMIN
SAFE|IP:68.238.199.67|WHEN:20110223|USER:rittersgifts*martha
SAFE|IP:68.238.212.227|WHEN:20110223|USER:rittersgifts*martha
SAFE|IP:68.238.253.250|WHEN:20110223|USER:4my3boyz*ADMIN
SAFE|IP:68.247.152.239|WHEN:20110223|USER:yourdreamizhere*ADMIN
SAFE|IP:68.253.212.162|WHEN:20110223|USER:dsbmktg*ADMIN
SAFE|IP:68.255.101.214|WHEN:20110223|USER:q3artinc*ADMIN
SAFE|IP:68.27.102.125|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:68.27.62.185|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:68.27.64.213|WHEN:20110223|USER:affordableproducts*ADMIN
SAFE|IP:68.27.67.193|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:68.29.41.6|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:68.29.62.186|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:68.3.184.21|WHEN:20110223|USER:girlfriendgalas*janna
SAFE|IP:68.33.58.78|WHEN:20110223|USER:barefoottess*tracey
SAFE|IP:68.34.121.59|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:68.35.46.45|WHEN:20110223|USER:paintspray*ADMIN
SAFE|IP:68.36.10.155|WHEN:20110223|USER:mondaescollectibles*ADMIN
SAFE|IP:68.36.240.156|WHEN:20110223|USER:tting*chirag
SAFE|IP:68.39.23.63|WHEN:20110223|USER:toonstation*
SAFE|IP:68.41.150.207|WHEN:20110223|USER:geoffhavens*geff
SAFE|IP:68.41.209.232|WHEN:20110223|USER:flymode*ADMIN
SAFE|IP:68.4.243.93|WHEN:20110223|USER:rockmusicjewelry*ADMIN
SAFE|IP:68.42.65.157|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:68.61.187.165|WHEN:20110223|USER:summitfashions*bill
SAFE|IP:68.68.34.76|WHEN:20110223|USER:replaceyourcell*elaine
SAFE|IP:68.68.36.71|WHEN:20110223|USER:replaceyourcell*elaine
SAFE|IP:68.7.209.55|WHEN:20110223|USER:mattb*ADMIN
SAFE|IP:68.80.206.111|WHEN:20110223|USER:amigaz*joel
SAFE|IP:68.82.128.198|WHEN:20110223|USER:amigaz*laura
SAFE|IP:68.82.229.22|WHEN:20110223|USER:temdee*2
SAFE|IP:68.96.72.244|WHEN:20110223|USER:sallyrdhd*ADMIN
SAFE|IP:69.108.121.98|WHEN:20110223|USER:buttony*
SAFE|IP:69.112.201.204|WHEN:20110223|USER:replaceyourcell*ADMIN
SAFE|IP:69.112.39.140|WHEN:20110223|USER:dealz4real*bill
SAFE|IP:69.112.88.31|WHEN:20110223|USER:replaceyourcell*ADMIN
SAFE|IP:69.113.126.26|WHEN:20110223|USER:replaceyourcell*shemek
SAFE|IP:69.113.36.196|WHEN:20110223|USER:tting*bo_rsong
SAFE|IP:69.113.36.231|WHEN:20110223|USER:tting*bo_rsong
SAFE|IP:69.115.175.221|WHEN:20110223|USER:sassyassybjeans*ron
SAFE|IP:69.122.125.221|WHEN:20110223|USER:victorianshop*ADMIN
SAFE|IP:69.122.125.30|WHEN:20110223|USER:victorianshop*ADMIN
SAFE|IP:69.122.179.34|WHEN:20110223|USER:gooddeals18*ADMIN
SAFE|IP:69.122.81.123|WHEN:20110223|USER:victorianshop*ADMIN
SAFE|IP:69.122.91.234|WHEN:20110223|USER:qualityoverstock*draisy
SAFE|IP:69.123.242.113|WHEN:20110223|USER:tting*bo_rsong
SAFE|IP:69.123.242.147|WHEN:20110223|USER:tting*bo_rsong
SAFE|IP:69.123.242.243|WHEN:20110223|USER:tting*bo_rsong
SAFE|IP:69.123.242.40|WHEN:20110223|USER:tting*chirag
SAFE|IP:69.123.246.202|WHEN:20110223|USER:tting*bo_rsong
SAFE|IP:69.123.247.243|WHEN:20110223|USER:tting*bo_rsong
SAFE|IP:69.132.209.242|WHEN:20110223|USER:frogpondaquatics*ADMIN
SAFE|IP:69.133.123.161|WHEN:20110223|USER:rufusdawg*ADMIN
SAFE|IP:69.143.70.231|WHEN:20110223|USER:barefoottess*ryan
SAFE|IP:69.151.157.113|WHEN:20110223|USER:rusted01*ADMIN
SAFE|IP:69.151.217.53|WHEN:20110223|USER:rusted01*ADMIN
SAFE|IP:69.151.8.29|WHEN:20110223|USER:wallsthatspeak*ADMIN
SAFE|IP:69.153.203.51|WHEN:20110223|USER:bibshoppe*ADMIN
SAFE|IP:69.168.140.186|WHEN:20110223|USER:rpmcycle*ADMIN
SAFE|IP:69.178.141.173|WHEN:20110223|USER:jeco*nikki
SAFE|IP:69.179.111.104|WHEN:20110223|USER:dutchsheets*ADMIN
SAFE|IP:69.179.111.110|WHEN:20110223|USER:dutchsheets*ADMIN
SAFE|IP:69.19.14.33|WHEN:20110223|USER:outofthetoybox*mike
SAFE|IP:69.199.29.222|WHEN:20110223|USER:gssstore*ADMIN
SAFE|IP:69.206.174.230|WHEN:20110223|USER:gkworld*greg
SAFE|IP:69.21.200.201|WHEN:20110223|USER:courtneybrooke*ADMIN
SAFE|IP:69.221.173.225|WHEN:20110223|USER:sacredengraving*ADMIN
SAFE|IP:69.234.178.32|WHEN:20110223|USER:misternostalgia*ADMIN
SAFE|IP:69.234.200.230|WHEN:20110223|USER:misternostalgia*ADMIN
SAFE|IP:69.234.210.199|WHEN:20110223|USER:misternostalgia*ADMIN
SAFE|IP:69.255.168.66|WHEN:20110223|USER:user10316*ADMIN
SAFE|IP:69.27.145.148|WHEN:20110223|USER:panrack*joanne
SAFE|IP:69.33.39.39|WHEN:20110223|USER:greatlookz*ADMIN
SAFE|IP:69.33.39.40|WHEN:20110223|USER:greatlookz*pam
SAFE|IP:69.33.39.42|WHEN:20110223|USER:greatlookz*pam
SAFE|IP:69.33.39.43|WHEN:20110223|USER:greatlookz*ADMIN
SAFE|IP:69.33.39.44|WHEN:20110223|USER:greatlookz*josh
SAFE|IP:69.35.26.145|WHEN:20110223|USER:outofthetoybox*pam
SAFE|IP:69.35.78.235|WHEN:20110223|USER:outofthetoybox*pam
SAFE|IP:69.38.249.37|WHEN:20110223|USER:highpointscientific*ADMIN
SAFE|IP:69.62.254.147|WHEN:20110223|USER:designed2bsweet*pin
SAFE|IP:69.77.159.91|WHEN:20110223|USER:hillbillysales*ADMIN
SAFE|IP:69.86.202.67|WHEN:20110223|USER:elegantaudio*ADMIN
SAFE|IP:69.95.188.90|WHEN:20110223|USER:kcint*kevin
SAFE|IP:70.104.252.26|WHEN:20110223|USER:poshuniforms*
SAFE|IP:70.107.228.12|WHEN:20110223|USER:partylytes*sam
SAFE|IP:70.121.147.34|WHEN:20110223|USER:highpointscientific*ADMIN
SAFE|IP:70.121.51.91|WHEN:20110223|USER:coolstuff4u*jeff
SAFE|IP:70.121.52.47|WHEN:20110223|USER:moetown55*ADMIN
SAFE|IP:70.122.233.191|WHEN:20110223|USER:gssstore*jilld
SAFE|IP:70.125.41.220|WHEN:20110223|USER:reefs2go*ADMIN
SAFE|IP:70.141.196.6|WHEN:20110223|USER:timaustrums*custserv
SAFE|IP:70.144.80.240|WHEN:20110223|USER:fdishops*ADMIN
SAFE|IP:70.15.210.57|WHEN:20110223|USER:gkworld*ADMIN
SAFE|IP:70.160.156.180|WHEN:20110223|USER:designwraps*liz
SAFE|IP:70.165.116.22|WHEN:20110223|USER:securitystore*brandy
SAFE|IP:70.165.79.188|WHEN:20110223|USER:nygaardjewelers*ADMIN
SAFE|IP:70.166.34.153|WHEN:20110223|USER:spaparts*ron
SAFE|IP:70.167.77.33|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:70.168.203.56|WHEN:20110223|USER:ahlersgifts*ADMIN
SAFE|IP:70.169.108.161|WHEN:20110223|USER:panrack*alan
SAFE|IP:70.169.108.37|WHEN:20110223|USER:panrack*ADMIN
SAFE|IP:70.169.108.92|WHEN:20110223|USER:panrack*ADMIN
SAFE|IP:70.169.109.139|WHEN:20110223|USER:panrack*alan
SAFE|IP:70.169.109.242|WHEN:20110223|USER:panrack*dave
SAFE|IP:70.169.109.35|WHEN:20110223|USER:panrack*ADMIN
SAFE|IP:70.169.109.7|WHEN:20110223|USER:panrack*
SAFE|IP:70.169.169.43|WHEN:20110223|USER:deals2all*brian
SAFE|IP:70.171.224.209|WHEN:20110223|USER:dollstreet*ADMIN
SAFE|IP:70.181.135.23|WHEN:20110223|USER:domino*nick
SAFE|IP:70.181.244.207|WHEN:20110223|USER:redford*
SAFE|IP:70.181.68.67|WHEN:20110223|USER:sallyrdhd*ADMIN
SAFE|IP:70.181.72.172|WHEN:20110223|USER:fortewebproperties*ADMIN
SAFE|IP:70.185.208.139|WHEN:20110223|USER:user10331*ADMIN
SAFE|IP:70.190.230.211|WHEN:20110223|USER:pawstogo*heather
SAFE|IP:70.196.149.227|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:70.196.41.87|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:70.196.59.9|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:70.197.129.207|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:70.197.147.225|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:70.234.96.154|WHEN:20110223|USER:sweetwaterscavenger*martin
SAFE|IP:70.240.70.32|WHEN:20110223|USER:batterup*ADMIN
SAFE|IP:70.240.92.113|WHEN:20110223|USER:batterup*ADMIN
SAFE|IP:70.240.93.189|WHEN:20110223|USER:batterup*ADMIN
SAFE|IP:70.240.93.92|WHEN:20110223|USER:batterup*ADMIN
SAFE|IP:70.249.162.164|WHEN:20110223|USER:europottery*ADMIN
SAFE|IP:70.41.231.178|WHEN:20110223|USER:vital*ADMIN
SAFE|IP:70.44.16.141|WHEN:20110223|USER:gkworld*orders
SAFE|IP:70.59.216.12|WHEN:20110223|USER:colocustommetal*ADMIN
SAFE|IP:70.61.224.209|WHEN:20110223|USER:orangeonions*ADMIN
SAFE|IP:70.66.13.146|WHEN:20110223|USER:designwraps*ADMIN
SAFE|IP:70.66.21.173|WHEN:20110223|USER:designwraps*
SAFE|IP:71.108.165.119|WHEN:20110223|USER:savonbags*ADMIN
SAFE|IP:71.110.135.40|WHEN:20110223|USER:discountgunmart*willh
SAFE|IP:71.117.230.101|WHEN:20110223|USER:thechessstore*jean
SAFE|IP:71.118.207.53|WHEN:20110223|USER:myhotshoes*dchung
SAFE|IP:71.126.68.82|WHEN:20110223|USER:rittersgifts*martha
SAFE|IP:71.126.73.200|WHEN:20110223|USER:rittersgifts*martha
SAFE|IP:71.126.75.53|WHEN:20110223|USER:rittersgifts*martha
SAFE|IP:71.126.82.111|WHEN:20110223|USER:rittersgifts*martha
SAFE|IP:71.146.65.229|WHEN:20110223|USER:rhythmfusion*
SAFE|IP:71.146.89.64|WHEN:20110223|USER:rhythmfusion*
SAFE|IP:71.153.224.145|WHEN:20110223|USER:crite2000*ADMIN
SAFE|IP:71.163.191.198|WHEN:20110223|USER:luvmy3toys*ADMIN
SAFE|IP:71.164.136.162|WHEN:20110223|USER:aaavacs*rthomi
SAFE|IP:71.164.235.60|WHEN:20110223|USER:aaavacs*rthomi
SAFE|IP:71.165.92.84|WHEN:20110223|USER:depclar*ADMIN
SAFE|IP:71.167.192.54|WHEN:20110223|USER:creative*ADMIN
SAFE|IP:71.167.238.67|WHEN:20110223|USER:pure4you*ADMIN
SAFE|IP:71.170.200.70|WHEN:20110223|USER:gssstore*ADMIN
SAFE|IP:71.176.227.149|WHEN:20110223|USER:motorcowboy*ADMIN
SAFE|IP:71.177.156.111|WHEN:20110223|USER:depclar*ADMIN
SAFE|IP:71.182.158.108|WHEN:20110223|USER:cypherstyles*john
SAFE|IP:71.185.174.141|WHEN:20110223|USER:ssphoto*ADMIN
SAFE|IP:71.190.145.22|WHEN:20110223|USER:cannolig*ADMIN
SAFE|IP:71.190.170.27|WHEN:20110223|USER:yourdreamizhere*leah
SAFE|IP:71.190.205.58|WHEN:20110223|USER:nyciwear*owen
SAFE|IP:71.195.182.196|WHEN:20110223|USER:rcraven*russc
SAFE|IP:71.195.191.114|WHEN:20110223|USER:audiovideo*ADMIN
SAFE|IP:71.209.51.60|WHEN:20110223|USER:affordableproducts*ADMIN
SAFE|IP:71.210.225.217|WHEN:20110223|USER:paintspray*ADMIN
SAFE|IP:71.210.232.208|WHEN:20110223|USER:paintspray*keira
SAFE|IP:71.210.234.216|WHEN:20110223|USER:paintspray*ADMIN
SAFE|IP:71.210.234.252|WHEN:20110223|USER:paintspray*keira
SAFE|IP:71.210.239.200|WHEN:20110223|USER:paintspray*ADMIN
SAFE|IP:71.210.253.131|WHEN:20110223|USER:paintspray*ADMIN
SAFE|IP:71.212.35.91|WHEN:20110223|USER:atozgifts*sam
SAFE|IP:71.226.49.220|WHEN:20110223|USER:courtneybrooke*ADMIN
SAFE|IP:71.226.96.213|WHEN:20110223|USER:toynk*dave
SAFE|IP:71.229.220.56|WHEN:20110223|USER:gssstore*pat
SAFE|IP:71.229.238.208|WHEN:20110223|USER:savecentral*ADMIN
SAFE|IP:71.236.186.8|WHEN:20110223|USER:underthesun*ADMIN
SAFE|IP:71.237.42.36|WHEN:20110223|USER:rcm1*ADMIN
SAFE|IP:71.249.100.110|WHEN:20110223|USER:watchzilla*ADMIN
SAFE|IP:71.249.99.75|WHEN:20110223|USER:athruzcloseouts*
SAFE|IP:71.253.123.122|WHEN:20110223|USER:bierhaus*ADMIN
SAFE|IP:71.254.77.190|WHEN:20110223|USER:f2ptech*ADMIN
SAFE|IP:71.2.69.46|WHEN:20110223|USER:lasvegasfurniture*joe
SAFE|IP:71.29.136.134|WHEN:20110223|USER:dannyscollectables*ADMIN
SAFE|IP:71.30.43.179|WHEN:20110223|USER:dannyscollectables*ADMIN
SAFE|IP:71.31.114.103|WHEN:20110223|USER:dannyscollectables*ADMIN
SAFE|IP:71.35.64.194|WHEN:20110223|USER:allpetsolutions*ADMIN
SAFE|IP:71.35.66.138|WHEN:20110223|USER:allpetsolutions*ADMIN
SAFE|IP:71.42.6.40|WHEN:20110223|USER:thephoneexchange*ADMIN
SAFE|IP:71.43.209.154|WHEN:20110223|USER:urlichdecorations*ADMIN
SAFE|IP:71.46.49.251|WHEN:20110223|USER:sasydeals*ADMIN
SAFE|IP:71.51.136.12|WHEN:20110223|USER:agandb*eric
SAFE|IP:71.57.115.219|WHEN:20110223|USER:mpodesigns*mark
SAFE|IP:71.59.222.64|WHEN:20110223|USER:thechessstore*ADMIN
SAFE|IP:71.59.231.206|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:71.60.18.249|WHEN:20110223|USER:cypherstyles*john
SAFE|IP:71.75.225.163|WHEN:20110223|USER:nwsalesconnection*ADMIN
SAFE|IP:71.80.214.116|WHEN:20110223|USER:4golftraining*ADMIN
SAFE|IP:71.80.218.237|WHEN:20110223|USER:digmodern*peter
SAFE|IP:71.85.120.168|WHEN:20110223|USER:1stproweddingalbums*ADMIN
SAFE|IP:71.88.176.48|WHEN:20110223|USER:jewelriver*ADMIN
SAFE|IP:71.91.139.202|WHEN:20110223|USER:performancepda*ADMIN
SAFE|IP:71.93.219.54|WHEN:20110223|USER:topgearleathers*ADMIN
SAFE|IP:71.93.70.48|WHEN:20110223|USER:gamesgalore*ADMIN
SAFE|IP:71.98.217.101|WHEN:20110223|USER:suncoast*carrie
SAFE|IP:71.99.93.48|WHEN:20110223|USER:reefs2go*crystal
SAFE|IP:72.102.167.25|WHEN:20110223|USER:dinkysduds*ADMIN
SAFE|IP:72.102.18.242|WHEN:20110223|USER:dinkysduds*ADMIN
SAFE|IP:72.12.191.69|WHEN:20110223|USER:musclextreme*ADMIN
SAFE|IP:72.128.18.185|WHEN:20110223|USER:mandwsales*
SAFE|IP:72.135.20.35|WHEN:20110223|USER:europottery*ADMIN
SAFE|IP:72.145.141.230|WHEN:20110223|USER:lsdace30095*kuu
SAFE|IP:72.145.142.118|WHEN:20110223|USER:lsdace30095*kuu
SAFE|IP:72.145.152.129|WHEN:20110223|USER:lsdace30095*kuu
SAFE|IP:72.151.56.93|WHEN:20110223|USER:lamawellness*ADMIN
SAFE|IP:72.156.39.113|WHEN:20110223|USER:conceptvanity*ADMIN
SAFE|IP:72.160.128.140|WHEN:20110223|USER:krewkut*ADMIN
SAFE|IP:72.160.136.123|WHEN:20110223|USER:krewkut*ADMIN
SAFE|IP:72.160.137.141|WHEN:20110223|USER:krewkut*ADMIN
SAFE|IP:72.173.133.60|WHEN:20110223|USER:capg*ADMIN
SAFE|IP:72.178.154.98|WHEN:20110223|USER:mccantsenamels*ADMIN
SAFE|IP:72.183.115.43|WHEN:20110223|USER:centraltexasleather*mer
SAFE|IP:72.197.47.172|WHEN:20110223|USER:acmeventures*suzee2253
SAFE|IP:72.197.85.137|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:72.201.9.108|WHEN:20110223|USER:greatlookz*suruchi
SAFE|IP:72.202.137.215|WHEN:20110223|USER:tlstuff*ADMIN
SAFE|IP:72.214.200.137|WHEN:20110223|USER:designwraps*jan
SAFE|IP:72.214.9.55|WHEN:20110223|USER:alternativedvd*ADMIN
SAFE|IP:72.220.29.55|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:72.225.153.123|WHEN:20110223|USER:tting*bo_rsong
SAFE|IP:72.229.31.101|WHEN:20110223|USER:replaceyourcell*shemek
SAFE|IP:72.234.161.175|WHEN:20110223|USER:hotsauce*ADMIN
SAFE|IP:72.234.202.237|WHEN:20110223|USER:hotsauce*ADMIN
SAFE|IP:72.235.110.117|WHEN:20110223|USER:tikimaster*ava
SAFE|IP:72.23.52.110|WHEN:20110223|USER:ajh235*ADMIN
SAFE|IP:72.24.185.239|WHEN:20110223|USER:outdoorgearco*ADMIN
SAFE|IP:72.25.111.209|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:72.255.52.157|WHEN:20110223|USER:bbrothersc*ADMIN
SAFE|IP:72.40.73.79|WHEN:20110223|USER:todaysmusic*ADMIN
SAFE|IP:72.47.20.138|WHEN:20110223|USER:kidsafeinc*michael
SAFE|IP:72.54.30.118|WHEN:20110223|USER:toynk*rufus
SAFE|IP:72.60.98.195|WHEN:20110223|USER:yourdreamizhere*ADMIN
SAFE|IP:72.62.210.61|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:72.62.26.104|WHEN:20110223|USER:prostreet*
SAFE|IP:72.64.180.17|WHEN:20110223|USER:dolldreams*
SAFE|IP:72.67.235.5|WHEN:20110223|USER:wildcollections*may
SAFE|IP:72.67.86.24|WHEN:20110223|USER:usfreight*ADMIN
SAFE|IP:72.78.249.2|WHEN:20110223|USER:dwlz*ADMIN
SAFE|IP:72.82.183.191|WHEN:20110223|USER:mondaescollectibles*ADMIN
SAFE|IP:72.85.27.37|WHEN:20110223|USER:barefoottess*mike
SAFE|IP:72.87.193.145|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:72.87.193.6|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:72.89.161.74|WHEN:20110223|USER:pure4you*ADMIN
SAFE|IP:72.92.208.215|WHEN:20110223|USER:bierhaus*ADMIN
SAFE|IP:72.92.223.118|WHEN:20110223|USER:bierhaus*ADMIN
SAFE|IP:74.101.234.50|WHEN:20110223|USER:victorianshop*ADMIN
SAFE|IP:74.107.96.75|WHEN:20110223|USER:barefoottess*alison
SAFE|IP:74.111.168.242|WHEN:20110223|USER:cypherstyles*courtney
SAFE|IP:74.129.108.61|WHEN:20110223|USER:blitz*ADMIN
SAFE|IP:74.164.5.152|WHEN:20110223|USER:thecubanshop*ADMIN
SAFE|IP:74.165.123.252|WHEN:20110223|USER:888knivesrus*ADMIN
SAFE|IP:74.169.11.150|WHEN:20110223|USER:quemex*ADMIN
SAFE|IP:74.176.42.62|WHEN:20110223|USER:lsdace30095*kuu
SAFE|IP:74.181.35.4|WHEN:20110223|USER:rowdyfan*ADMIN
SAFE|IP:74.2.148.2|WHEN:20110223|USER:kbtdirect*kevin
SAFE|IP:74.231.18.162|WHEN:20110223|USER:barefoottess*katie
SAFE|IP:74.240.218.142|WHEN:20110223|USER:froggysfog*ADMIN
SAFE|IP:74.248.211.233|WHEN:20110223|USER:toolsolutions*ADMIN
SAFE|IP:74.40.29.14|WHEN:20110223|USER:dealz4real*solid
SAFE|IP:74.62.204.58|WHEN:20110223|USER:denimsquare*ADMIN
SAFE|IP:74.73.149.17|WHEN:20110223|USER:stateofnine*courtneyh
SAFE|IP:74.82.64.32|WHEN:20110223|USER:yourdreamizhere*ADMIN
SAFE|IP:74.82.64.35|WHEN:20110223|USER:yourdreamizhere*ADMIN
SAFE|IP:74.82.64.37|WHEN:20110223|USER:yourdreamizhere*ADMIN
SAFE|IP:74.82.68.16|WHEN:20110223|USER:thechessstore*ADMIN
SAFE|IP:74.82.68.17|WHEN:20110223|USER:2bhip*ADMIN
SAFE|IP:74.82.68.18|WHEN:20110223|USER:thechessstore*ADMIN
SAFE|IP:74.82.68.19|WHEN:20110223|USER:2bhip*ADMIN
SAFE|IP:74.82.68.20|WHEN:20110223|USER:2bhip*ADMIN
SAFE|IP:74.82.68.32|WHEN:20110223|USER:2bhip*ADMIN
SAFE|IP:74.82.68.33|WHEN:20110223|USER:2bhip*ADMIN
SAFE|IP:74.82.68.34|WHEN:20110223|USER:2bhip*ADMIN
SAFE|IP:74.82.68.35|WHEN:20110223|USER:2bhip*ADMIN
SAFE|IP:74.82.68.36|WHEN:20110223|USER:2bhip*ADMIN
SAFE|IP:74.82.68.37|WHEN:20110223|USER:2bhip*ADMIN
SAFE|IP:74.82.68.38|WHEN:20110223|USER:2bhip*ADMIN
SAFE|IP:74.83.65.238|WHEN:20110223|USER:candlemakers*ADMIN
SAFE|IP:74.87.18.82|WHEN:20110223|USER:acmeventures*suzee2253
SAFE|IP:74.88.50.243|WHEN:20110223|USER:tting*chirag
SAFE|IP:74.88.56.198|WHEN:20110223|USER:tting*chirag
SAFE|IP:74.89.48.244|WHEN:20110223|USER:uaamerica*ADMIN
SAFE|IP:74.92.43.133|WHEN:20110223|USER:stateofnine*ADMIN
SAFE|IP:75.0.18.30|WHEN:20110223|USER:rockthebabe*ADMIN
SAFE|IP:75.104.109.184|WHEN:20110223|USER:fairyfinery*
SAFE|IP:75.108.142.154|WHEN:20110223|USER:cardiacwellness*ADMIN
SAFE|IP:75.11.168.110|WHEN:20110223|USER:thesavewave*maggie
SAFE|IP:75.117.21.47|WHEN:20110223|USER:standsbyriver*ADMIN
SAFE|IP:75.118.12.48|WHEN:20110223|USER:polishkitchenonline*ADMIN
SAFE|IP:75.118.206.172|WHEN:20110223|USER:kidsafeinc*dennis
SAFE|IP:75.120.36.189|WHEN:20110223|USER:dutchsheets*
SAFE|IP:75.120.37.211|WHEN:20110223|USER:dutchsheets*ADMIN
SAFE|IP:75.121.3.109|WHEN:20110223|USER:elegantbed*jeff
SAFE|IP:75.128.199.77|WHEN:20110223|USER:erinsedge*ADMIN
SAFE|IP:75.131.193.222|WHEN:20110223|USER:lsdace30095*ADMIN
SAFE|IP:75.131.237.222|WHEN:20110223|USER:fcwstores*stephanie
SAFE|IP:75.138.245.65|WHEN:20110223|USER:froggysfog*ADMIN
SAFE|IP:75.139.128.117|WHEN:20110223|USER:lsdace30095*
SAFE|IP:75.139.128.185|WHEN:20110223|USER:lsdace30095*ADMIN
SAFE|IP:75.139.143.25|WHEN:20110223|USER:usavem*
SAFE|IP:75.139.144.4|WHEN:20110223|USER:lsdace30095*
SAFE|IP:75.139.145.28|WHEN:20110223|USER:lsdace30095*ADMIN
SAFE|IP:75.139.145.47|WHEN:20110223|USER:lsdace30095*ADMIN
SAFE|IP:75.139.145.84|WHEN:20110223|USER:lsdace30095*ADMIN
SAFE|IP:75.140.21.31|WHEN:20110223|USER:usfreight*ADMIN
SAFE|IP:75.142.249.195|WHEN:20110223|USER:rockthebabe*ADMIN
SAFE|IP:75.142.56.62|WHEN:20110223|USER:designed2bsweet*
SAFE|IP:75.143.246.56|WHEN:20110223|USER:ancientsun*ADMIN
SAFE|IP:75.146.171.230|WHEN:20110223|USER:sfplanet*alan
SAFE|IP:75.147.129.93|WHEN:20110223|USER:mariposahill*cecilia
SAFE|IP:75.149.101.62|WHEN:20110223|USER:smyrnacoin*
SAFE|IP:75.151.25.9|WHEN:20110223|USER:flymode*steve
SAFE|IP:75.15.235.172|WHEN:20110223|USER:leisure*ADMIN
SAFE|IP:75.16.41.13|WHEN:20110223|USER:luggage4less*steveeq1
SAFE|IP:75.169.205.74|WHEN:20110223|USER:climbingholds*brad
SAFE|IP:75.169.223.47|WHEN:20110223|USER:wildemats*marcy
SAFE|IP:75.174.195.67|WHEN:20110223|USER:greatlookz*anastasia
SAFE|IP:75.186.48.70|WHEN:20110223|USER:shopdownlite*ADMIN
SAFE|IP:75.187.146.90|WHEN:20110223|USER:bargaincds*ADMIN
SAFE|IP:75.19.37.142|WHEN:20110223|USER:yocaps*john
SAFE|IP:75.194.43.207|WHEN:20110223|USER:stateofnine*ADMIN
SAFE|IP:75.203.96.49|WHEN:20110223|USER:dealz4real*ADMIN
SAFE|IP:75.213.191.10|WHEN:20110223|USER:stateofnine*
SAFE|IP:75.213.246.103|WHEN:20110223|USER:stateofnine*ADMIN
SAFE|IP:75.218.72.119|WHEN:20110223|USER:kcint*cindy
SAFE|IP:75.224.69.38|WHEN:20110223|USER:dealz4real*ADMIN
SAFE|IP:75.225.248.223|WHEN:20110223|USER:user5667*ADMIN
SAFE|IP:75.226.67.175|WHEN:20110223|USER:stateofnine*ADMIN
SAFE|IP:75.23.227.54|WHEN:20110223|USER:riascrazydeals*ADMIN
SAFE|IP:75.24.110.252|WHEN:20110223|USER:expeditionimports*ADMIN
SAFE|IP:75.25.17.98|WHEN:20110223|USER:luggage4less*ADMIN
SAFE|IP:75.25.18.53|WHEN:20110223|USER:beltsandmore*parviz
SAFE|IP:75.28.128.97|WHEN:20110223|USER:ticohomedecor*ADMIN
SAFE|IP:75.32.105.14|WHEN:20110223|USER:topgearleathers*ADMIN
SAFE|IP:75.32.184.113|WHEN:20110223|USER:yocaps*john
SAFE|IP:75.33.201.139|WHEN:20110223|USER:thesavewave*maggie
SAFE|IP:75.33.204.23|WHEN:20110223|USER:ledinsider*lindy
SAFE|IP:75.33.217.30|WHEN:20110223|USER:panrack*dave
SAFE|IP:75.36.33.251|WHEN:20110223|USER:swells*ADMIN
SAFE|IP:75.37.138.161|WHEN:20110223|USER:gamesgalore*ADMIN
SAFE|IP:75.39.26.27|WHEN:20110223|USER:orangeonions*ADMIN
SAFE|IP:75.4.139.244|WHEN:20110223|USER:cubworld*ADMIN
SAFE|IP:75.42.176.86|WHEN:20110223|USER:smarterlight*david
SAFE|IP:75.49.20.40|WHEN:20110223|USER:justifieddefiance*ADMIN
SAFE|IP:75.51.85.116|WHEN:20110223|USER:raincustom*joe
SAFE|IP:75.51.86.159|WHEN:20110223|USER:raincustom*joe
SAFE|IP:75.60.231.23|WHEN:20110223|USER:justifieddefiance*ADMIN
SAFE|IP:75.67.233.241|WHEN:20110223|USER:sportstop*jamie
SAFE|IP:75.70.214.146|WHEN:20110223|USER:savecentral*ADMIN
SAFE|IP:75.72.252.246|WHEN:20110223|USER:bamtar*lisa
SAFE|IP:75.73.16.71|WHEN:20110223|USER:bamtar*ADMIN
SAFE|IP:75.73.185.246|WHEN:20110223|USER:flagsonastick*ADMIN
SAFE|IP:75.73.48.8|WHEN:20110223|USER:bamtar*ADMIN
SAFE|IP:75.79.173.165|WHEN:20110223|USER:ribbontrade*info
SAFE|IP:75.83.80.56|WHEN:20110223|USER:zephyrsports*tholley
SAFE|IP:75.83.82.198|WHEN:20110223|USER:zephyrsports*bob2
SAFE|IP:75.84.64.146|WHEN:20110223|USER:jeco*tim
SAFE|IP:75.84.67.94|WHEN:20110223|USER:jeco*ADMIN
SAFE|IP:75.85.182.106|WHEN:20110223|USER:877myjuicer*ADMIN
SAFE|IP:75.93.23.158|WHEN:20110223|USER:oakfurniture*
SAFE|IP:75.99.109.26|WHEN:20110223|USER:tting*jeremiahl
SAFE|IP:76.0.147.238|WHEN:20110223|USER:teramasu*storeph
SAFE|IP:76.0.194.34|WHEN:20110223|USER:lasvegasfurniture*scott
SAFE|IP:76.0.209.29|WHEN:20110223|USER:lasvegasfurniture*steve
SAFE|IP:76.103.233.231|WHEN:20110223|USER:kyledesign*master
SAFE|IP:76.109.21.9|WHEN:20110223|USER:theh2oguru*cliff
SAFE|IP:76.110.197.149|WHEN:20110223|USER:pure4you*ADMIN
SAFE|IP:76.111.214.231|WHEN:20110223|USER:craftersnet*ADMIN
SAFE|IP:76.112.218.19|WHEN:20110223|USER:flymode*steve
SAFE|IP:76.113.179.174|WHEN:20110223|USER:sfplanet*levi
SAFE|IP:76.114.91.204|WHEN:20110223|USER:totalfanshop*ADMIN
SAFE|IP:76.115.170.167|WHEN:20110223|USER:thechessstore*sierra
SAFE|IP:76.121.171.60|WHEN:20110223|USER:sommelier*ADMIN
SAFE|IP:76.122.43.145|WHEN:20110223|USER:4armedforces*ADMIN
SAFE|IP:76.16.225.49|WHEN:20110223|USER:toynk*s
SAFE|IP:76.166.173.5|WHEN:20110223|USER:usmemoryfoam*donok
SAFE|IP:76.170.152.99|WHEN:20110223|USER:incipiodirect*andy
SAFE|IP:76.173.174.157|WHEN:20110223|USER:beltiscool*lee
SAFE|IP:76.174.197.110|WHEN:20110223|USER:myhotshoes*dlam
SAFE|IP:76.176.137.243|WHEN:20110223|USER:closeoutdude*ADMIN
SAFE|IP:76.176.30.189|WHEN:20110223|USER:swells*ADMIN
SAFE|IP:76.181.74.188|WHEN:20110223|USER:polishkitchenonline*ADMIN
SAFE|IP:76.185.119.122|WHEN:20110223|USER:sticksman*ADMIN
SAFE|IP:76.189.123.123|WHEN:20110223|USER:dollhousesandmore*ADMIN
SAFE|IP:76.189.194.12|WHEN:20110223|USER:orangeonions*kasey
SAFE|IP:76.19.21.154|WHEN:20110223|USER:stateofnine*ADMIN
SAFE|IP:76.194.209.44|WHEN:20110223|USER:bluelightning*ADMIN
SAFE|IP:76.198.92.151|WHEN:20110223|USER:rockmusicjewelry*ADMIN
SAFE|IP:76.202.240.4|WHEN:20110223|USER:speedbleeder*ADMIN
SAFE|IP:76.209.187.142|WHEN:20110223|USER:sjpacific*ADMIN
SAFE|IP:76.211.230.195|WHEN:20110223|USER:4golftraining*ADMIN
SAFE|IP:76.212.212.174|WHEN:20110223|USER:hobbytoolsupply*ADMIN
SAFE|IP:76.213.230.234|WHEN:20110223|USER:no1collectibles*ADMIN
SAFE|IP:76.214.15.17|WHEN:20110223|USER:no1collectibles*ADMIN
SAFE|IP:76.214.17.44|WHEN:20110223|USER:beltsandmore*perry
SAFE|IP:76.214.19.229|WHEN:20110223|USER:beltsandmore*perry
SAFE|IP:76.214.4.86|WHEN:20110223|USER:beltsandmore*renata
SAFE|IP:76.216.173.17|WHEN:20110223|USER:photonracquets*ADMIN
SAFE|IP:76.21.62.49|WHEN:20110223|USER:kidsafeinc*michael
SAFE|IP:76.219.156.239|WHEN:20110223|USER:allansjewelry*ADMIN
SAFE|IP:76.229.124.57|WHEN:20110223|USER:ribbontrade*info
SAFE|IP:76.231.10.123|WHEN:20110223|USER:stealthcycling*ADMIN
SAFE|IP:76.23.128.47|WHEN:20110223|USER:gilco*ADMIN
SAFE|IP:76.235.31.196|WHEN:20110223|USER:satin*david
SAFE|IP:76.235.33.241|WHEN:20110223|USER:rapiddirection*ADMIN
SAFE|IP:76.237.179.199|WHEN:20110223|USER:q3artinc*
SAFE|IP:76.237.185.87|WHEN:20110223|USER:bulldog*
SAFE|IP:76.241.98.18|WHEN:20110223|USER:ramh*ADMIN
SAFE|IP:76.244.176.225|WHEN:20110223|USER:toolusa*vickie
SAFE|IP:76.26.169.179|WHEN:20110223|USER:theh2oguru*marissa
SAFE|IP:76.30.230.23|WHEN:20110223|USER:silverchicks*ADMIN
SAFE|IP:76.4.238.147|WHEN:20110223|USER:cellphoneslord*carol
SAFE|IP:76.7.40.18|WHEN:20110223|USER:softenerparts*kate
SAFE|IP:76.88.59.72|WHEN:20110223|USER:webstrings*ADMIN
SAFE|IP:76.89.248.222|WHEN:20110223|USER:sjpacific*mark
SAFE|IP:76.91.118.3|WHEN:20110223|USER:riascrazydeals*medshane
SAFE|IP:76.91.123.172|WHEN:20110223|USER:depclar*ADMIN
SAFE|IP:76.95.146.98|WHEN:20110223|USER:laartwork*nita
SAFE|IP:76.99.145.91|WHEN:20110223|USER:temdee*ADMIN
SAFE|IP:79.177.184.174|WHEN:20110223|USER:onequickcup*jason
SAFE|IP:79.179.185.72|WHEN:20110223|USER:onequickcup*jason
SAFE|IP:79.182.184.149|WHEN:20110223|USER:onequickcup*jason
SAFE|IP:82.43.91.169|WHEN:20110223|USER:pulsartech*ADMIN
SAFE|IP:94.249.32.188|WHEN:20110223|USER:mulishagear*fat
SAFE|IP:95.143.213.114|WHEN:20110223|USER:rubdol*ADMIN
SAFE|IP:96.235.145.233|WHEN:20110223|USER:camdenbar*ADMIN
SAFE|IP:96.235.149.81|WHEN:20110223|USER:mondaescollectibles*ADMIN
SAFE|IP:96.238.86.38|WHEN:20110223|USER:onlineformals*ADMIN
SAFE|IP:96.241.49.238|WHEN:20110223|USER:tcanyon*ADMIN
SAFE|IP:96.242.154.2|WHEN:20110223|USER:sassyassybjeans*ron
SAFE|IP:96.244.7.20|WHEN:20110223|USER:barefoottess*mike
SAFE|IP:96.247.93.149|WHEN:20110223|USER:marcel*ADMIN
SAFE|IP:96.250.30.143|WHEN:20110223|USER:fairdeals*ADMIN
SAFE|IP:96.251.173.101|WHEN:20110223|USER:precisiondata*aurora
SAFE|IP:96.254.200.37|WHEN:20110223|USER:softenerparts*ADMIN
SAFE|IP:96.254.60.212|WHEN:20110223|USER:dealz4real*
SAFE|IP:96.254.97.160|WHEN:20110223|USER:softenerparts*kate
SAFE|IP:96.32.143.40|WHEN:20110223|USER:user10330*ADMIN
SAFE|IP:96.32.95.208|WHEN:20110223|USER:usavem*michael
SAFE|IP:96.42.30.238|WHEN:20110223|USER:classicaromas*ADMIN
SAFE|IP:96.53.80.162|WHEN:20110223|USER:pricematters*jsaris
SAFE|IP:96.57.187.242|WHEN:20110223|USER:tting*ADMIN
SAFE|IP:96.57.27.178|WHEN:20110223|USER:watchzilla*ADMIN
SAFE|IP:96.57.27.179|WHEN:20110223|USER:watchzilla*ADMIN
SAFE|IP:96.57.61.186|WHEN:20110223|USER:perfumecenteronline*ADMIN
SAFE|IP:97.102.139.229|WHEN:20110223|USER:thephoneexchange*ADMIN
SAFE|IP:97.113.60.111|WHEN:20110223|USER:jean13anne13*ADMIN
SAFE|IP:97.113.60.209|WHEN:20110223|USER:jean13anne13*ADMIN
SAFE|IP:97.115.196.227|WHEN:20110223|USER:purewave*buyit
SAFE|IP:97.134.69.90|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:97.140.239.44|WHEN:20110223|USER:highpointscientific*ADMIN
SAFE|IP:97.160.36.143|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:97.161.21.173|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:97.191.8.135|WHEN:20110223|USER:froggysfog*ADMIN
SAFE|IP:97.235.117.227|WHEN:20110223|USER:froggysfog*ADMIN
SAFE|IP:97.33.99.194|WHEN:20110223|USER:highpointscientific*ADMIN
SAFE|IP:97.51.66.152|WHEN:20110223|USER:columbiasports*ADMIN
SAFE|IP:97.67.23.254|WHEN:20110223|USER:pastgentoys*bbcw
SAFE|IP:97.75.179.150|WHEN:20110223|USER:furnitureonline*ryan
SAFE|IP:97.78.166.105|WHEN:20110223|USER:ebestsourc*ADMIN
SAFE|IP:97.78.209.66|WHEN:20110223|USER:dianayvonne*ADMIN
SAFE|IP:97.78.89.238|WHEN:20110223|USER:dianayvonne*
SAFE|IP:97.79.115.51|WHEN:20110223|USER:urlichdecorations*ADMIN
SAFE|IP:97.82.215.60|WHEN:20110223|USER:usmemoryfoam*ADMIN
SAFE|IP:97.87.15.18|WHEN:20110223|USER:gssstore*amy
SAFE|IP:97.93.72.69|WHEN:20110223|USER:speedy*grayson
SAFE|IP:97.94.119.67|WHEN:20110223|USER:speedaddictcycles*ADMIN
SAFE|IP:97.97.215.124|WHEN:20110223|USER:raku*ADMIN
SAFE|IP:98.101.149.81|WHEN:20110223|USER:gunnersalley*ed
SAFE|IP:98.110.19.127|WHEN:20110223|USER:ornamentsafe*ADMIN
SAFE|IP:98.110.245.115|WHEN:20110223|USER:winsports*ADMIN
SAFE|IP:98.140.196.210|WHEN:20110223|USER:gogoods*ADMIN
SAFE|IP:98.148.25.58|WHEN:20110223|USER:misternostalgia*ADMIN
SAFE|IP:98.148.71.169|WHEN:20110223|USER:denimsquare*ADMIN
SAFE|IP:98.164.234.236|WHEN:20110223|USER:jbossinger*ADMIN
SAFE|IP:98.168.250.143|WHEN:20110223|USER:toynk*rufus
SAFE|IP:98.169.180.156|WHEN:20110223|USER:pastgentoys*ADMIN
SAFE|IP:98.17.174.52|WHEN:20110223|USER:dannyscollectables*ADMIN
SAFE|IP:98.175.27.37|WHEN:20110223|USER:pastgentoys*matt
SAFE|IP:98.189.136.31|WHEN:20110223|USER:goshotcamera*ADMIN
SAFE|IP:98.189.232.227|WHEN:20110223|USER:incipiodirect*cs2
SAFE|IP:98.201.169.32|WHEN:20110223|USER:batterup*ADMIN
SAFE|IP:98.206.238.161|WHEN:20110223|USER:cdphonehome*ADMIN
SAFE|IP:98.208.228.177|WHEN:20110223|USER:candlemakers*2
SAFE|IP:98.220.232.65|WHEN:20110223|USER:crunruh*ADMIN
SAFE|IP:98.220.236.140|WHEN:20110223|USER:barefoottess*philip
SAFE|IP:98.222.116.39|WHEN:20110223|USER:allansjewelry*ADMIN
SAFE|IP:98.227.118.134|WHEN:20110223|USER:cdphonehome*ADMIN
SAFE|IP:98.230.223.47|WHEN:20110223|USER:caboots*mmm
SAFE|IP:98.238.43.216|WHEN:20110223|USER:thegiftchoice*ADMIN
SAFE|IP:98.249.204.129|WHEN:20110223|USER:conceptvanity*ADMIN
SAFE|IP:98.251.110.145|WHEN:20110223|USER:usavem*michael
SAFE|IP:98.27.52.139|WHEN:20110223|USER:gunnersalley*bill
SAFE|IP:98.28.19.46|WHEN:20110223|USER:polishkitchenonline*ADMIN
SAFE|IP:98.28.230.123|WHEN:20110223|USER:kcint*brock
SAFE|IP:98.65.214.49|WHEN:20110223|USER:toolsolutions*ADMIN
SAFE|IP:98.70.149.239|WHEN:20110223|USER:logcop55*ADMIN
SAFE|IP:98.71.216.175|WHEN:20110223|USER:4armedforces*xellenc
SAFE|IP:98.77.239.189|WHEN:20110223|USER:itronixinc*ADMIN
SAFE|IP:98.82.242.210|WHEN:20110223|USER:beachmart*vin
SAFE|IP:98.86.1.162|WHEN:20110223|USER:toolsolutions*ADMIN
SAFE|IP:98.86.33.84|WHEN:20110223|USER:toolsolutions*ADMIN
SAFE|IP:98.88.80.203|WHEN:20110223|USER:lsdace30095*kuu
SAFE|IP:98.88.83.250|WHEN:20110223|USER:lsdace30095*kuu
SAFE|IP:98.93.11.6|WHEN:20110223|USER:westkycustoms*tyler
SAFE|IP:98.93.154.144|WHEN:20110223|USER:westkycustoms*tyler
SAFE|IP:98.93.36.128|WHEN:20110223|USER:westkycustoms*corey
SAFE|IP:99.101.25.52|WHEN:20110223|USER:orangeonions*ADMIN
SAFE|IP:99.109.109.103|WHEN:20110223|USER:mckeeflyfishing*ADMIN
SAFE|IP:99.113.24.39|WHEN:20110223|USER:cubworld*sean
SAFE|IP:99.116.153.230|WHEN:20110223|USER:fcwstores*stephanie
SAFE|IP:99.1.221.210|WHEN:20110223|USER:perennial*ADMIN
SAFE|IP:99.122.251.93|WHEN:20110223|USER:orangeonions*heather
SAFE|IP:99.127.123.139|WHEN:20110223|USER:digmodern*eddie
SAFE|IP:99.127.75.89|WHEN:20110223|USER:crite2000*ADMIN
SAFE|IP:99.136.226.203|WHEN:20110223|USER:maureenscreations*ADMIN
SAFE|IP:99.137.85.90|WHEN:20110223|USER:firefoxtechnologies*ADMIN
SAFE|IP:99.169.9.194|WHEN:20110223|USER:redford*ADMIN
SAFE|IP:99.174.164.179|WHEN:20110223|USER:justifieddefiance*ADMIN
SAFE|IP:99.195.184.19|WHEN:20110223|USER:dutchsheets*ADMIN
SAFE|IP:99.203.117.38|WHEN:20110223|USER:terracotta*
SAFE|IP:99.203.69.147|WHEN:20110223|USER:prostreet*ADMIN
SAFE|IP:99.204.210.152|WHEN:20110223|USER:pnt*ADMIN
SAFE|IP:99.204.23.170|WHEN:20110223|USER:spaparts*ron
SAFE|IP:99.204.35.160|WHEN:20110223|USER:stage3motorsports*ADMIN
SAFE|IP:99.20.88.179|WHEN:20110223|USER:studiohut*
SAFE|IP:99.240.243.24|WHEN:20110223|USER:rpmcycle*ADMIN
SAFE|IP:99.29.154.249|WHEN:20110223|USER:dollhousesandmore*gila
SAFE|IP:99.33.223.76|WHEN:20110223|USER:caboots*irwin
SAFE|IP:99.38.106.184|WHEN:20110223|USER:grncruiser*ADMIN
SAFE|IP:99.38.92.146|WHEN:20110223|USER:briggs0419*ADMIN
SAFE|IP:99.41.208.91|WHEN:20110223|USER:caboots*joey
SAFE|IP:99.57.160.30|WHEN:20110223|USER:flymode*bart
SAFE|IP:99.59.148.166|WHEN:20110223|USER:amphidex*steve
SAFE|IP:99.61.11.117|WHEN:20110223|USER:dollssoreal*
SAFE|IP:99.61.192.7|WHEN:20110223|USER:dollhousesandmore*
SAFE|IP:99.70.227.110|WHEN:20110223|USER:spangirl*ADMIN
SAFE|IP:99.71.165.62|WHEN:20110223|USER:bloomindesigns*
SAFE|IP:99.71.67.39|WHEN:20110223|USER:barefoottess*katie
SAFE|IP:99.88.241.127|WHEN:20110223|USER:beautystore*ADMIN
SAFE|IP:99.90.144.86|WHEN:20110223|USER:designed2bsweet*ADMIN
SAFE|IP:99.93.200.99|WHEN:20110223|USER:gilco*ADMIN
SAFE|IP:99.9.59.26|WHEN:20110223|USER:musclextreme*ADMIN
SAFE|IP:99.99.172.183|WHEN:20110223|USER:courtneybrooke*ADMIN
WATCH|IP:220.181.125.146|WHEN:20110304|SERVER:www.greatscarvez.com|REASON:robots.txt
WATCH|IP:66.249.67.165|WHEN:20110304|SERVER:www.barstoolselect.com|REASON:robots.txt
WATCH|IP:190.43.128.243|WHEN:20110304|SERVER:www.marcelhomedecor.com|REASON:robots.txt
WATCH|IP:220.181.93.6|WHEN:20110304|SERVER:www.indianselections.com|REASON:robots.txt
WATCH|IP:201.240.49.248|WHEN:20110304|SERVER:www.schoolfurniture-online.com|REASON:robots.txt
WATCH|IP:201.240.49.248|WHEN:20110304|SERVER:www.ibuyhomefurniture.com|REASON:robots.txt
WATCH|IP:220.181.125.145|WHEN:20110304|SERVER:www.foodequipmentnw.com|REASON:robots.txt
WATCH|IP:220.181.93.8|WHEN:20110304|SERVER:www.oldcookbooks.com|REASON:robots.txt
WATCH|IP:209.151.140.123|WHEN:20110304|SERVER:www.ibuysolarpanels.com|REASON:robots.txt
WATCH|IP:61.135.184.211|WHEN:20110304|SERVER:www.bonnies-treasures.com|REASON:robots.txt
WATCH|IP:61.135.184.211|WHEN:20110304|SERVER:www.prostreetlighting.com|REASON:robots.txt
WATCH|IP:61.135.184.211|WHEN:20110304|SERVER:www.modernmini.com|REASON:robots.txt
WATCH|IP:61.135.184.211|WHEN:20110304|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:66.249.68.214|WHEN:20110304|SERVER:www.barstoolselect.com|REASON:robots.txt
WATCH|IP:220.181.93.2|WHEN:20110304|SERVER:www.stopdirt.com|REASON:robots.txt
WATCH|IP:220.181.125.148|WHEN:20110304|SERVER:www.steveshumor.com|REASON:robots.txt
WATCH|IP:220.181.125.149|WHEN:20110304|SERVER:www.leedway.com|REASON:robots.txt
WATCH|IP:220.181.125.149|WHEN:20110304|SERVER:www.santaferanch.com|REASON:robots.txt
WATCH|IP:220.181.125.149|WHEN:20110304|SERVER:www.rancholocoboots.com|REASON:robots.txt
WATCH|IP:220.181.93.8|WHEN:20110304|SERVER:www.caliperpaints.com|REASON:robots.txt
WATCH|IP:61.135.184.211|WHEN:20110304|SERVER:www.onlineformals.com|REASON:robots.txt
WATCH|IP:61.135.184.211|WHEN:20110304|SERVER:www.eaglelight.com|REASON:robots.txt
WATCH|IP:220.181.93.9|WHEN:20110304|SERVER:www.beauty-mart.com|REASON:robots.txt
WATCH|IP:220.181.93.9|WHEN:20110304|SERVER:www.arcolamp.com|REASON:robots.txt
WATCH|IP:220.181.125.178|WHEN:20110304|SERVER:www.flymode.com|REASON:robots.txt
WATCH|IP:220.181.93.3|WHEN:20110304|SERVER:qualityprice.com|REASON:robots.txt
WATCH|IP:220.181.125.178|WHEN:20110304|SERVER:www.gandwcollectibles.com|REASON:robots.txt
WATCH|IP:220.181.125.162|WHEN:20110304|SERVER:www.futonbedplanet.com|REASON:robots.txt
WATCH|IP:220.181.125.162|WHEN:20110304|SERVER:www.acworldtoys.com|REASON:robots.txt
WATCH|IP:220.181.93.2|WHEN:20110304|SERVER:www.cfisd.biz|REASON:robots.txt
WATCH|IP:220.181.93.6|WHEN:20110304|SERVER:allpetsolutions.com|REASON:robots.txt
WATCH|IP:69.28.58.43|WHEN:20110304|SERVER:pitstool.zoovy.com|REASON:robots.txt
WATCH|IP:69.28.58.43|WHEN:20110304|SERVER:www.fotoadapter.com|REASON:robots.txt
WATCH|IP:220.181.93.1|WHEN:20110304|SERVER:www.buildbikes.net|REASON:robots.txt
WATCH|IP:220.181.125.147|WHEN:20110304|SERVER:www.greatparasolz.com|REASON:robots.txt
WATCH|IP:72.14.164.168|WHEN:20110304|SERVER:www.toynk.com|REASON:robots.txt
KILL|IP:121.14.96.153|WHEN:20110317|REASON:spambot (no robots.txt)
KILL|IP:58.60.14.*|WHEN:20110317|REASON:spambot (no robots.txt)
KILL|IP:58.61.32.55|WHEN:20110317|REASON:spambot (no robots.txt)
KILL|IP:124.115.0.180|WHEN:20110317|REASON:spambot (no robots.txt)
