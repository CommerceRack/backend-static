#!/usr/bin/perl

use lib "/httpd/modules";
use TOXML;
use Data::Dumper;
use INI;
use ZTOOLKIT;
use Storable;


my %f = ();
$f{'<!-- CONTENT_TEXT_COLOR -->'} = '%CONTENT_TEXT_COLOR%';
$f{'<!--CONTENT_TEXT_COLOR-->'} = '%CONTENT_TEXT_COLOR%';
$f{'<!-- LINK_TEXT_COLOR -->'} = '%LINK_TEXT_COLOR%';
$f{'<!-- LINK_ACTIVE_TEXT_COLOR -->'} = '%LINK_ACTIVE_TEXT_COLOR%';
$f{'<!-- LINK_VISITED_TEXT_COLOR -->'} = '%LINK_VISITED_TEXT_COLOR%';
$f{'<!--LINK_TEXT_COLOR-->'} = '%LINK_TEXT_COLOR%';
$f{'<!--LINK_ACTIVE_TEXT_COLOR-->'} = '%LINK_ACTIVE_TEXT_COLOR%';
$f{'<!--LINK_VISITED_TEXT_COLOR-->'} = '%LINK_VISITED_TEXT_COLOR%';
$f{'<!--LINK_VISITED_TEXT_COLOR -->'} = '%LINK_VISITED_TEXT_COLOR%';
$f{'<!--CONTENT_BACKGROUND_COLOR-->'} = '%CONTENT_BACKGROUND_COLOR%';
$f{'<!--ALERT_COLOR-->'} = '%ALERT_COLOR%';
$f{'<!--WRAPPER_FILE-->'} = '%WRAPPER_FILE%';

opendir $D, ".";
while ( $path = readdir($D) ) {
	next if (substr($path,0,1) eq '.');
	next if (! -d $path);	

	next if (! -f "/httpd/site/wrappers/$path/main.xml");
	my $DOCID = $path;

	my $changed = 0;
	my ($t) = TOXML->new('WRAPPER',$path);
	my ($configel) = $t->findElements('CONFIG');


	if ($configel->{'THEME'} !~ /\&/) {
		if ($configel->{'THEME'} eq '') { $configel->{'THEME'} = 'default'; }

		if (! -f "/httpd/static/themes/$configel->{'THEME'}.ini") { $configel->{'THEME'} = 'default'; }
		my $REF = &INI::read_ini("/httpd/static/themes/$configel->{'THEME'}.ini",'',1,0,0,0,0);

		$configel->{'THEME'} = &ZTOOLKIT::buildparams($REF);
		$changed++;
		}

	foreach my $el (@{$t->elements()}) {
		next unless ($el->{'TYPE'} eq 'OUTPUT');
		
		foreach my $k (keys %f) {
			if ($el->{'HTML'} =~ /$k/) {
				print "F: $path / $k\n";
				$el->{'HTML'} =~ s/$k/$f{$k}/sg;
				$changed++;
				}
			}
##		if ($el->{'HTML'} =~ /<script/i) {}
##		elsif ($el->{'HTML'} =~ /<!--/) { print Dumper($path,$el);	}
		}

##	if ($changed) { print "changed: $path\n"; }
	if ($changed) {
		$E = $t->elements();
                            unshift @{$E}, {
                             'ID' => 'CQLVLCD',
                             'SUB' => 'LINK_VISITED_TEXT_COLOR',
                             'LOAD' => 'THEME::LINK_VISITED_TEXT_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCE',
                             'SUB' => 'TABLE_HEADING_FONT_SIZE',
                             'LOAD' => 'THEME::TABLE_HEADING_FONT_SIZE',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCF',
                             'SUB' => 'DISCLAIMER_FONT_SIZE',
                             'LOAD' => 'THEME::DISCLAIMER_FONT_SIZE',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCG',
                             'SUB' => 'CONTENT_BACKGROUND_COLOR',
                             'LOAD' => 'THEME::CONTENT_BACKGROUND_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCH',
                             'SUB' => 'TABLE_LISTING_BACKGROUND_COLOR',
                             'LOAD' => 'THEME::TABLE_LISTING_BACKGROUND_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCI',
                             'SUB' => 'CONTENT_TEXT_COLOR',
                             'LOAD' => 'THEME::CONTENT_TEXT_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCJ',
                             'SUB' => 'TABLE_LISTING_FONT_SIZE',
                             'LOAD' => 'THEME::TABLE_LISTING_FONT_SIZE',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCK',
                             'SUB' => 'TABLE_LISTING_TEXT_COLOR',
                             'LOAD' => 'THEME::TABLE_LISTING_TEXT_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCL',
                             'SUB' => 'TABLE_LISTING_FONT_FACE',
                             'LOAD' => 'THEME::TABLE_LISTING_FONT_FACE',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCM',
                             'SUB' => 'CONTENT_FONT_FACE',
                             'LOAD' => 'THEME::CONTENT_FONT_FACE',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCN',
                             'SUB' => 'NAME',
                             'LOAD' => 'THEME::NAME',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCO',
                             'SUB' => 'DISCLAIMER_FONT_FACE',
                             'LOAD' => 'THEME::DISCLAIMER_FONT_FACE',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCP',
                             'SUB' => 'PRETTY_NAME',
                             'LOAD' => 'THEME::PRETTY_NAME',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCQ',
                             'SUB' => 'TABLE_HEADING_BACKGROUND_COLOR',
                             'LOAD' => 'THEME::TABLE_HEADING_BACKGROUND_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCR',
                             'SUB' => 'TABLE_LISTING_BACKGROUND_COLOR_ALTERNATE',
                             'LOAD' => 'THEME::TABLE_LISTING_BACKGROUND_COLOR_ALTERNATE',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCS',
                             'SUB' => 'LINK_ACTIVE_TEXT_COLOR',
                             'LOAD' => 'THEME::LINK_ACTIVE_TEXT_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCT',
                             'SUB' => 'CONTENT_FONT_SIZE',
                             'LOAD' => 'THEME::CONTENT_FONT_SIZE',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCU',
                             'SUB' => 'ALERT_COLOR',
                             'LOAD' => 'THEME::ALERT_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCV',
                             'SUB' => 'DISCLAIMER_BACKGROUND_COLOR',
                             'LOAD' => 'THEME::DISCLAIMER_BACKGROUND_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCW',
                             'SUB' => 'TABLE_HEADING_FONT_FACE',
                             'LOAD' => 'THEME::TABLE_HEADING_FONT_FACE',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCX',
                             'SUB' => 'TABLE_HEADING_TEXT_COLOR',
                             'LOAD' => 'THEME::TABLE_HEADING_TEXT_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCY',
                             'SUB' => 'DISCLAIMER_TEXT_COLOR',
                             'LOAD' => 'THEME::DISCLAIMER_TEXT_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
                            unshift @{$E}, {
                             'ID' => 'CQLVLCZ',
                             'SUB' => 'LINK_TEXT_COLOR',
                             'LOAD' => 'THEME::LINK_TEXT_COLOR',
                             'TYPE' => 'READONLY',
                             'RAW' => 1
                           };
		$changed++;
		}
	
	if ($changed) {			
		print "DOCID: $DOCID\n";
		open F, ">$DOCID/main.xml";
		print F $t->as_xml();
		close F;

		store $t, "$DOCID/main.bin";
		}

	}
closedir $D;