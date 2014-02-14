#!/usr/bin/perl

use lib "/httpd/modules";
use SITE;
use SITE::Vstore;

if (not defined $MEMD) { $MEMD = &SITE::Vstore::getGlobalMemCache(); }
if (defined $MEMD) {
	my ($LOOKUP) = $MEMD->get( "IP:$IP" );
	print "MEMCACHE: $LOOKUP\n";	
	}


my ($result) = SITE::whatis($ARGV[0]);
print "STATIC/BANNED: $result\n";

