#!/usr/bin/perl

opendir $D, "wizards";
while ($file = readdir($D)) {
	next if (substr($file,0,1) eq '.');

	print "DIR: $file\n";

	$/ = undef;
	open F, "<wizards/$file/main.xml";
	$body = <F>;
	close F;

	$new = '';
	#foreach my $chunk (split(/(<img.*?>)/i,$body)) {
	#	if ($chunk =~ /^(<img.*?src=[\"\']+)(.*?)([\"\'\>]+.*?)$/i) {
	#		($pre,$img,$post) = ($1,$2,$3);
	#		print "IMG[$img]\n";
	#		}
	#	else {
	#		$new .= $chunk;
	#		}
	#	}

	$changes = 0;
	foreach my $chunk (split(/(http\:\/\/gfx\.zoovy\.com\/.*?[\"\' ]+)/i,$body)) {

		if ($chunk =~ /(http\:\/\/gfx\.zoovy\.com\/)(.*?)([\)\"\' ]+)/) {
			$ifile = $2;
			$post = $3;
			print "IFILE[$ifile] POST[$post]\n";
			$chunk = "http://static.zoovy.com/graphics/gfx/$ifile$post";
			$new .= $chunk;
			$changes++;
			}
		elsif ($chunk =~ /^(http\:\/\/proshop\.zoovy\.com\/)(.*?)([\"\' ]+)/) {
			$chunk = "http://static.zoovy.com/$2$3";
			$new .= $chunk;
			$changes++;
			print "STATIC CHUNK: $chunk\n";
			}
		elsif ($chunk =~ /(http\:\/\/www\.zoovy\.com\/)(.*?)([\"\' ]+)/) {
			print "CHUNK: $chunk\n";
			die();
			$ifile = $2;
			$post = $3;
			print "FILE: /httpd/htdocs/$ifile\n";
			if (-f "/httpd/htdocs/$ifile") {
				$changes++;
				open F, "</httpd/htdocs/$ifile"; $content = <F>; close F;
				$ifile = substr($ifile,rindex($ifile,'/')+1);
				open F, ">wizards/$file/$ifile"; print F $content; close F;
				$url = "http://static.zoovy.com/graphics/wizards/$file/$ifile";
				$new .= $url.$post;
				print "URL: $url\n";
				}
			else {
				die();
				}
			}
		else {
			$new .= $chunk;
			}

		}

	if ($changes) {
		open F, ">wizards/$file/main.xml";
		print F $new;
		close F;
		}

	}
closedir($D);