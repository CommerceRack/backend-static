#!/usr/bin/perl -w
use strict;
use DBI;
use lib "/httpd/modules";
use ebayConfig;

my $edbh = DBI->connect($CONNECT_INFO->[0], $CONNECT_INFO->[1], $CONNECT_INFO->[2], $CONNECT_INFO->[3]);

open FILE, "<database02.sql";

my $sql;

while (my $line = <FILE>) {
    unless ($line =~ /^--/) {
        unless ($line =~/^ENGINE/) {
            #unless ($line =~/^DROP/) {
                chomp $line;
                $sql .= $line." ";
                if ($line =~ /;/) {
                    eval { $edbh->do($sql) };
                    print "$sql\nSQL failed: $@\n" if $@;
                    #print "$sql\n";
                    $sql="";
                }
            #}
        }
    }
}
