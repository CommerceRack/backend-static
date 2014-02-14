#!/usr/bin/perl

use strict;
use Storable;
use Data::Dumper;

## LIST OF OFFICIALLY SUPPORTED VARIABLES:
my %DEFAULTS = (
	'bgimage'=>'',		# a background image e.g. "background.gif" or "background.jpg" (recommended)
	'height' =>'',			# the height of the image (if it will be bounded) 
	'width' =>'',			# the width of the image (if it will be bounded)
	'align_x' => 'left',		# possible values: left, center, right
	'align_y' => 'middle',	# possible values: top, middle, botton
	'blur' => 0,			# 1/0
	'border_x' => 1,		# should we put a border on the x axis
	'border_y' => 1,		# should we put a border on the y axis
	'border_type' => '',		# none, bevel, plain (default to: DO NOT DEFAULT)
	'border_color' => '#000000',	# border color
	'bgcolor' => '#FFFFFF',	# duh.
	'font' => 'ARIAL.TTF',	# the corresponding file in the /httpd/fonts directory CASE SENSITIVE
	'font_size' => 12,		# the number of pixels tall 
	'padding_top' => 1,		# 
	'padding_bottom' => 1,
	'padding_left' => 2,
	'padding_right' => 2,
	'text_color' => '#FF0000',
	'shadow' => 0,				# 1/0
	'shadow_color' => '#000000',
	'shadow_offset_x' => 2,
	'shadow_offset_y' => 2,
	'highlight' => 0,
	'highlight_color' => '#FFFFFF',
	'highlight_offset_x' => 2,
	'highlight_offset_y' => 2,
	'stretch' => 0,
	'offset_x' => 0,
	'offset_y' => 0,
	'random' => 0,

	## INTERNAL RESERVED VALUES:		
	'get_height'=>'',		# internally used to determine if we were passed a height (set to zero to turn off user specified values)
	'get_width'=>'',

	);



my $MAINDIR = "/httpd/static/navbuttons";
opendir my $D, $MAINDIR;
while (my $dir = readdir($D)) {
	next if (substr($dir,0,1) eq '.');
	next if (! -d $MAINDIR."/$dir");
	print "DIR: $dir\n";
	
	my %cfg = ();	
	open F, "<$MAINDIR/$dir/button.ini"; $/ = "\n";
	while (<F>) {
		$_ =~ s/[\n\r]+//gs;
		my ($k,$v) = split(/\=/,$_,2);
		$cfg{$k} = $v;
		}
	close F; 

	# print Dumper(\%cfg);


	## default everything.
	foreach my $k (keys %DEFAULTS) {	
		next if ($DEFAULTS{$k} eq '');
		if (not defined $cfg{$k}) { $cfg{$k} = $DEFAULTS{$k}; }
		}

	## do all button validation checks here.
	foreach my $k (keys %cfg) {
		# print STDERR "K: $k\n";
		if (not defined $DEFAULTS{$k}) {
			print "UH-OH $dir has unknown value: $k=$cfg{$k} in button.ini\n";
			}
		}

	## TODO: verify the font exists.
	## TODO: verify the font size is a positive number
	## TODO: verify the height and width are positive numbers (if set)
	## TODO: verify all colors lead with a # and are 6 digits
	if ($cfg{'height'} < 1) { $cfg{'height'} = 1; }
	if ($cfg{'width'} < 1) { $cfg{'width'} = 1; }
	
	
	Storable::nstore \%cfg, "$MAINDIR/$dir/button.bin";
#	chmod 0666, "$MAINDIR/$dir/button.bin";
	}
closedir $D;