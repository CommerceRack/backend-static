#!/usr/bin/perl -w
use strict;
use warnings;

#use FindBin;
#use lib "$FindBin::Bin/../cgi-bin/lib";
use lib '/httpd/modules';
use ebayConfig;

my ($db, $user, $pass);

$db = [split ':', [split ';', $CONNECT_INFO->[0]]->[0]]->[2];
$user = $CONNECT_INFO->[1];
$pass = $CONNECT_INFO->[2];

## save 5 versions of dump - rotate.
`touch fulldump.sql.gz fulldump1.sql.gz fulldump2.sql.gz fulldump3.sql.gz` if !-e 'fulldump4.sql.gz';
`mv fulldump3.sql.gz fulldump4.sql.gz`;
`mv fulldump2.sql.gz fulldump3.sql.gz`;
`mv fulldump1.sql.gz fulldump2.sql.gz`;
`mv fulldump.sql.gz fulldump1.sql.gz`;

## only schema, without data
#`mysqldump -u $user --password=$pass -n --add-drop-table -d $db ebay_categories ebay_category_custom_specifics ebay_category_2_cs ebay_attribute_sets ebay_category_2_product_finder ebay_product_finders ebay_attribute_set_2_attribute ebay_attributes | gzip -9 > dump.sql.gz`;

## full dump - only our 8 tables.
`mysqldump -u $user --password=$pass -n --add-drop-table $db ebay_categories ebay_category_custom_specifics ebay_category_2_cs ebay_attribute_sets ebay_category_2_product_finder ebay_product_finders ebay_attribute_set_2_attribute ebay_attributes | gzip -9 > fulldump.sql.gz`;
