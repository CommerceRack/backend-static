#!/usr/bin/perl

use lib "/httpd/modules";
use TOXML;
use TOXML::UTIL;
use Data::Dumper;
use XMLTOOLS;

use XML::Parser;
use XML::Parser::EasyTree;

        $XML::Parser::Easytree::Noempty=1;
         my $p=new XML::Parser(Style=>'EasyTree');
         my $tree=$p->parsefile('flows.xml');

$tree = $tree->[0]->{'content'};
foreach my $node (@{$tree}) {
	next if ($node->{'type'} ne 'e');
	my $ref = XMLTOOLS::XMLcollapse($node->{'content'});
	print Dumper($ref,$node);
	my $ID = $node->{'attrib'}->{'ID'};

	($t) = TOXML->new('LAYOUT',$ID);
	next if (not defined $t);

	($config) = $t->findElements('CONFIG');
	print Dumper($config);

	exit;
	}

