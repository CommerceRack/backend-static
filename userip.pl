#!/usr/bin/perl

use lib "/httpd/modules";
use SITE;


my %IP = ();
open F, "<userip.log";
while (<F>) {
	# flagsonastick*ADMIN - 75.73.185.246 - /biz/manage/customer/index.cgi
	my ($user,$ip) = split(/ - /,$_);
	next if (defined $IP{$ip});
	$IP{$ip}++;

	if (my $type = SITE::whatis($ip)) {
		if ($type eq 'BOT') {
#			print "REMOVE: $ip $user\n";
			}
		}
	print "SAFE|IP:$ip|WHEN:20110223|USER:$user\n";
	}
close F;