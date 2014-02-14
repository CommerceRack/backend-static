#!/usr/bin/perl

use lib "/httpd/modules";

use JSONAPI;
use XML::Simple;
use Pod::Parser;


my $WIKI_DIR = "AnyCommerce-Development.wiki";

my %GROUPED = ();
foreach my $api (sort keys %JSONAPI::CMDS) {
	my ($func,$requirements,$group) = @{$JSONAPI::CMDS{$api}};
	push @{$GROUPED{$group}}, $api;
	}

use Data::Dumper;
#print Dumper(\%GROUPED);

my @CONCEPTS = ();
opendir $D, "$WIKI_DIR/";
while ( my $dir = readdir($D) ) {
	next if (substr($dir,0,1) eq '.');
	if ($dir =~ /^CONCEPT_(.*?)\.md$/) {
		push @CONCEPTS, $1;
		}
	}
closedir $D;
open F, ">$WIKI_DIR/Concepts.md";
print F "## Concepts ##\n";
my %CONCEPTS = ();
foreach my $concept (sort @CONCEPTS) {
	print F "   * [[$concept|CONCEPT_$concept]]\n";
	$CONCEPTS{$concept}++;
	}
print F "\n\n";
close F;

require OAUTH;
foreach my $object (@OAUTH::OBJECTS) {
	$object = lc($object);
	$object =~ s/\//_/gs;
	next if (defined $CONCEPTS{$object});
#	die "need a page CONCEPT_$object\n";
	}


open F, ">$WIKI_DIR/API_Call_Reference.md";
foreach my $ref (@JSONAPI::GROUP_HEADERS) {
	my ($group,$title,$subtitle) = @{$ref};

	print F "## $title ##\n";
	print F "**$subtitle**\n";
	print F "\n";
	foreach my $api (sort @{$GROUPED{$group}}) {
		my ($func,$properties,$grp) = @_;
		print F "    * [[$api|API_$api]] \n";
		}
	print F "\n\n";
	}
close F;

use XML::Parser;
use XML::Parser::EasyTree;
use strict;
use lib "/httpd/modules";
use JSONAPI;
use Data::Dumper;


#my ($doc) = WEBDOC->new(51609);
use IO::String;
my $io = IO::String->new;

require WEBDOC::PODPLAIN;
my $parser = new WEBDOC::PODPLAIN();
$parser->parse_from_file("/httpd/modules/JSONAPI.pm",$io);
my $buf = ${$io->string_ref()};

my %META = ();

#use HTML::TreeBuilder;
#my $tree = HTML::TreeBuilder->new(
##	marked_sections=>1,
##	unbroken_text=>1,
##	strict_comment=>0,
##	ignore_elements=>['raw'],
#	no_space_compacting=>1,
##	implicit_tags=>0,
##	p_strict=>1,
#	ignore_unknown=>0,
##	store_declarations=>1,
#	store_comments=>1); # empty tree
#$tree->parse_content("$buf");
#my $el = $tree->elementify();

#use XML::SAX;
#use lib ".";
#use MySAXHandler;
  
#my $parser = XML::SAX::ParserFactory->parser(
#  Handler => MySAXHandler->new
#  );
#$parser->parse_string("<xml>\n$buf</xml>\n");

#use XML::Parser;
#my $p1 = XML::Parser->new(
#	Handlers => { Element=>\&handle_element }
#	);
#my ($result) = $p1->parse("<xml>\n$buf</xml>\n");
#
#sub handle_element {
#	my ($p1,$tag,$mode) = @_;
#	print Dumper(@_);
#	die();
#	}
#
#print Dumper($result);
#
#die();

#&parseElement($el,\%META);
#$buf = "<xml>\n$buf\n</xml>";

#use XML::TreeBuilder;
#my $tree = XML::TreeBuilder->new({ 'NoExpand' => 0, 'ErrorContext' => 0 });
#$tree->parse("<xml>\n$buf</xml>\n", 'Start'=>\sub { die(); });
#print "TREE: ".$tree->as_XML;

#use XML::Simple;
#print Dumper(XML::Simple::XMLin("<xml>\n$buf</xml>\n",'ForceArray'=>1,'KeyAttr'=>'_'));
use XML::Parser::EasyTree;
my $parse = new XML::Parser(Style=>'EasyTree');
my $buf = "<xml>\n$buf</xml>\n";
open F, ">xml";
my @lines = split(/\n/,$buf);
my $i = 1;
while (scalar(@lines)>0) {
	print F "$i: " .( shift @lines )."\n";
	$i++;
	}
close F;
my $tree = $parse->parse($buf);
$tree = $tree->[0];

parseElement($tree,\%META);

sub parseElement {
	my ($el,$meta) = @_;

	#print Dumper($el);
	# print $el->tag()."\n";
	if ($el->{'type'} eq 't') { 
		}
	elsif ($el->{'type'} ne 'e') {
		die();
		}
	elsif ($el->{'name'} eq 'API') {
		# print "API FOUND: ".$el->attr("id")."\n";
		push @{$meta->{'@APIS'}}, $el;
		# print "---------------------------------------------\n";
		}
	elsif ($el->{'name'} eq 'SECTION') {
#		print $el->attr('type')."\n";
#		if ($el->attr('type') eq 'tag') { push @{$meta->{'@TAGS'}}, $el->attr('id'); }
#		if ($el->attr('type') eq 'docid') { 
#			$meta->{'docid'} = $el->attr('id');
#			}
		}

	foreach my $elx (@{$el->{'content'}}) {
		if ($elx->{'type'} eq 'e') {
			## print "-- ".$elx->tag()."\n";
			&parseElement($elx,$meta);
			}
		}
	return();
	}




my @APIS = ();
my %API_LOOKUP = ();
foreach my $root (@{$META{'@APIS'}}) {
	# next if (uc($el->tag()) ne 'API');

	my %API = ();
	# $API{'cmd'} = $el->attr('id');
	# my $xml = ''; foreach my $txtnode (@{$tag->{'@'}}) { $xml .= $txtnode->{'txt'}; }
	# my $xml = $API{'xml'} = $el->dump();

	# my ($root) = undef;
	## XML::Simple loses data .. it's not safe.
	## XML::Parser::EasyTree ditches comments, so we're screwed -- this is a ghetto fix:
	#$xml =~ s/<!--/<![CDATA[/gs;
	#$xml =~ s/-->/]]>/gs;
	#my $CMD = undef;
	#eval { 
	#	$XML::Parser::Easytree::Noempty=1;
	#	my $p=new XML::Parser(Style=>'EasyTree');
	#	$root = $p->parse("$xml");
	#	$CMD = $API{'cmd'} = $root->[0]->{'attrib'}->{'id'};
	#	$root = $root->[0]->{'content'};
	#	};

	my $xml = '';
	my $CMD = $API{'cmd'} = $root->{'attrib'}->{'id'};
	print "xxxx CMD: $CMD\n";
	if ($CMD eq 'adminReportDownload') {
		print Dumper($xml,$root);
		}

	my @NODES = ();
	if (defined $root) {
		foreach my $tag (@{$root->{'content'}}) {
			next if ($tag->{'type'} eq 't');
			my %NODE = ();
			if (defined $tag->{'attrib'}) { %NODE = %{$tag->{'attrib'}}; }
			$NODE{'tag'} = $tag->{'name'};
			$NODE{'%'} = $tag;

			## COLLAPSE CDATA:
			if (not defined $tag->{'content'}) {
				}
			elsif (not defined $tag->{'content'}->[0]) {
				}
			elsif (not defined $tag->{'content'}->[0]->{'content'}) {
				}
			elsif ($tag->{'content'}->[0]->{'content'}) {
				$NODE{'_'} = $tag->{'content'}->[0]->{'content'};
				}

#			if ($tag->{'name'} eq 'hint') {
#				$NODE{'_'} =~ s/[\n\r]+/<br>/gs;
#				}
#			elsif ($tag->{'name'} eq 'note') {
#				$NODE{'_'} =~ s/[\n\r]+/<br>/gs;
#				}
#			elsif ($tag->{'name'} eq 'caution') {
#				$NODE{'_'} =~ s/[\n\r]+/<br>/gs;
#				}
			if ($tag->{'name'} eq 'errors') {
				foreach my $err (@{$tag->{'content'}}) {
					next if ($err->{'type'} eq 't');
					my %ERR = %{$err->{'attrib'}};
					$ERR{'_'} = $err->{'content'}->[0]->{'content'};
					push @{$NODE{'@ERRORS'}}, \%ERR;
					}
				}
			push @NODES, \%NODE;
			}
		}
	else {
		my $i = 1;
		print STDERR "=================================================================\nERROR: ".Dumper($@)."\n";
		foreach my $line (split(/\n/,$xml)) {
			print sprintf("%02d: %s\n",$i,$line);
			$i++;
			}
		@NODES = ( { 'type'=>'error', '_'=>"XML parsing error reading API parameters</i><br><xmp>".Dumper($xml)."</xmp>" } );
		}
	$API{'@NODES'} = \@NODES;

	push @APIS, \%API;
	$API_LOOKUP{ $API{'cmd'} } = \%API;
	}


foreach my $cmd (sort keys %JSONAPI::CMDS) {
	next if ($JSONAPI::CMDS{$cmd}->[2] eq 'deprecated');
	# print "CMD: $cmd\n";

	if (not defined $API_LOOKUP{ $cmd }) {
		warn("[[API]] MISSING: $cmd\n");
		}

	my $hasPurpose = 0;
	## do purpose check here.

	next if ($JSONAPI::CMDS{$cmd}->[2] eq 'deprecated');

	my $ACLREF = $JSONAPI::CMDS{$cmd}->[3];

	open F, ">$WIKI_DIR/API_$cmd.md";
	print F "# API: $cmd\n\n";

	if (defined $ACLREF) {
		print F "\n## ACCESS REQUIREMENTS: ##\n";
		foreach my $object (keys %{$ACLREF}) {
			my $permission = $ACLREF->{$object};
			if ($permission eq 'C') { $permission = 'CREATE'; }
			elsif ($permission eq 'R') { $permission = 'READ/DETAIL'; }
			elsif ($permission eq 'W') { $permission = 'WRITE/MODIFY'; }
			elsif ($permission eq 'L') { $permission = 'LIST'; }
			elsif ($permission eq 'S') { $permission = 'SEARCH'; }
			elsif ($permission eq 'D') { $permission = 'DELETE/REMOVE'; }
			print F sprintf("[[%s|CONCEPT_%s]] - $permission\n",$object,lc($object));
			}
		print F "\n";
		}

	my $APIREF = $API_LOOKUP{$cmd};

	my $lasttag = '';
	foreach my $node (@{$APIREF->{'@NODES'}}) {

		if ($lasttag ne $node->{'tag'}) { print F "\n"; }

		$node->{'tag'} = lc($node->{'tag'});
		if ($node->{'tag'} eq 't') {
			print F "$node->{'_'}\n";
			}
		elsif ($node->{'tag'} eq 'purpose') {
			print F "$node->{'_'}\n";
			}
		elsif ($node->{'tag'} eq 'concept') {
			print F "[Concept - $node->{'_'}](concept_$node->{'_'})\n";
			}
		elsif ($node->{'tag'} eq 'input') {
			if ($lasttag ne 'input') {
				print F "## INPUT PARAMETERS: ##\n";
				}
			my ($notes) = '';
			if ($node->{'optional'}) { $notes .= ' _(optional)_ '; }
			if ($node->{'required'}) { $notes .= ' _(required)_ '; }
			print F "  * $node->{'id'}$notes: $node->{'_'}\n";
		#	print Dumper($node);	if ($node->{'id'} eq 'mode') { die(); }
			}
		elsif (($node->{'tag'} eq 'code') || ($node->{'tag'} eq 'sample')) {
			my ($type) = $node->{'type'};
			if ($type eq '') { $type = 'html'; }
			if ($node->{'title'}) { print F "### $node->{'title'} ($type) ###\n"; }
			print F "```$type\n";
			print F "$node->{'_'}\n";
			print F "````\n";
			}
		elsif ($node->{'tag'} eq 'response') {
			if ($lasttag ne 'response') {
				print F "## RESPONSE: ##\n";
				}
			print F "  * $node->{'id'}: $node->{'_'}\n";
			}
		elsif ($node->{'tag'} eq 'output') {
			if ($lasttag ne 'output') {
				print F "## OUTPUT PARAMETERS: ##\n";
				}
			print F "  * $node->{'id'}: $node->{'_'}\n";
			}
		elsif ($node->{'tag'} eq 'hint') {
			print F "_HINT: $node->{'_'}_\n";
			}
		elsif (($node->{'tag'} eq 'note') || ($node->{'tag'} eq 'notes')) {
			foreach my $line ('NOTE:',split(/[\n\r]+/,$node->{'_'}),'') {
				print F "> $line\n";
				}
			}
		elsif ($node->{'tag'} eq 'caution') {
			print F "**CAUTION: $node->{'_'}**\n";
			}
		elsif ($node->{'tag'} eq 'example') {
			print F "```json\n";
			print F $node->{'_'};
			print F "```\n";
			}
		elsif ($node->{'tag'} eq 'errors') {
			print F "\n### Possible Errors ###\n";
			foreach my $err (@{$node->{'@ERRORS'}}) {
				print F "    * $err->{'tag'}.$err->{'id'}: $err->{'_'}\n";
				}
			print F "\n";
			}
		elsif ($node->{'tag'} eq 'acl') {
			print F "\n### Additional Access Notes: ###\n";
			print F " * $node->{'want'}: $node->{'_'}\n";
			}
		elsif ($node->{'tag'} eq 'deprecated') {
			print F "\n### DEPRECATION WARNING: ###\n";
			print F " * Last supported version: $node->{'version'}\n";
			}
		elsif ($node->{'tag'} eq 'raw') {
			print F $node->{'_'}."\n";
			print Dumper($node);
			die();
			}
		else {
			print Dumper($node);
			die("UNKNOWN $cmd NODE: $node->{'tag'}");
			}

		$lasttag = $node->{'tag'};
		}

#	print F "\n\n```\n".Dumper($API_LOOKUP{ $cmd })."```\n";
	close F;

	}

__DATA__

