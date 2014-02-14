#!/usr/bin/perl

my $DATA = q~
SHIPPING(1384461734)?%2b=%2bNo+shipping+overrides+found%2e&_=STOP
RELATIONS(1384461734)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA305+cannot+be+synced+because+the+TS2368%2dD13%3aA305+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384461734)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA304+cannot+be+synced+because+the+TS2368%2dD13%3aA304+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384461734)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA303+cannot+be+synced+because+the+TS2368%2dD13%3aA303+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384461734)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA302+cannot+be+synced+because+the+TS2368%2dD13%3aA302+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384461734)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA301+cannot+be+synced+because+the+TS2368%2dD13%3aA301+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384461734)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA300+cannot+be+synced+because+the+TS2368%2dD13%3aA300+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
INVENTORY(1384461734)?%2b=%2bSet+inventory+Qty+29&_=SUCCESS
PRICES(1384461734)?%2b=%2bZero+price+set+on+SKU+TS2368%2dD13%2c+cannot+transmit&_=STOP
PRICES(1384461734)?%2b=%2bNo+pricing+for+inventoriable+option+parents&_=STOP
IMAGES(1384461734)?%2b=%2bSent+3+images&_=SUCCESS
PRODUCTS(1384459953)?%2b=%2bappended+product+to+feed&MSGID=38&_=SUCCESS
PRODUCTS(1384458865)?%2b=Re%2dQueue+Requested+Via+User+Interface&_=SUCCESS
INVENTORY(1384451666)?%2b=%2bSet+inventory+Qty+29&_=SUCCESS
INVENTORY(1384448949)?%2b=%2bSet+inventory+Qty+29&_=SUCCESS
SHIPPING(1384443700)?%2b=%2bNo+shipping+overrides+found%2e&_=STOP
RELATIONS(1384443700)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA305+cannot+be+synced+because+the+TS2368%2dD13%3aA305+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384443700)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA304+cannot+be+synced+because+the+TS2368%2dD13%3aA304+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384443700)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA303+cannot+be+synced+because+the+TS2368%2dD13%3aA303+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384443700)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA302+cannot+be+synced+because+the+TS2368%2dD13%3aA302+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384443700)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA301+cannot+be+synced+because+the+TS2368%2dD13%3aA301+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384443700)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA300+cannot+be+synced+because+the+TS2368%2dD13%3aA300+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
INVENTORY(1384443700)?%2b=%2bSet+inventory+Qty+29&_=SUCCESS
PRICES(1384443700)?%2b=%2bZero+price+set+on+SKU+TS2368%2dD13%2c+cannot+transmit&_=STOP
PRICES(1384443700)?%2b=%2bNo+pricing+for+inventoriable+option+parents&_=STOP
IMAGES(1384443700)?%2b=%2bSent+3+images&_=SUCCESS
PRODUCTS(1384441906)?%2b=%2bappended+product+to+feed&MSGID=8&_=SUCCESS
PRODUCTS(1384440949)?%2b=Re%2dQueue+Requested+Via+User+Interface&_=SUCCESS
DELETE(1384286500)?%2b=%2bDid+DELETE+%2813%29&_=SUCCESS
PRODUCTS(1384285084)?%2b=Delete+via+PowerTool&_=SUCCESS
PRODUCTS(1384285025)?%2b=Delete+via+PowerTool&_=SUCCESS
PRODUCTS(1384285025)?%2b=Delete+via+PowerTool&_=SUCCESS
SHIPPING(1384200119)?%2b=%2bNo+shipping+overrides+found%2e&_=STOP
RELATIONS(1384200119)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA305+cannot+be+synced+because+the+TS2368%2dD13%3aA305+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384200119)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA304+cannot+be+synced+because+the+TS2368%2dD13%3aA304+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384200119)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA303+cannot+be+synced+because+the+TS2368%2dD13%3aA303+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384200119)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA302+cannot+be+synced+because+the+TS2368%2dD13%3aA302+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384200119)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA301+cannot+be+synced+because+the+TS2368%2dD13%3aA301+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
RELATIONS(1384200119)?%2b=%2bThe+relationship+for+variation/TS2368%2dD13%3aA300+cannot+be+synced+because+the+TS2368%2dD13%3aA300+has+not+been+successfully+sent+to+Amazon%2e+If+this+was+returned+for+%27VALIDATE%27+and+the+product+has+not+yet+been+sent+to+Amazon%2c+this+message+can+be+ignored&_=PAUSE
INVENTORY(1384200119)?%2b=%2bSet+inventory+Qty+29&_=SUCCESS
PRICES(1384200119)?%2b=%2bZero+price+set+on+SKU+TS2368%2dD13%2c+cannot+transmit&_=STOP
PRICES(1384200119)?%2b=%2bNo+pricing+for+inventoriable+option+parents&_=STOP
IMAGES(1384200119)?%2b=%2bSent+3+images&_=SUCCESS
PRODUCTS(1384198297)?%2b=%2bappended+product+to+feed&MSGID=8&_=SUCCESS
PRODUCTS(1384197320)?%2b=Re%2dQueue+Requested+Via+User+Interface&_=SUCCESS
SHIPPING(1383589380)?%2b=%2bNo+shipping+overrides+found%2e&_=STOP
RELATIONS(1383589380)?%2b=%2bSent+6+relations&_=SUCCESS
INVENTORY(1383589380)?%2b=%2bSet+inventory+Qty+29&_=SUCCESS
PRICES(1383589380)?%2b=%2bZero+price+set+on+SKU+TS2368%2dD13%2c+cannot+transmit&_=STOP
PRICES(1383589380)?%2b=%2bNo+pricing+for+inventoriable+option+parents&_=STOP
IMAGES(1383589380)?%2b=%2bSent+3+images&_=SUCCESS
PRODUCTS(1383588151)?%2b=%2bappended+product+to+feed&MSGID=1&_=SUCCESS
PRODUCTS(1383587314)?_=SUCCESS&%2b=Re%2dQueue..
~;

use lib "/httpd/modules";
use Data::Dumper;
use TXLOG;

         my @LOG = ();
         my ($tx) = TXLOG->new($DATA);
         foreach my $line (@{$tx->lines()}) {
            my ($FEED,$TS,$PARAMSREF) = &TXLOG::parseline($line);
            push @LOG, { ts=>$TS, feed=>$FEED, type=>$PARAMSREF->{'_'}, msg=>$PARAMSREF->{'+'}, unique=>($PARAMSREF->{'top'})?1:0  };
            }
         $row->{'@LOG'} = \@LOG;
         delete $row->{'AMZ_ERROR'};      ## don't send this to jt!

print Dumper(\@LOG);

