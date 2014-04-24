#!/usr/bin/perl

use lib "/httpd/modules";
use TOXML;
use TOXML::COMPILE;
use Data::Dumper;
use Storable;
use strict;
use Image::Magick;
use JSON::XS;

my $FORMAT = uc($ARGV[0]);
if ($FORMAT eq '') {
	die("You need to specify a type e.g. WIZARD, WRAPPER");
	}

my $PATH = '';
if ($FORMAT eq 'WRAPPER') {
	$PATH = "/httpd/static/wrappers";
	}
elsif ($FORMAT eq 'LAYOUT') {
	$PATH = "/httpd/static/layouts";
	}
elsif ($FORMAT eq 'DEFINITION') {
	$PATH = "/httpd/static/definitions";
	}
elsif ($FORMAT eq 'USER') {
	$PATH = &ZOOVY::resolve_userpath($ARGV[1]);
	}

if (1) {
	my @FILES = ();

	print "PATH: $PATH\n";
	opendir my $D, $PATH;
	while ( my $dir = readdir($D)) {
	
		my $file = '';
		next if (substr($dir,0,1) eq '.');	# always skip . and ..
		#if ($FORMAT eq 'DEFINITION') {
		#	$file = $dir;
		#	$dir = '/';
		#	}
		if ($FORMAT eq 'USER') {
			if ($dir =~ /(WRAPPER|LAYOUT|ZEMAIL)\+(.*?)\.xml$/) {
				push @FILES, [ $FORMAT, $dir, $file ];
				}
			}
		else {
			$dir .= '/'; $file = 'main.xml'; 
			print "$FORMAT|$PATH/$dir$file\n";
			next if (! -d "$PATH/$dir");
			next if (! -f "$PATH/$dir$file");
			next if ($file !~ /\.xml$/);
			push @FILES, [ $FORMAT, $dir, $file ];
			}
		}
	closedir $D;
	
	foreach my $set (@FILES) {
		my ($FORMAT,$dir,$file) = @{$set};

		my $binfile = substr($file,0,-4).'.bin';
			
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$PATH/$dir$file");	
		my ($bdev,$bino,$bmode,$bnlink,$buid,$bgid,$brdev,$bsize,$batime,$bmtime,$bctime,$bblksize,$bblocks) = stat("$PATH/$dir$binfile");
	
		# komment this line to recompile all files:
		# next if ($bmtime >= $mtime);
	
		print "FILE: $PATH/$dir$file [$bmtime $mtime]\n";
		open F, "<$PATH/$dir$file"; $/ = undef; my $xml = <F>; $/ = "\n"; close F;

		my $DOCID = substr($file,0,-4);
		$DOCID = substr($dir,0,-1);

		my ($toxml) = TOXML::COMPILE::fromXML($FORMAT,$DOCID,$xml);
		if (not defined $toxml) {
			die("$PATH/$dir$file appears to be corrupted");
			}
		if ($toxml->{'_HASERRORS'}) {
			die("Document has errors - cannot compile");
			}

		delete $toxml->{'_USERNAME'};
		delete $toxml->{'_MID'};
		if ($toxml->{'_SYSTEM'} != 1) { 
			die("not a system file"); 
			}
		my $DOCID = $toxml->{'_ID'};

		my $srcfile = '';
		my $binfile = '';
		my $jsonfile = '';
		if ($toxml->{'_FORMAT'} eq 'LAYOUT') {
			# /httpd/static/layouts/$FILE.bin and $FILE.xml	
			$srcfile = "/httpd/static/layouts/$DOCID/main.xml";
			$binfile = "/httpd/static/layouts/$DOCID/main.bin";
			$jsonfile = "/httpd/static/layouts/$DOCID/main.json";
			}
		elsif ($toxml->{'_FORMAT'} eq 'WRAPPER') {
			# /httpd/static/layouts/$FILE.bin and $FILE.xml	
			$toxml->compile();
			$srcfile = "/httpd/static/wrappers/$DOCID/main.xml";
			$binfile = "/httpd/static/wrappers/$DOCID/main.bin";
			$jsonfile = "/httpd/static/wrappers/$DOCID/main.json";
			}

		my $WRITE_FILES = 0;
		if ($srcfile) {
			my ($srcdev,$srcino,$srcmode,$srcnlink,$srcuid,$srcgid,$srcrdev,$srcsize,$srcatime,$srcmtime,$srcctime,$srcblksize,$srcblocks) = stat($srcfile);
			my ($bindev,$binino,$binmode,$binnlink,$binuid,$bingid,$binrdev,$binsize,$binatime,$binmtime,$binctime,$binblksize,$binblocks) = stat($binfile);
			if ($srcmtime > $binmtime) {
				print "!!!!!!!!!!!!!!!!!!!!!!!!!!! WROTE: $binfile\n"; 
				Storable::nstore $toxml, $binfile; 
				chmod 0666, $binfile; chown $ZOOVY::EUID,$ZOOVY::EGID, $binfile; 
				chmod 0666, "$binfile";
				chown 65534,65534, "$binfile";
				&TOXML::UTIL::updateFILE($toxml);
				}
			}

		if ($srcfile) {
			my ($srcdev,$srcino,$srcmode,$srcnlink,$srcuid,$srcgid,$srcrdev,$srcsize,$srcatime,$srcmtime,$srcctime,$srcblksize,$srcblocks) = stat($srcfile);
			my ($jsondev,$jsonino,$jsonmode,$jsonnlink,$jsonuid,$jsongid,$jsonrdev,$jsonsize,$jsonatime,$jsonmtime,$jsonctime,$jsonblksize,$jsonblocks) = stat($jsonfile);
			if ($srcmtime > $jsonmtime) {
				print "!!!!!!!!!!!!!!!!!!!!!!!!!!! WROTE: $jsonfile\n"; 
				open F, ">$jsonfile";
				print F JSON::XS->new->ascii->pretty->allow_nonref->convert_blessed->encode($toxml);
				close F;
				}
			}
	

		if ($WRITE_FILES) {		
			## this really cheeses things in git.
			#if ($xmlfile ne '') { 
			#	print STDERR "TOXML->MaSTerSaVE Wrote: $xmlfile\n";
			#	open F, ">$xmlfile"; print F $toxml->as_xml();  close F; chmod 0666, $xmlfile; chown $ZOOVY::EUID,$ZOOVY::EGID, $xmlfile; 
			#	}

	
			if ($binfile ne '') { 
				}

			#if ($jsonfile ne '') {
			#	}

			}

		# TOXML::UTIL::updateDB($toxml); 
		}
	closedir ($D);
	}


## update stars
if (0) {
	## create the zip file for warehouse manager
	use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
	my $zip = Archive::Zip->new();
	my $dbh = &DBINFO::db_zoovy_connect();
	my $qtFORMAT = $dbh->quote($FORMAT);
	my $pstmt = "select DOCID from TOXML where FORMAT=$qtFORMAT and MID=0";
	my $sth = $dbh->prepare($pstmt);
	$sth->execute();
	while ( my ($DOCID) = $sth->fetchrow() ) {
		next if ($DOCID eq '');
		print "DOCID: $DOCID\n";
		my ($t) = TOXML->new($FORMAT,$DOCID);
		next if (not defined $t);
		my $file = "/tmp/".lc($DOCID).".xml";
		open F, ">$file"; print F $t->as_xml(); close F;
		my $member = $zip->addFile( $file, lc($DOCID.'.xml') );
		}
	die 'write error' unless $zip->writeToFileNamed( "/httpd/htdocs/webapi/$FORMAT.zip" ) == AZ_OK;
	chmod 0777, "/httpd/htdocs/webapi/$FORMAT.zip";
	chown 65534, 65534, "/httpd/htdocs/webapi/$FORMAT.zip";
	}




##
##
##
sub createImage {
	my ($FORMAT,$IMG,$p,$height,$width) = @_;

	my $source_width  = $p->Get('width');
	my $source_height = $p->Get('height');
	print "WIDTH: $source_width HEIGHT: $source_height\n";

	if ($height==0 && $width==0) {
		}
	else {
		
		my $scale_width = undef;
		my $scale_height = undef;
		my $x_offset = undef; my $y_offset = undef;
		if (($source_width == $width) && ($source_height == $height)) {
			$x_offset = 0;
			$y_offset = 0;
			}
		else {
			## See how much each axis needs to be scaled by
			my $width_ratio  = ($width / $source_width);
			my $height_ratio = ($height / $source_height);
			if ($width_ratio == $height_ratio) {
				## Scale the same on both axes
				$scale_width  = int($width_ratio  * $source_width);
				$scale_height = int($height_ratio * $source_height);
				$x_offset   = 0;
				$y_offset   = 0;
				}
			elsif ($width_ratio < $height_ratio) {
				## we have to scale more on  the width (i.e., it has a smaller
				## value), then use it to scale the image
				$scale_width  = int($width_ratio * $source_width);
				$scale_height = int($width_ratio * $source_height);
				$x_offset   = 0;
				$y_offset   = int(($height - $scale_height) / 2);
				}
			else	{
				## we have to scale more on  the height (i.e., it has a smaller
				## value), then use it to scale the image
				$scale_width  = int($height_ratio * $source_width);
				$scale_height = int($height_ratio * $source_height);
				$x_offset   = int(($width - $scale_width) / 2);
				$y_offset   = 0;
				}
			}

		if ((defined $scale_width) && (defined $scale_height)) {
				## Regular scaling
				$p->Scale('width' => $scale_width,'height' => $scale_height,);
				## Scale the image or return a green 1x1 image
				}
		}
	my $filename = '';
	if ($FORMAT eq 'WIZARD') {
		$filename = "/httpd/htdocs/images/wizards/$IMG~${width}x${height}.png";
		}
	elsif ($FORMAT eq 'EMAIL') {
		$filename = "/httpd/htdocs/images/emails/$IMG~${width}x${height}.png";
		}
	print "FILENAME: $filename\n";
	unlink $filename;
	$p->Set('magick' => 'png');
	$p->Write($filename);
	if (! -f $filename) {
		die("could not write $filename\n");
		}
	chown(65534,65534,$filename);
	chmod 0666, $filename;

	}
