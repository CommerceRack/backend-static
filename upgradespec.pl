#!/usr/bin/perl

use strict;
use lib "/httpd/modules";
use TOXML;
use FLOW::LIST;
use TOXML::UTIL;
use Data::Dumper;
use ZTOOLKIT;

my $USERNAME = '';
my $FORMAT = 'WRAPPER';

my @USERS = ();
push @USERS, '';
# push @USERS, "sporks";

my $dbh = &DBINFO::db_zoovy_connect();
&DBINFO::db_zoovy_close();

foreach my $USERNAME (@USERS) {
	upgradeUser($USERNAME,'WRAPPER');
	}



sub upgradeUser {
	my ($USERNAME,$FORMAT) = @_;

	my $ar = TOXML::UTIL::listDocs($USERNAME,$FORMAT);
	foreach my $docref (@{$ar}) {

		next if (($USERNAME eq '') && ($docref->{'MID'}>0));
		next if (($USERNAME ne '') && ($docref->{'MID'}==0));

		# next if ($docref->{'DOCID'} ne 'gradefade');
		print "DOC: $docref->{'FORMAT'},$docref->{'DOCID'}\n";

		my ($t) = TOXML->new($docref->{'FORMAT'},$docref->{'DOCID'},USERNAME=>$USERNAME);


		my @DIVS = ();
		push @DIVS, '';

		if ((defined $t->{'_DIVS'}) && (scalar(@{$t->{'_DIVS'}})>0)) {
			die("Document has Divs!");
			}

		my $changed = 0;
		foreach my $div (@DIVS) {
			foreach my $iniref (@{$t->getElements($div)}) {
	
				my $TYPE = $iniref->{'TYPE'};
				# print "TYPE: $TYPE\n";

				if ($TYPE eq 'OUTPUT') {}
				elsif ($TYPE eq 'READONLY') {}
				elsif (&ZTOOLKIT::isin(['FOOTER', 'SEARCH','SUBCAT','CARTPRODCATS','PRODCATS'],$TYPE)) {
					if (defined $iniref->{'HTML'}) {
						my $x = $iniref->{'HTML'};
						$iniref->{'HTML'} = &FLOW::LIST::upgrade1to2($iniref->{'HTML'}); 
						if ($x ne $iniref->{'HTML'}) { 
							print "Upgraded $TYPE $iniref->{'ID'}\n";
							$changed++; 
							}
						}				
					}
				elsif (&ZTOOLKIT::isin(['REVIEWS', 'FINDER', 'PRODLIST'],$TYPE)) {
					## FINDER - all SPEC_ 
					foreach my $k (keys %{$iniref}) {
						my $x = $iniref->{$k};
						$iniref->{$k} = &FLOW::LIST::upgrade1to2($iniref->{$k}); 
						if ($x ne $iniref->{$k}) { 
							print "Upgraded $TYPE $iniref->{'ID'}\n";
							$changed++; 
							}
						}
					print Dumper($iniref);
					}
				elsif (&ZTOOLKIT::isin(['MENU','BREADCRUMB'],$TYPE)) {
	
					if ($iniref->{'HTML'} =~ /<!-- CATEGORY -->/) {}
					else {
						$iniref->{'DIVIDER'} = &FLOW::LIST::upgrade1to2($iniref->{'DIVIDER'});
						$iniref->{'BEFORE'} = &FLOW::LIST::upgrade1to2($iniref->{'BEFORE'});
						$iniref->{'AFTER'} = &FLOW::LIST::upgrade1to2($iniref->{'AFTER'});
						$iniref->{'HTML'} = &FLOW::LIST::upgrade1to2($iniref->{'HTML'});
	
						$iniref->{'DIVIDER'} =~ s/"/&quot;/gs;		# escape the divider for runspec
						$iniref->{'DIVIDER'} =~ s/>/&gt;/gs;
						$iniref->{'DIVIDER'} =~ s/</&lt;/gs;
						$iniref->{'DIVIDER'} =~ s/[\n\r]+/ /gs;
		
						my $spec = qq~$iniref->{'BEFORE'}\n<!-- CATEGORY -->\n$iniref->{'HTML'}\n~;
						if ($iniref->{'DIVIDER'} ne '') {
							$spec .= qq~\n<% load(\$TOTALCOUNT); math(op=>"subtract",var=>\$COUNT); math(op=>"subtract",var=>"1"); stop(unless=>\$_); runspec("$iniref->{'DIVIDER'}"); print(); %>\n~;
							}
				
						$spec .=qq~\n<!-- /CATEGORY -->\n$iniref->{'AFTER'}\n~;
						delete $iniref->{'DIVIDER'};
						delete $iniref->{'AFTER'};
						delete $iniref->{'BEFORE'};
		
						$spec =~ s/\$NUM/\$cat_num/gs;
						$spec =~ s/\$MESSAGE/\$cat_pretty/gs;
						$spec =~ s/\$URL/\$cat_url/gs;
						$spec =~ s/\$LT/"&lt;"/gs;
						$spec =~ s/\$GT/"&gt;"/gs;
						$spec =~ s/\$BREAK/"\n"/gs;
			
						$spec =~ s/\$WIDTH/\$button_width/gs;
						$spec =~ s/\$HEIGHT/\$button_height/gs;
						$spec =~ s/\$SRC/\$button_imgsrc/gs;
			
						$iniref->{'HTML'} = $spec;
						print "Upgraded $TYPE $iniref->{'ID'}\n";
						$changed++;
						}
					}
				else {
					print "IGNORED: ".$iniref->{'ID'}.' '.$TYPE." [$changed]\n";
					}
					
				}
			}
		print "CHANGED: $changed\n";
		
		if ($changed) {
			if ($t->{'_SYSTEM'}==1) { $t->MaSTerSaVE(); } else { $t->save(); }
#			die();
			}

		# print Dumper($docref,$t);
		}
	}
