#!/usr/bin/perl

use lib "/httpd/modules";
use TOXML;
use TOXML::COMPILE;
use Data::Dumper;
use Storable;
use strict;
use Image::Magick;

my $FORMAT = uc($ARGV[0]);
if ($FORMAT eq '') {
	die("You need to specify a type e.g. WIZARD, WRAPPER");
	}

my $PATH = '';
if ($FORMAT eq  'WIZARD') {
	$PATH = "/httpd/static/wizards";
	}
elsif ($FORMAT eq 'WRAPPER') {
	$PATH = "/httpd/static/wrappers";
	}
elsif ($FORMAT eq 'LAYOUT') {
	$PATH = "/httpd/static/layouts";
	}
elsif ($FORMAT eq 'EMAIL') {
	$PATH = "/httpd/static/emails";
	}
elsif ($FORMAT eq 'DEFINITION') {
	$PATH = "/httpd/static/definitions";
	}
elsif ($FORMAT eq 'ORDER') {
	$PATH = "/httpd/static/orders";
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
#		next if (not defined $toxml);
#		next if ($toxml->{'_HASERRORS'});
		if ($toxml->{'_HASERRORS'}) {
			die("Document has errors - cannot compile");
			}

		if ($FORMAT eq 'EMAIL') {
			&findThumbs($FORMAT,$DOCID,$toxml);
			}

		$toxml->MaSTerSaVE('preservexml'=>1);
		Storable::nstore $toxml, "$PATH/$dir/$binfile";
		print "!!!!!!!!!!!!!!!!!!!!!!!!!!! WROTE: $PATH/$dir/$binfile\n";

		chmod 0666, "$PATH/$dir/$binfile";
		chown 65534,65534, "$PATH/$dir/$binfile";
		chmod 0666, "$PATH/$file";
		chown 65534,65534, "$PATH/$file";
	

		&TOXML::UTIL::updateFILE($toxml);

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



if ($FORMAT eq 'WIZARD') {
	my $dbh = &DBINFO::db_zoovy_connect();
	my $qtFORMAT = $dbh->quote($FORMAT);
	my $pstmt = "select DOCID,count(*) X,sum(SELECTED) Y from TOXML_RANKS where FORMAT=$qtFORMAT group by DOCID";
	print STDERR $pstmt."\n";
	my $sth = $dbh->prepare($pstmt);
	$sth->execute();
	while ( my ($DOCID,$REMEMBER,$SELECTED) = $sth->fetchrow() ) {
		my $qtDOCID = $dbh->quote($DOCID);
		$pstmt = "update TOXML set RANK_REMEMBER=$REMEMBER,RANK_SELECTED=$SELECTED where FORMAT=$qtFORMAT and DOCID=$qtDOCID";
		print $pstmt."\n";
		$dbh->do($pstmt);
		}
	$sth->finish();

	$pstmt = "select DOCID,RANK_REMEMBER,RANK_SELECTED,date_format(from_unixtime(CREATED_GMT),'%Y,%j') AGE from TOXML where FORMAT=$qtFORMAT and MID=0 and STARS>=0";
	$sth = $dbh->prepare($pstmt);
	$sth->execute();
	my %SCORES = ();
	while ( my ($DOCID,$REMEMBER,$SELECTED,$AGE) = $sth->fetchrow() ) {
		my ($year,$jday) = split(',',$AGE);
		$year -= 2000;	
		if ($year<0) { $year = 0; } # NOTE: 1970 themes get 0 
		my $SCORE = ($REMEMBER * 6) + ($SELECTED * 25) + ($year*6) + ( $jday / 60 );
		$SCORES{$DOCID} = $SCORE;
		}
	$sth->finish();

	my $step = scalar(keys %SCORES)/10;
	my $i = 0;
	my $stars = 10;
	foreach my $docid (reverse ZTOOLKIT::value_sort(\%SCORES,'numerically')) {
		if ($i++>=$step) { $stars--; $i=0; }
		$SCORES{$docid} = $stars;
		}

	foreach my $docid (keys %SCORES) {
		$pstmt = "update TOXML set STARS=$SCORES{$docid} where FORMAT=$qtFORMAT and DOCID=".$dbh->quote($docid);
		print $pstmt."\n";
		$dbh->do($pstmt);
		}
	
	&DBINFO::db_zoovy_close();
	}

##
## findThumbs
##
sub findThumbs {
	my ($FORMAT,$DOCID,$toxml) = @_;

	my $dir = '';
	if ($FORMAT eq 'WIZARD') {
		$dir = "/httpd/static/wizards";
		}
	elsif ($FORMAT eq 'EMAIL') {
		$dir = "/httpd/static/emails";
		}

	my @IMAGES = ();
	opendir my $D, $dir;
	while ( my $file = readdir($D) ) {
		next if (substr($file,0,1) eq '~');
		if ($file =~ /^($DOCID.*?)\.png$/) {
			push @IMAGES, $1;
			}
		}
	closedir $D;

	my ($config) = $toxml->findElements('CONFIG');
	$config->{'THUMBNAIL_COUNT'} = scalar(@IMAGES);
	$config->{'THUMBNAIL'} = $IMAGES[0];	
	$config->{'THUMBNAILS'} = join(',',@IMAGES);

	foreach my $IMG (sort @IMAGES) {
		my $p = new Image::Magick;
		my $filename = "$dir/$IMG.png";
		print "Reading $filename\n";
		$p->Read($filename);
		createImage($FORMAT,$IMG,$p,0,0);
		createImage($FORMAT,$IMG,$p,180,180);
		createImage($FORMAT,$IMG,$p,75,75);
		createImage($FORMAT,$IMG,$p,32,32);
		undef $p;
		}

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
