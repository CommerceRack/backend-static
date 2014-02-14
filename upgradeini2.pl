#!/usr/bin/perl

use strict;
use lib "/httpd/modules";
use TOXML;
use TOXML::UTIL;
use TOXML::CSS;
use Data::Dumper;
use ZTOOLKIT;

my $USERNAME = '';
my $FORMAT = 'EMAIL';

my @USERS = ();
push @USERS, '';

my $dbh = &DBINFO::db_zoovy_connect();
my $pstmt = "select USERNAME from ZUSERS where CACHED_FLAGS like '%BASIC%' order by MID";
my $sth = $dbh->prepare($pstmt);
$sth->execute();
while ( my ($USERNAME) = $sth->fetchrow() ) {
	push @USERS, $USERNAME;
	}
$sth->finish();
&DBINFO::db_zoovy_close();


@USERS = ('');
foreach my $USERNAME (@USERS) {
	upgradeUser($USERNAME,'WRAPPER');
	}


sub upgradeUser {
	my ($USERNAME,$FORMAT) = @_;

	print "USERNAME: $USERNAME\n";
	
	my @ar = ();
	my $ref = &TOXML::UTIL::listDocs($USERNAME,$FORMAT);
	foreach my $x (@{$ref}) {
		next if (($x->{'MID'}==0) && ($USERNAME ne ''));
		push @ar, $x->{'DOCID'};
		}


	foreach my $file (@ar) {


#		next if ($file eq 'default');
#		next if ($file eq 'wrapper_error');
#		next unless ($file eq 'patriotic3');
#		next unless ($file eq 'patriotic2');
#		next if ($file eq 'techy');
#		next if ($file eq 'pinkfade');
#		next if ($file eq 'soap');
#		next if ($file eq 'roguedual');
#		next if ($file eq 'bluedual');
#		next if ($file eq 'sundual');
#		next if ($file eq 'theory');
#		next if ($file eq 'bergs2');
#		next if ($file eq 'bergs');
#		next if ($file eq 'baggy');
#		next if ($file eq 'search_results');
		#next if (($USERNAME eq '') && ($docref->{'MID'}>0));
		#next if (($USERNAME ne '') && ($docref->{'MID'}==0));

		# next if ($docref->{'DOCID'} ne 'evolution');
		print "DOC: $FORMAT,$file\n";
		
		my ($t) = TOXML->new($FORMAT,$file,USERNAME=>$USERNAME);
		my ($configel) = $t->findElements('CONFIG');
		if (not defined $configel) {
			die();
#			$configel = { ID=>'CONFIG', TYPE=>'CONFIG',  };
#			unshift @{$t->{'_ELEMENTS'}}, $configel;

#			$configel->{'TITLE'} = $file;
#			$configel->{'SITEBUTTONS'} = 'default=default|gif|0|0&add_to_cart=default|gif|108|28&back=default|gif|80|28&cancel=default|gif|64|28&checkout=default|gif|84|28&continue_shopping=default|gif|164|28&empty_cart=default|gif|100|28&forward=default|gif|76|28&update_cart=default|gif|108|28&add_to_site=default|gif|122|32';
			}


#		if ($configel->{'THEME'} eq '') {
#			$configel->{'THEME'} = 'name=default&pretty_name=Default&content_background_color=FFFFFF&content_font_face=Arial, Helvetica&content_font_size=3&content_text_color=000000&table_heading_background_color=CCCCCC&table_heading_font_face=Arial, Helvetica&table_heading_font_size=3&table_heading_text_color=000000&table_listing_background_color=FFFFFF&table_listing_background_color_alternate=EEEEEE&table_listing_font_face=Arial, Helvetica&table_listing_font_size=3&table_listing_text_color=000000&link_text_color=000033&link_active_text_color=000066&link_visited_text_color=000000&alert_color=FF0000&disclaimer_background_color=999999&disclaimer_font_face=Arial, Helvetica&disclaimer_font_size=1&disclaimer_text_color=000000';
#			}

		my $changed= 0;

		if (not defined $configel) {
			die();
			}
		else {
			$configel->{'CSS'} =~ s/ };/ }/gs;
			my $cssvar = &TOXML::CSS::css2cssvar($configel->{'CSS'},1);
			$cssvar->{'ztable_row0.font_family'} = $cssvar->{'ztable_row.font_family'};
			$cssvar->{'ztable_row1.font_family'} = $cssvar->{'ztable_row.font_family'};
			$cssvar->{'ztable_row0.color'} = $cssvar->{'ztable_row.color'};
			$cssvar->{'ztable_row1.color'} = $cssvar->{'ztable_row.color'};
			$cssvar->{'ztable_row_title.font_size'} = &TOXML::CSS::bumppt($cssvar->{'ztable_row_title.font_size'},1);
			delete $cssvar->{'ztable_row.bgcolor'};
			
			$configel->{'CSS'} = &TOXML::CSS::cssvar2css($cssvar);
			$changed++;
			}
		

		if ($changed) {
			if ($t->{'_SYSTEM'}==1) { $t->MaSTerSaVE(); } else { $t->save(); }
			}

		# print Dumper($docref,$t);
		}
	}
