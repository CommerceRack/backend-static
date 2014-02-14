#!/usr/bin/perl -w
use strict;
use warnings;

#use FindBin;
#use lib "$FindBin::Bin/../cgi-bin/lib";
use lib '/httpd/modules';
use ebayConfig;

my ($db, $user, $pass, $file);
$file = $ARGV[0] || 'fulldump.sql.gz';
$db = [split ':', [split ';', $CONNECT_INFO->[0]]->[0]]->[2];
$user = $CONNECT_INFO->[1];
$pass = $CONNECT_INFO->[2];

if(-e $file) {
  ($file =~ /\.gz$/) ? `gunzip -c $file | mysql -u $user --password=$pass $db` : `mysql -u $user --password=$pass $db < $file`;
} else {
  print "File $file not found...\n";
}
