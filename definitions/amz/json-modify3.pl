#!/usr/perl

use strict;

use File::Slurp;
use JSON::XS;
use lib "/httpd/modules";
use AMAZON3;
use Data::Dumper;

my $ts = time();


my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

opendir my $D, "/httpd/static/definitions/amz";
while ( my $file = readdir($D) ) {
	next if (substr($file,0,1) eq '.');
	next if ($file !~ /\.json$/);
	print "FILE: $file\n";

	my $json = File::Slurp::read_file("/httpd/static/definitions/amz/$file");
	my $jrefs = JSON::XS::decode_json($json);

	my $X = $file;
	$X = uc($X);
	$X =~ s/\.JSON$//gs;
	$X =~ s/^AMZ\.//gs;

	my ($CATREF) = &AMAZON3::fetch_catalogref($X);
	my ($catalog,$subcat) = ($CATREF->{'catalog'},$CATREF->{'subcat'});	## this needs to be updated
	

	print "CATALOG:$catalog SUBCAT:$subcat\n";

	foreach my $field (@{$jrefs}) {

		next if ($field->{'xmlpath'} eq '');

		my @arr = split(/\./, $field->{'xmlpath'});
		my $node = pop(@arr);
		my $subnode = pop(@arr);

		if ($field->{'xmlpath'} =~ /ProductType/ && $node eq 'ColorSpecification') {
			$field->{'amz-format'} = 'ColorSpecification';
			}
		elsif ($field->{'xmlpath'} =~ /ProductType/ && $node eq 'ComputerPlatform') {
			$field->{'amz-format'} = 'ComputerPlatform';
			}
		elsif ($field->{'xmlpath'} =~ /ProductType/ && ($node eq 'Megapixels' || $node eq 'MaxImageResolution')) {
			$field->{'amz-format'} = 'Unit';
			$field->{'amz-units'} = 'pixels';
			}
		elsif ($field->{'xmlpath'} =~ /ProductType/ && $node eq 'DigitalZoom') {
			$field->{'amz-format'} = 'Unit';
			$field->{'amz-units'} = 'x';			
			}
		elsif ($field->{'xmlpath'} =~ /ProductType/) {
			$field->{'amz-format'} = 'Text';
			## unary values

			if ($node eq "Wattage") {
				$field->{'amz-format'} = 'Unit';
				$field->{'amz-units'} = 'watts';
				}
			if ($node eq "Power") {
				$field->{'amz-format'} = 'Unit';
				$field->{'amz-units'} = 'watts-per-sec';
				}
			if ($node eq "Amperage") { 
				$field->{'amz-format'} = 'Unit';
				$field->{'amz-units'} = 'amps';
				}
			if ($node eq "Voltage") { 
				$field->{'amz-format'} = 'Unit';
				$field->{'amz-units'} = 'volts';
				}

			if ($node =~ /(Length|Width|Height|Depth|Diameter|Size|Volume|Weight)/){
				if (($catalog eq 'AUTOPART') && $node eq "Size" ||	
					 ($catalog eq 'MUSICINST' && $node eq 'InstrumentSize')){	
					## don't add unitOfMeasure 
					$field->{'amz-format'} = 'Scalar';
					}
				elsif ($catalog eq 'PETSUPPLY') {
					if ($node eq 'Size') {
						## don't add unitOfMeasure
						$field->{'amz-format'} = 'Scalar';
						}
					else {
						$field->{'amz-format'} = 'Weight';
						}
					}
				else {
					$field->{'amz-format'} = 'Measurement';
					}
				}
			## months and years are valid values
			elsif ($node =~ /AgeRecommended/) {
				$field->{'amz-format'} = 'Age';
				}
			## need to add the Recall node
			elsif ($node =~ /Recall/) {	
				$field->{'amz-format'} = 'Recall';
				}
			## this node should be a number, not a range
			## grab the maximum number if a range is given (2-6 => 6)
			elsif ($node =~ /NumberOfPlayers/) {				
				$field->{'amz-format'} = 'Players';
				}
			}		

		if ($field->{'xmlpath'} =~ /ProductType/){
			## "Standard" ProductType messages were handled earlier.
			}
		else {
			$field->{'amz-format'} = '**Unknown-Format**';
			print "NON-PRODUCTYPE MESSAGE: $field->{'xmlpath'}\n";
			}

		if ($field->{'xmlpath'} =~ /ProductType/){
			## "Standard" ProductType messages were handled earlier.
			#if ($subcat eq '') {
			#	$field->{'xmlpath'} = sprintf("ProductType.%s",$field->{'xmlpath'});
			#	}
			#else {
			#	$field->{'xmlpath'} = sprintf("ProductType.%s",$subcat,$field->{'xmlpath'});
			#	}
			}
		## added for SPORTS
		## "Node"->unitOfMeasure
		elsif ($node eq "Wattage" && $catalog eq 'SPORTS') { 
			$field->{'amz-format'} = 'Unit';
			$field->{'amz-units'} = 'watts';
			}			
		elsif ($catalog eq 'APPAREL' || $catalog eq 'CLOTHING') {
			if ($node eq 'IsCustomizable') { 
				$field->{'amz-format'} = 'Boolean';
				}
			elsif ($node eq "WaistSize" || $node eq "InseamLength" || $node eq "SleeveLength" ||
					 $node eq "NeckSize" || $node eq "ChestSize") {
				$field->{'amz-format'} = 'Measurement';
				}
			elsif ($node eq "Department" || $node eq "PlatinumKeywords") {
				$field->{'amz-format'} = 'Text';
				$field->{'amz-max-length'} = 49;
				}
			else {
				$field->{'amz-format'} = 'Text';
				}
			}
		elsif ($node eq 'Length' || $node eq 'Width' || $node eq 'Height') {
			$field->{'amz-format'} = 'Length';
			}
		elsif ($node =~ /Weight/) {
			$field->{'amz-format'} = 'Weight';
			}
		## months and years are valid values
		elsif ($node =~ /AgeRecommended/ ) {	
			## NOTE: pretty sure these didn't port over correctly in the json (but didn't seem to work on prod before)
			$field->{'amz-format'} = 'Age';
			#$field->{'xmlpath'} = sprintf("AgeRecommendation.%s",$field->{'xmlpath'});
			#$prodxml->{'AgeRecommendation'}{$node}[$n]->content($val);
			#$prodxml->{'AgeRecommendation'}{$node}[$n]{'unitOfMeasure'} = lc($unitOfMeasure);
			}
		## this node should be a number, not a range
		## grab the maximum number if a range is given (2-6 => 6)
		elsif ($node =~ /NumberOfPlayers/) {
			$field->{'amz-format'} = 'Players';
			}
		elsif ($node =~ /Time/) {
			$field->{'amz-format'} = 'Time';
			}
		elsif ($node =~ /WeightRecommended/ ) {
			## NOTE: pretty sure these didn't port over correctly in the json (but didn't seem to work on prod before)
			$field->{'amz-format'} = 'WeightRecommended';
			# $field->{'xmlpath'} = sprintf("WeightRecommendation.%s",$field->{'xmlpath'});
			}
		else { 
			$field->{'amz-format'} = 'Text';
			}

			## ProductType->"SubCat"->"Node"
			## ProductType->"SubCat"->"Node"->unitOfMeasure
		} ## end of foreach $val

   my $pretty_printed_unencoded = $coder->encode($jrefs);

	print $pretty_printed_unencoded;
#	open F, ">/httpd/static/definitions/amz/$file.$ts";
#	print F $json;
#	close F;

	open F, ">/httpd/static/definitions/amz/$file";
	print F $pretty_printed_unencoded;
	close F;
	}
closedir $D;