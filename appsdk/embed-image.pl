#!/usr/bin/perl

my $FILENAME = $ARGV[0];
if (! -f $FILENAME) {
	die ("need a filename\n");
	}


my $buf = undef;
open F, "<$FILENAME"; while(<F>) { $buf .= $_; } close F;

use MIME::Base64;
use MIME::Types;
use Image::Magick;

my ($mime_type, $encoding) = MIME::Types::by_suffix($FILENAME);
my $p = Image::Magick->new();
$p->Read($FILENAME);
my $height = $p->Get('height');
my $width = $p->get('width');


print sprintf(q~<img height="%s" width="%s" src="data:%s;%s,%s" />~,
	$height,
	$width,
	$mime_type,
	$encoding,
	MIME::Base64::encode_base64($buf,'')
	);

