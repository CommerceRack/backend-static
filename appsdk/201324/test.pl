#!/usr/bin/perl

use Data::Dumper;

$WIKI = q~
[[This is a test#AND THEN SOME]]
*ONE
*TWO
*THREE
*FOUR
~;


require Text::WikiCreole;
print Dumper(&Text::WikiCreole::creole_parse($WIKI));


__DATA__

use lib "/httpd/modules";
use XMLTOOLS;

my %xml = ();
$xml{"Item.PaymentMethods\$x"} = "Paypal";
$xml{"Item.PaymentMethods\$y"} = "Paypal";
print XMLTOOLS::buildTree(undef,\%xml,1)."\n";



__DATA__

use HTTP::Lite;

			my %vars = ();
			$vars{'code'} = $v->{'googlesso:code'};
#			my $gplusid = $v->{'googlesso:id'};
#			my $oauth2_client_id = 'NEED_THIS';  # clientID :    464875398878.apps.googleusercontent.com
#			my $code = 'CLg_TBRKBvIu0o7cFwr-tfcl';

#			# client secret :  CLg_TBRKBvIu0o7cFwr-tfcl	
			$vars{'client_id'} = '464875398878.apps.googleusercontent.com';
			$vars{'client_secret'} = 'CLg_TBRKBvIu0o7cFwr-tfcl';
			$vars{'redirect_uri'} = 'https://oauth2-login-demo.appspot.com/code';
			$vars{'grant_type'} = 'authorization_code';

			use HTTP::Lite;
			my $http = HTTP::Lite->new;
			$http->http11_mode(1);
			$http->prepare_post( \%vars );
			my $req = $http->request("https://accounts.google.com/o/oauth2/token")
               or die "Unable to get document: $!";
        	my $body = $http->body();

			##
			## A successful response will include:
			##
			# access_token	A token that can be sent to a Google API
			# id_token	A JWT that contains identity information about the user that is digitally signed by Google
			# expires_in	The remaining lifetime on the Access Token
			# token_type	Indicates the type of token returned. At this time, this field will always have the value Bearer	

			print STDERR "BODY: $body\n";

			my $jwt = $body;
			require JSON::WebToken;
			my $identity = JSON::WebToken::decode_jwt($jwt,$vars{'client_secret'},1);
