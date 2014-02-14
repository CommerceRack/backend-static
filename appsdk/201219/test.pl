#!/usr/bin/perl

use JavaScript::SpiderMonkey;

my $js = JavaScript::SpiderMonkey->new();
$js->init();  # Initialize Runtime/Context

my $buf = '';
open F, "<extensions/store_prodlist.js";
while (<F>) { $buf .= $_; }
close F;

my $rc = $js->eval($buf);

use Data::Dumper; print Dumper($rc,$@);


$js->destroy();


__DATA__

