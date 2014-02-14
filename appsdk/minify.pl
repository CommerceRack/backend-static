#!/usr/bin/perl

use JavaScript::Minifier qw(minify);

my $DIR = "./201216";
parsedir($DIR);

sub parsedir {
	my ($DIR) = @_;
	opendir my $D, "$DIR";
	while ( my $file = readdir($D) ) {
		next if (substr($file,0,1) eq '.');
	
		if (-d "$DIR/$file") {
			print "SUBDIR: $DIR/$file\n";
			&parsedir("$DIR/$file");
			}
		if ($file =~ /^(.*?)\-min\.js$/) {
			print "SKIP: $file\n";
			}
		elsif ($file =~ /^(.*?)\.js$/) {
			my ($fbase) = $1;
			print "FILE: $DIR/$file => $DIR/$fbase-min.js\n";
		 	open(INFILE, "<$DIR/$file") or die;
         open(OUTFILE, ">$DIR/$fbase-min.js") or die;
         minify(input => *INFILE, outfile => *OUTFILE);
         close(INFILE);
         close(OUTFILE);
			}
		}
	closedir $D;
	return();
	}