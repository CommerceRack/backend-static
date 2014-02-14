#!/usr/bin/perl


use XML::Parser;
use XML::Parser::EasyTree;
use strict;
use lib "/httpd/modules";
use WEBDOC;
use PAGE::JQUERY;
use Data::Dumper;


#my ($doc) = WEBDOC->new(51609);
use IO::String;
my $io = IO::String->new;

require WEBDOC::PODPLAIN;
my $parser = new WEBDOC::PODPLAIN();
$parser->parse_from_file("/httpd/modules/PAGE/JQUERY.pm",$io);
my $buf = ${$io->string_ref()};

my ($metaref,$docref) = &WEBDOC::wikiparse($buf,footer=>0);
my @APIS = ();
my %API_LOOKUP = ();
foreach my $tag (@{$docref}) {
	next if ($tag->{'cmd'} ne 'API');
	my %API = ();
	$API{'cmd'} = $tag->{'%inner%'};
	my $xml = ''; foreach my $txtnode (@{$tag->{'@'}}) { $xml .= $txtnode->{'txt'}; }
	$API{'xml'} = $xml;

	my ($in) = undef;
	eval { 
		# XML::Simple::XMLin("<api>$RAWXML</api>",'ForceArray'=>1); 
		$XML::Parser::Easytree::Noempty=1;
		my $p=new XML::Parser(Style=>'EasyTree');
		$in = $p->parse("<api>$xml</api>");
		$in = $in->[0]->{'content'};
		};

	my @NODES = ();
	if (defined $in) {
		foreach my $tag (@{$in}) {
			my %NODE = ();
			if (defined $tag->{'attrib'}) { %NODE = %{$tag->{'attrib'}}; }
			$NODE{'type'} = $tag->{'name'};

			if (defined $tag->{'content'}) {
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
		@NODES = ( { 'type'=>'error', '_'=>"XML parsing error reading API parameters</i><br><xmp>".Dumper($xml)."</xmp>" } );
		}
	$API{'@NODES'} = \@NODES;

	push @APIS, \%API;
	$API_LOOKUP{ $API{'cmd'} } = \%API;
	}
#   my $html = wiki2html_output($subdocref);
#   return($html);

#my ($metaref,$docref) = WEBDOC::wikiparse();
#print Dumper(\@APIS);

foreach my $cmd (sort keys %PAGE::JQUERY::CMDS) {
	next if ($PAGE::JQUERY::CMDS{$cmd}->[2] eq 'deprecated');
	print "CMD: $cmd\n";

	if (not defined $API_LOOKUP{ $cmd }) {
		die("[[API]] MISSING: $cmd\n");
		}

	}
