#!/usr/bin/perl

use Data::Dumper;
use Storable;

my $COUNTRIES = [
{ 'Z' => 'Afghanistan',	'ISO' => 'AF',	'PAYPAL' => 'AF',	'ISOX' => 'AFX', 'PS' => 'Afganistan' },
{ 'Z' => 'Albania',	'ISO' => 'AL', 'PAYPAL' => 'AL',	'FDX' => 'AL', 'UPS' => 'AL',	'ISOX' => 'AL', 'PS' => 'Albania'           },
{ 'Z' => 'Algeria', 'ISO' => 'DZ', 'PAYPAL' => 'DZ', 'FDX' => 'DZ', 'UPS' => 'DZ', 'ISOX' => 'DZ', 'PS' => 'Algeria' },
{ 'Z' => 'American Samoa', 'ISO' => 'AS', 'PAYPAL' => 'AS', 'FDX' => 'AS', 'UPS' => 'AS', 'ISOX' => 'AS' },
{ 'Z' => 'Andorra', 'ISO' => 'AD', 'PAYPAL' => 'AD', 'FDX' => 'AD', 'UPS' => 'AD', 'ISOX' => 'AD', 'PS' => 'Andorra' },
{ 'Z' => 'Angola', 'ISO' => 'AO', 'PAYPAL' => 'AO', 'FDX' => 'AO', 'ISOX' => 'AO', 'PS' => 'Angola' },
{ 'Z' => 'Anguilla', 'ISO' => 'AI', 'PAYPAL' => 'AI', 'FDX' => 'AI', 'UPS' => 'AI', 'ISOX' => 'AI', 'PS' => 'Anguilla' },
{ 'Z' => 'Antartica', 'ISO' => 'AQ', 'PAYPAL' => 'AQ', 'ISOX' => 'AQ', 'PS' => 'Antartica' },
{ 'Z' => 'Antigua/Barbuda', 'ISO' => 'AG', 'FDX' => 'AG', 'UPS' => 'AG', 'ISOX' => 'AG', 'PS' => 'Antigua and Barbuda', 'ENDICIA'=>'AG1' },
{ 'Z' => 'Argentina', 'ISO' => 'AR', 'PAYPAL' => 'AR', 'FDX' => 'AR', 'UPS' => 'AR', 'ISOX' => 'AR', 'PS' => 'Argentina' },
{ 'Z' => 'Armenia', 'ISO' => 'AM', 'PAYPAL' => 'AM', 'FDX' => 'AM', 'UPS' => '', 'ISOX' => 'AM', 'PS' => 'Armenia' },
{ 'Z' => 'Aruba', 'ISO' => 'AW', 'PAYPAL' => 'AW', 'FDX' => 'AW', 'UPS' => 'AW', 'ISOX' => 'AW', 'PS' => 'Aruba' },
{ 'Z' => 'Ascension', 'ISO'=>'AC', 'FDX' => '', 'UPS'=>'', 'ISOX'=>'ASX', 'PS' => 'Ascension' },
{ 'Z' => 'Australia','PAYPAL' => 'AU', 'SAFE' => 1,  'ISO' => 'AU', 'FDX' => 'AU', 'ISOX' => 'AU', 'UPS' => 'AU', 'PS' => 'Australia' },
{ 'Z' => 'Austria','PAYPAL' => 'AT', 'SAFE' => 1,  'ISO' => 'AT', 'FDX' => 'AT', 'ISOX' => 'AT', 'UPS' => 'AT', 'PS' => 'Austria' },
{ 'Z' => 'Azores', 'FDX' => '', 'UPS' => 'AP', 'ISOX' => 'AZX', 'SAFE' => 1, 'PS' => 'Portugal' },
{ 'Z' => 'Azerbaijan', 'ISO' => 'AZ', 'PAYPAL' => 'AZ', 'FDX' => 'AZ', 'UPS' => '', 'ISOX' => 'AZ', 'PS' => 'Azerbaijan' },
{ 'Z' => 'Bahamas','PAYPAL' => 'BS', 'SAFE' => 1,  'ISO' => 'BS', 'FDX' => 'BS', 'ISOX' => 'BS', 'UPS' => 'BS', 'PS' => 'Bahamas' },
{ 'Z' => 'Bahrain', 'ISO' => 'BH', 'PAYPAL' => 'BH', 'FDX' => 'BH', 'UPS' => 'BH', 'ISOX' => 'BH', 'PS' => 'Bahrain' },
{ 'Z' => 'Bangladesh', 'ISO' => 'BD', 'PAYPAL' => 'BD', 'FDX' => 'BD', 'UPS' => 'BD', 'ISOX' => 'BD', 'PS' => 'Bangladesh' },
{ 'Z' => 'Barbados', 'ISO' => 'BB', 'PAYPAL' => 'BB', 'FDX' => 'BB', 'UPS' => 'BB', 'ISOX' => 'BB', 'PS' => 'Barbados' },
{ 'Z' => 'Barbuda', 'FDX' => '', 'UPS' => 'BC', 'ISOX' => 'BAX' },
{ 'Z' => 'Belarus', 'ISO' => 'BY', 'PAYPAL' => 'BY', 'FDX' => 'BY', 'UPS' => 'BY', 'ISOX' => 'BY', 'PS' => 'Belarus' },
{ 'Z' => 'Belgium','PAYPAL' => 'BE', 'SAFE' => 1,  'ISO' => 'BE', 'FDX' => 'BE', 'ISOX' => 'BE', 'UPS' => 'BE', 'PS' => 'Belgium' },
{ 'Z' => 'Belize', 'ISO' => 'BZ', 'PAYPAL' => 'BZ', 'FDX' => 'BZ', 'UPS' => 'BZ', 'ISOX' => 'BZ', 'PS' => 'Belize' },
{ 'Z' => 'Benin', 'ISO' => 'BJ', 'PAYPAL' => 'BJ', 'FDX' => 'BJ', 'UPS' => 'BJ', 'ISOX' => 'BJ', 'PS' => 'Benin' },
{ 'Z' => 'Bermuda', 'ISO' => 'BM', 'PAYPAL' => 'BM', 'FDX' => 'BM', 'UPS' => 'BM', 'ISOX' => 'BM', 'PS' => 'Bermuda' },
{ 'Z' => 'Bhutan', 'ISO' => 'BT', 'PAYPAL' => 'BT', 'FDX' => 'BT,UPS=', 'ISOX' => 'BT', 'PS' => 'Bhutan' },
{ 'Z' => 'Bolivia', 'ISO' => 'BO', 'PAYPAL' => 'BO', 'FDX' => 'BO', 'UPS' => 'BO', 'ISOX' => 'BO', 'PS' => 'Bolivia' },
{ 'Z' => 'Bosnia/Herzegowina', 'ISO' => 'BA', 'PAYPAL' => 'BA', 'ISOX' => 'BOX', 'PS' => 'Bosnia-Herzegovina' },
{ 'Z' => 'Bonaire', 'ISO' => 'AN', 'PAYPAL' => 'AN', 'FDX' => 'AN', 'UPS' => 'BL', 'ISOX' => 'AN', 'PS' => 'Netherlands Antilles' },
{ 'Z' => 'Botswana', 'ISO' => 'BW', 'PAYPAL' => 'BW', 'FDX' => 'BW', 'UPS' => 'BW', 'ISOX' => 'BW', 'PS' => 'Botswana' },
{ 'Z' => 'Bouvet Island', 'ISO' => 'BV', 'PAYPAL' => 'BV', 'ISOX' => 'BV', 'PS' => '' },
{ 'Z' => 'Brazil','PAYPAL' => 'BR', 'SAFE' => 1,  'ISO' => 'BR', 'FDX' => 'BR', 'ISOX' => 'BR', 'UPS' => 'BR', 'PS' => 'Brazil' },
{ 'Z' => 'British Virgin. Isl.', 'ISO' => 'VG', 'PAYPAL' => 'VG', 'FDX' => 'VG', 'UPS' => 'VG', 'ISOX' => 'VG', 'PS' => 'British Virgin Islands' },
{ 'Z' => 'British Indian Ocean Terrority', 'ISO' => 'IO', 'PAYPAL' => 'IO', 'ISOX' => 'IO' },
{ 'Z' => 'Brunei Darussalam', 'ISO' => 'BN', 'PAYPAL' => 'BN', 'FDX' => 'BN', 'UPS' => 'BN', 'ISOX' => 'BN', 'PS' => 'Brunei Darussalam' },
{ 'Z' => 'Bulgaria', 'ISO' => 'BG', 'PAYPAL' => 'BG', 'FDX' => 'BG', 'UPS' => 'BG', 'ISOX' => 'BG', 'PS' => 'Bulgaria' },
{ 'Z' => 'Burkina Faso', 'ISO' => 'BF', 'PAYPAL' => 'BF', 'FDX' => 'BF', 'UPS' => 'BF', 'ISOX' => 'BF', 'PS' => 'Burkina Faso' },
{ 'Z' => 'Burma/Myanmar', 'ISO' => 'MM', 'PAYPAL' => 'MM', 'FDX' => 'MM', 'UPS' => 'MM', 'ISOX' => 'MM', 'PS' => 'Burma' },
{ 'Z' => 'Burundi', 'ISO' => 'BI', 'PAYPAL' => 'BI', 'FDX' => 'BI', 'UPS' => 'BI', 'ISOX' => 'BI', 'PS' => 'Burundi' },
{ 'Z' => 'Cambodia', 'ISO' => 'KH', 'PAYPAL' => 'KH', 'FDX' => 'KH', 'UPS' => 'KH', 'ISOX' => 'KH', 'PS' => 'Cambodia' },
{ 'Z' => 'Cameroon', 'ISO' => 'CM', 'PAYPAL' => 'CM', 'FDX' => 'CM', 'UPS' => 'CM', 'ISOX' => 'CM', 'PS' => 'Cameroon' },
{ 'Z' => 'Canada','PAYPAL' => 'CA', 'SAFE' => 1,  'ISO' => 'CA', 'FDX' => 'CA', 'ISOX' => 'CA', 'UPS' => 'CA', 'PS' => 'Canada' },
{ 'Z' => 'Cape Verde', 'ISO' => 'CV', 'PAYPAL' => 'CV', 'FDX' => 'CV', 'UPS' => 'CV', 'ISOX' => 'CV', 'PS' => 'Cape Verde' },
{ 'Z' => 'Canary Islands', 'ISO' => 'ES', 'PAYPAL' => 'ES', 'FDX' => 'ES', 'UPS'=>'ES', 'ISOX' => 'ES', 'SAFE' => 1, 'PS' => 'Spain' },
{ 'Z' => 'Cayman Islands', 'ISO' => 'KY', 'PAYPAL' => 'KY', 'FDX' => 'KY', 'UPS' => 'KY', 'ISOX' => 'KY', 'PS' => 'Cayman Islands' },
{ 'Z' => 'Central African Rep.', 'UPS' => 'CF', 'ISOX' => 'CAX', 'PS' => 'Central African Republic', 'ALT'=>'CENTRAL AFRICAN REPUBLIC' },
{ 'Z' => 'Chad', 'ISO' => 'TD', 'PAYPAL' => 'TD', 'FDX' => 'TD', 'UPS' => 'TD', 'ISOX' => 'TD', 'PS' => 'Chad' },
{ 'Z' => 'Channel Islands', 'PAYPAL' => 'GB', 'FDX' => 'GB', 'UPS' => 'EN', 'ISOX' => 'GBI' },
{ 'Z' => 'Chile', 'ISO' => 'CL', 'PAYPAL' => 'CL', 'FDX' => 'CL', 'UPS' => 'CL', 'ISOX' => 'CL', 'PS' => 'Chile' },
{ 'Z' => 'China', 'ISO' => 'CN', 'PAYPAL' => 'CN', 'FDX' => 'CN', 'UPS' => 'CN', 'ISOX' => 'CN', 'PS' => 'China' },
{ 'Z' => 'Cocos (Keeling) Isl.', 'UPS' => 'CC', 'PS'=>'', 'ISOX' => 'COX' },
{ 'Z' => 'Columbia', 'ISO' => 'CO', 'PAYPAL' => 'CO', 'FDX' => 'CO', 'UPS' => 'CO', 'ISOX' => 'CO', 'PS' => 'Colombia' },
{ 'Z' => 'Comoros', 'ISOX' => 'CMX', 'PS' => 'Comoros' },
{ 'Z' => 'Congo', 'ISO' => 'CG', 'PAYPAL' => 'CG', 'FDX' => 'CG', 'UPS' => 'CG', 'ISOX' => 'CG' },
{ 'Z' => 'Congo, the Democratic Republic of the', 'ISO'=>'CD', 'PS'=>'Congo Democratic Republic of the', ALT=>'DEMOCRATIC REPUBLIC OF THE CONGO' },
{ 'Z' => 'Cook Islands', 'ISO' => 'CK', 'PAYPAL' => 'CK', 'FDX' => 'CK', 'UPS' => 'CK', 'ISOX' => 'CK', 'NEW PS' => 'Zealand' },
{ 'Z' => 'Costa Rica', 'ISO' => 'CR', 'PAYPAL' => 'CR', 'FDX' => 'CR', 'UPS' => 'CR', 'ISOX' => 'CR', 'COSTA PS' => 'Rica' },
{ 'Z' => 'Croatia', 'ISO' => 'HR', 'PAYPAL' => 'HR', 'FDX' => 'HR', 'UPS' => 'HR', 'ISOX' => 'HR', 'PS' => 'Croatia' },
{ 'Z' => 'Cuba', 'ISOX' => 'CUX', 'PS' => 'Cuba' },
{ 'Z' => 'Curacao', 'ISO' => 'AN', 'PAYPAL' => 'AN', 'FDX' => 'AN', 'NETHERLANDS PS' => 'Antilles', 'ISOX' => 'AN' },
{ 'Z' => 'Cyprus', 'ISO' => 'CY', 'PAYPAL' => 'CY', 'FDX' => 'CY', 'UPS' => 'CY', 'ISOX' => 'CY', 'PS' => 'Cyprus' },
{ 'Z' => 'Czech. Republic', 'ISO' => 'CZ', 'PAYPAL' => 'CZ', 'FDX' => 'CZ', 'UPS' => 'CZ', 'ISOX' => 'CZ', 'PS' => 'Czech Republic' },
{ 'Z' => 'Denmark','PAYPAL' => 'DK', 'SAFE' => 1,  'ISO' => 'DK', 'FDX' => 'DK', 'ISOX' => 'DK', 'UPS' => 'DK', 'PS' => 'Denmark' },
{ 'Z' => 'Djibouti', 'ISO' => 'DJ', 'PAYPAL' => 'DJ', 'FDX' => 'DJ', 'UPS' => 'DJ', 'ISOX' => 'DJ', 'PS' => 'Djibouti' },
{ 'Z' => 'Dominica', 'ISO' => 'DM', 'PAYPAL' => 'DM', 'FDX' => 'DM', 'UPS' => 'DM', 'ISOX' => 'DM', 'PS' => 'Dominica' },
{ 'Z' => 'Dominican Republic', 'ISO' => 'DO', 'PAYPAL' => 'DO', 'FDX' => 'DO', 'UPS' => 'DO', 'ISOX' => 'DO', 'PS' => 'Dominican Republic' },
{ 'Z' => 'Ecuador', 'ISO' => 'EC', 'PAYPAL' => 'EC', 'FDX' => 'EC', 'UPS' => 'EC', 'ISOX' => 'EC', 'PS' => 'Ecuador' },
{ 'Z' => 'Egypt', 'ISO' => 'EG', 'PAYPAL' => 'EG', 'FDX' => 'EG', 'UPS' => 'EG', 'ISOX' => 'EG', 'PS' => 'Egypt' },
{ 'Z' => 'El Salvador', 'ISO' => 'SV', 'PAYPAL' => 'SV', 'FDX' => 'SV', 'UPS' => 'SV', 'ISOX' => 'SV', 'PS' => 'El Salvador' },
{ 'Z' => 'England', 'FDX' => 'GB', 'UPS' => 'EN', 'ISOX' => 'GBE', 'SAFE' => 1, 'PS' => 'Great Britain and Northern Ireland' },
{ 'Z' => 'Equatorial Guinea', 'ISO' => 'GQ', 'PAYPAL' => 'GQ', 'FDX' => 'GQ', 'UPS' => 'GQ', 'ISOX' => 'GQ', 'PS' => 'Equatorial Guinea' },
{ 'Z' => 'Eritrea', 'ISO' => 'ER', 'PAYPAL' => 'ER', 'FDX' => 'ER', 'UPS' => 'ER', 'ISOX' => 'ER', 'PS' => 'Eritrea' },
{ 'Z' => 'Estonia', 'ISO' => 'EE', 'PAYPAL' => 'EE', 'FDX' => 'EE', 'UPS' => 'EE', 'ISOX' => 'EE', 'PS' => 'Estonia' },
{ 'Z' => 'Ethiopia', 'ISO' => 'ET', 'PAYPAL' => 'ET', 'FDX' => 'ET', 'UPS' => 'ET', 'ISOX' => 'ET', 'PS' => 'Ethiopia' },
{ 'Z' => 'Falkland Islands', 'ISOX' => 'FIX', 'PS' => 'Falkland Islands' },
{ 'Z' => 'Faroe Islands', 'ISO' => 'FO', 'PAYPAL' => 'FO', 'FDX' => 'FO', 'UPS' => 'FO', 'ISOX' => 'FO', 'FAROE PS' => 'Islands' },
{ 'Z' => 'Fiji', 'ISO' => 'FJ', 'PAYPAL' => 'FJ', 'FDX' => 'FJ', 'UPS' => 'FJ', 'ISOX' => 'FJ', 'PS' => 'Fiji' },
{ 'Z' => 'Finland','PAYPAL' => 'FI', 'SAFE' => 1,  'ISO' => 'FI', 'FDX' => 'FI', 'ISOX' => 'FI', 'UPS' => 'FI', 'PS' => 'Finland' },
{ 'Z' => 'France','PAYPAL' => 'FR', 'SAFE' => 1,  'ISO' => 'FR', 'FDX' => 'FR', 'ISOX' => 'FR', 'UPS' => 'FR', 'PS' => 'France' },
{ 'Z' => 'French Guinea', 'ISO' => 'GF', 'PAYPAL' => 'GF', 'FDX' => 'GF', 'UPS' => 'GF', 'ISOX' => 'GF', 'PS' => 'French Guiana' },
{ 'Z' => 'French Polynesia', 'ISO' => 'PF', 'PAYPAL' => 'PF', 'FDX' => 'PF', 'UPS' => 'PF', 'ISOX' => 'PF', 'PS' => 'French Polynesia' },
{ 'Z' => 'Gabon', 'ISO' => 'GA', 'PAYPAL' => 'GA', 'FDX' => 'GA', 'UPS' => 'GA', 'ISOX' => 'GA', 'PS' => 'Gabon' },
{ 'Z' => 'Gambia', 'ISO' => 'GM', 'PAYPAL' => 'GM', 'FDX' => 'GM', 'UPS' => 'GM', 'ISOX' => 'GM', 'PS' => 'Gambia' },
{ 'Z' => 'Georgia', 'ISO' => 'GE', 'PAYPAL' => 'GE', 'FDX' => 'GE', 'ISOX' => 'GE', 'PS' => 'Georgia, Republic of' },
{ 'Z' => 'Germany','PAYPAL' => 'DE', 'SAFE' => 1,  'ISO' => 'DE', 'FDX' => 'DE', 'ISOX' => 'DE', 'UPS' => 'DE', 'PS' => 'Germany' },
{ 'Z' => 'Ghana', 'ISO' => 'GH', 'PAYPAL' => 'GH', 'FDX' => 'GH', 'UPS' => 'GH', 'ISOX' => 'GH', 'PS' => 'Ghana' },
{ 'Z' => 'Gibraltar', 'ISO' => 'GI', 'PAYPAL' => 'GI', 'FDX' => 'GI', 'UPS' => 'GI', 'ISOX' => 'GI', 'PS' => 'Gibraltar' },
{ 'Z' => 'Greece','PAYPAL' => 'GR', 'SAFE' => 1,  'ISO' => 'GR', 'FDX' => 'GR', 'ISOX' => 'GR', 'UPS' => 'GR', 'PS' => 'Greece' },
{ 'Z' => 'Greenland','PAYPAL' => 'GL', 'SAFE' => 1,  'ISO' => 'GL', 'FDX' => 'GL', 'ISOX' => 'GL', 'UPS' => 'GL', 'PS' => 'Greenland' },
{ 'Z' => 'Grenada', 'ISO' => 'GD', 'PAYPAL' => 'GD', 'FDX' => 'GD', 'UPS' => 'GD', 'ISOX' => 'GD', 'PS' => 'Grenada' },
{ 'Z' => 'Guadeloupe', 'ISO' => 'GP', 'PAYPAL' => 'GP', 'FDX' => 'GP', 'UPS' => 'GP', 'ISOX' => 'GP', 'PS' => 'Guadeloupe' },
{ 'Z' => 'Guam', 'ISO' => 'GU', 'PAYPAL' => 'GU', 'FDX' => 'GU', 'UPS' => 'GU', 'ISOX' => 'GU' },
{ 'Z' => 'Guatemala', 'ISO' => 'GT', 'PAYPAL' => 'GT', 'FDX' => 'GT', 'UPS' => 'GT', 'ISOX' => 'GT', 'PS' => 'Guatemala' },
{ 'Z' => 'Guinea', 'ISO' => 'GN', 'PAYPAL' => 'GN', 'FDX' => 'GN', 'UPS' => 'GN', 'ISOX' => 'GN', 'PS' => 'Guinea' },
{ 'Z' => 'Guinea-Bissau', 'ISO' => 'GW', 'PAYPAL' => 'GW', 'FDX' => 'GW', 'UPS' => 'GW', 'ISOX' => 'GW' },
{ 'Z' => 'Guyana', 'ISO' => 'GY', 'PAYPAL' => 'GY', 'FDX' => 'GY', 'UPS' => 'GY', 'ISOX' => 'GY', 'PS' => 'Guyana' },
{ 'Z' => 'Haiti', 'ISO' => 'HT', 'PAYPAL' => 'HT', 'FDX' => 'HT', 'UPS' => 'HT', 'ISOX' => 'HT', 'PS' => 'Haiti' },
{ 'Z' => 'Holland', 'ISO' => 'NL', 'PAYPAL' => 'NL', 'FDX' => 'NL', 'UPS' => 'HO', 'ISOX' => 'NL' },
{ 'Z' => 'Honduras', 'ISO' => 'HN', 'PAYPAL' => 'HN', 'FDX' => 'HN', 'UPS' => 'HN', 'ISOX' => 'HN', 'PS' => 'Honduras' },
{ 'Z' => 'Hong Kong', 'ISO' => 'HK', 'PAYPAL' => 'HK', 'FDX' => 'HK', 'UPS' => 'HK', 'ISOX' => 'HK', 'PS' => 'Hong Kong' },
{ 'Z' => 'Hungary', 'ISO' => 'HU', 'PAYPAL' => 'HU', 'FDX' => 'HU', 'UPS' => 'HU', 'ISOX' => 'HU', 'PS' => 'Hungary' },
{ 'Z' => 'Iceland','PAYPAL' => 'IS', 'SAFE' => 1,  'ISO' => 'IS', 'FDX' => 'IS', 'ISOX' => 'IS', 'UPS' => 'IS', 'PS' => 'Iceland' },
{ 'Z' => 'India', 'ISO' => 'IN', 'PAYPAL' => 'IN', 'FDX' => 'IN', 'UPS' => 'IN', 'ISOX' => 'IN', 'PS' => 'India' },
{ 'Z' => 'Indonesia', 'ISO' => 'ID', 'PAYPAL' => 'ID', 'FDX' => 'ID', 'UPS' => 'ID', 'ISOX' => 'ID', 'PS' => 'Indonesia' },
{ 'Z' => 'Iran', 'ISOX' => 'IRX', 'PS' => 'Iran', 'ENDICIA'=>'IR1', 'ALT'=>'Persia' },
{ 'Z' => 'Iraq', 'ISOX' => 'IQX', 'PS' => 'Iraq' },
{ 'Z' => 'Ireland/Eire','PAYPAL' => 'IE', 'SAFE' => 1,  'ISO' => 'IE', 'FDX' => 'IE', 'ISOX' => 'IE', 'UPS' => 'IE', 'PS' => 'Ireland' },
{ 'Z' => 'Israel', 'ISO' => 'IL', 'PAYPAL' => 'IL', 'FDX' => 'IL', 'UPS' => 'IL', 'ISOX' => 'IL', 'PS' => 'Israel' },
{ 'Z' => 'Italy','PAYPAL' => 'IT', 'SAFE' => 1,  'ISO' => 'IT', 'FDX' => 'IT', 'ISOX' => 'IT', 'UPS' => 'IT', 'PS' => 'Italy' },
{ 'Z' => 'Ivory Coast', 'ISO' => 'CI', 'PAYPAL' => 'CI', 'FDX' => 'CI', 'UPS' => 'CI', 'ISOX' => 'CI' },
{ 'Z' => 'Jamaica', 'ISO' => 'JM', 'PAYPAL' => 'JM', 'FDX' => 'JM', 'UPS' => 'JM', 'ISOX' => 'JM', 'PS' => 'Jamaica' },
{ 'Z' => 'Japan','PAYPAL' => 'JP', 'SAFE' => 1,  'ISO' => 'JP', 'FDX' => 'JP', 'ISOX' => 'JP', 'UPS' => 'JP', 'PS' => 'Japan' },
{ 'Z' => 'Jordan', 'ISO' => 'JO', 'PAYPAL' => 'JO', 'FDX' => 'JO', 'UPS' => 'JO', 'ISOX' => 'JO', 'PS' => 'Jordan' },
{ 'Z' => 'Kazakhstan', 'ISO' => 'KZ', 'PAYPAL' => 'KZ', 'FDX' => 'KZ', 'UPS' => 'KZ', 'ISOX' => 'KZ', 'PS' => 'Kazakhstan' },
{ 'Z' => 'Kenya', 'ISO' => 'KE', 'PAYPAL' => 'KE', 'FDX' => 'KE', 'UPS' => 'KE', 'ISOX' => 'KE', 'PS' => 'Kenya' },
{ 'Z' => 'Kiribati', 'UPS' => 'KI', 'ISOX' => 'KIX', 'PS' => 'Kiribati' },
{ 'Z' => 'Korea South', 'ISO' => 'KR', 'PAYPAL' => 'KR', 'FDX' => 'KR', 'UPS' => 'KR', 'ISOX' => 'KR', 'PS' => 'South Korea' },
{ 'Z' => 'Korea North', 'ISO' => 'KP', 'PS'=>'NORTH KOREA', 'ALT'=>'Democratic Peoples Republic of Korea' },
{ 'Z' => 'Kosrae', 'UPS' => 'KO', 'ISOX' => 'KOX' },
{ 'Z' => 'Kosovo', 'PS'=>'Kosovo', 'ENDICIA'=>'XZ', 'ISO'=>'XK' }, # note: temoproary
{ 'Z' => 'Kuwait', 'ISO' => 'KW', 'PAYPAL' => 'KW', 'FDX' => 'KW', 'UPS' => 'KW', 'ISOX' => 'KW', 'PS' => 'Kuwait' },
{ 'Z' => 'Kyrgyzstan', 'ISO' => 'KG', 'PAYPAL' => 'KG', 'FDX' => 'KG', 'UPS' => 'KG', 'ISOX' => 'KG', 'PS' => 'Kyrgyzstan' },
{ 'Z' => 'Lao People Republic', 'UPS' => 'LA', 'ISOX' => 'LPX', 'PS' => 'Laos' },
{ 'Z' => 'Latvia', 'ISO' => 'LV', 'PAYPAL' => 'LV', 'FDX' => 'LV', 'UPS' => 'LV', 'ISOX' => 'LV', 'PS' => 'Latvia' },
{ 'Z' => 'Lebanon', 'ISO' => 'LB', 'PAYPAL' => 'LB', 'FDX' => 'LB', 'UPS' => 'LB', 'ISOX' => 'LB', 'PS' => 'Lebanon' },
{ 'Z' => 'Lesotho', 'ISO' => 'LS', 'PAYPAL' => 'LS', 'FDX' => 'LS', 'UPS' => 'LS', 'ISOX' => 'LS', 'PS' => 'Lesotho' },
{ 'Z' => 'Liberia', 'ISO' => 'LR', 'PAYPAL' => 'LR', 'FDX' => 'LR', 'UPS' => 'LR', 'ISOX' => 'LR' },
{ 'Z' => 'Libyan Arab Jamahir.', 'ISOX' => 'LAX', 'PS' => 'Libya' },
{ 'Z' => 'Liechtenstein', 'ISO' => 'LI', 'PAYPAL' => 'LI', 'FDX' => 'LI', 'UPS' => 'LI', 'ISOX' => 'LI', 'PS' => 'Liechtenstein' },
{ 'Z' => 'Lithuania', 'ISO' => 'LT', 'PAYPAL' => 'LT', 'FDX' => 'LT', 'UPS' => 'LT', 'ISOX' => 'LT', 'PS' => 'Lithuania' },
{ 'Z' => 'Luxembourg','PAYPAL' => 'LU', 'SAFE' => 1,  'ISO' => 'LU', 'FDX' => 'LU', 'ISOX' => 'LU', 'UPS' => 'LU', 'PS' => 'Luxembourg' },
{ 'Z' => 'Macao', 'ISO' => 'MO', 'PAYPAL' => 'MO', 'FDX' => 'MO', 'UPS' => 'MO', 'ISOX' => 'MO', 'PS' => 'Macao' },
{ 'Z' => 'Macedonia', 'ISO' => 'MK', 'PAYPAL' => 'MK', 'FDX' => 'MK', 'UPS' => 'MK', 'ISOX' => 'MK', 'PS' => 'Macedonia Republic of' },
{ 'Z' => 'Madagascar', 'ISO' => 'MG', 'PAYPAL' => 'MG', 'FDX' => 'MG', 'UPS' => 'MG', 'ISOX' => 'MG', 'PS' => 'Madagascar' },
{ 'Z' => 'Madeira', 'ISOX'=>'PTM', 'UPS' => 'ME', 'ISOX' => 'MAX', 'SAFE' => 1, 'PS' => 'Portugal' }, # note: shares with portugal
{ 'Z' => 'Malawi', 'ISO' => 'MW', 'PAYPAL' => 'MW', 'FDX' => 'MW', 'UPS' => 'MW', 'ISOX' => 'MW', 'PS' => 'Malawi' },
{ 'Z' => 'Malaysia', 'ISO' => 'MY', 'PAYPAL' => 'MY', 'FDX' => 'MY', 'UPS' => 'MY', 'ISOX' => 'MY', 'PS' => 'Malaysia' },
{ 'Z' => 'Maldives', 'ISO' => 'MV', 'PAYPAL' => 'MV', 'FDX' => 'MV', 'UPS' => 'MV', 'ISOX' => 'MV', 'PS' => 'Maldives' },
{ 'Z' => 'Mali', 'ISO' => 'ML', 'PAYPAL' => 'ML', 'FDX' => 'ML', 'UPS' => 'ML', 'ISOX' => 'ML', 'PS' => 'Mali' },
{ 'Z' => 'Malta', 'ISO' => 'MT', 'PAYPAL' => 'MT', 'FDX' => 'MT', 'UPS' => 'MT', 'ISOX' => 'MT', 'PS' => 'Malta' },
{ 'Z' => 'Marshall Islands', 'ISO' => 'MH', 'PAYPAL' => 'MH', 'FDX' => 'MH', 'UPS' => 'MH', 'ISOX' => 'MH' },
{ 'Z' => 'Martinique', 'ISO' => 'MQ', 'PAYPAL' => 'MQ', 'FDX' => 'MQ', 'UPS' => 'MQ', 'ISOX' => 'MQ', 'PS' => 'Martinique' },
{ 'Z' => 'Mauritania', 'ISO' => 'MR', 'PAYPAL' => 'MR', 'FDX' => 'MR', 'UPS' => 'MR', 'ISOX' => 'MR', 'PS' => 'Mauritania' },
{ 'Z' => 'Mauritius', 'ISO' => 'MU', 'PAYPAL' => 'MU', 'FDX' => 'MU', 'UPS' => 'MU', 'ISOX' => 'MU', 'PS' => 'Mauritius' },
{ 'Z' => 'Mayotte', 'ISOX' => 'MAX' },
{ 'Z' => 'Mexico', 'ISO' => 'MX', 'PAYPAL' => 'MX', 'FDX' => 'MX', 'UPS' => 'MX', 'ISOX' => 'MX', 'PS' => 'Mexico' },
{ 'Z' => 'Micronesia', 'ISO' => 'FM', 'PAYPAL' => 'FM', 'FDX' => 'FM', 'UPS' => 'FM', 'ISOX' => 'FM' },
{ 'Z' => 'Moldova', 'ISO' => 'MD', 'PAYPAL' => 'MD', 'FDX' => 'MD', 'ISOX' => 'MD', 'PS' => 'Moldova' },
{ 'Z' => 'Monaco','PAYPAL' => 'MC', 'SAFE' => 1,  'ISO' => 'MC', 'FDX' => 'MC', 'ISOX' => 'MC', 'UPS' => 'MC', 'PS' => 'France' },
{ 'Z' => 'Mongolia', 'ISO' => 'MN', 'PAYPAL' => 'MN', 'FDX' => 'MN', 'UPS' => 'MN', 'ISOX' => 'MN', 'PS' => 'Mongolia' },
{ 'Z' => 'Montserrat', 'ISO' => 'MS', 'PAYPAL' => 'MS', 'FDX' => 'MS', 'UPS' => 'MS', 'ISOX' => 'MS', 'PS' => 'Montserrat' },
{ 'Z' => 'Montenegro', 'ISO'=>'ME', 'ALT'=>'MONTENEGRO, REPUBLIC OF', 'UPS' => 'ME', },
{ 'Z' => 'Morocco', 'ISO' => 'MA', 'PAYPAL' => 'MA', 'FDX' => 'MA', 'UPS' => 'MA', 'ISOX' => 'MA', 'PS' => 'Morocco' },
{ 'Z' => 'Mozambique', 'ISO' => 'MZ', 'PAYPAL' => 'MZ', 'FDX' => 'MZ', 'UPS' => 'MZ', 'ISOX' => 'MZ', 'PS' => 'Mozambique' },
{ 'Z' => 'Namibia', 'ISO' => 'NA', 'PAYPAL' => 'NA', 'FDX' => 'NA', 'UPS' => 'NA', 'ISOX' => 'NA', 'PS' => 'Namibia' },
{ 'Z' => 'Nauru', 'ISOX' => 'NAX', 'PS' => 'Nauru' },
{ 'Z' => 'Nepal', 'ISO' => 'NP', 'PAYPAL' => 'NP', 'FDX' => 'NP', 'UPS' => 'NP', 'ISOX' => 'NP', 'PS' => 'Nepal' },
{ 'Z' => 'Netherlands','PAYPAL' => 'NL', 'SAFE' => 1,  'ISO' => 'NL', 'FDX' => 'NL', 'ISOX' => 'NL', 'UPS' => 'NL', 'PS' => 'Netherlands' },
{ 'Z' => 'Netherlands Antilles', 'ISO' => 'AN', 'PAYPAL' => 'AN', 'FDX' => 'AN', 'UPS' => 'AN', 'ISOX' => 'AN', 'PS' => 'Netherlands Antilles' },
{ 'Z' => 'Nevis', 'ISO' => 'KN', 'PAYPAL' => 'KN', 'FDX' => 'KN', 'UPS' => 'KN', 'ISOX' => 'KN', 'PS' => 'St. Christopher and Nevis' },
{ 'Z' => 'New Caledonia', 'ISO' => 'NC', 'PAYPAL' => 'NC', 'FDX' => 'NC', 'UPS' => 'NC', 'ISOX' => 'NC', 'PS' => 'New Caledonia' },
{ 'Z' => 'New Zealand','PAYPAL' => 'NZ', 'SAFE' => 1,  'ISO' => 'NZ', 'FDX' => 'NZ', 'ISOX' => 'NZ', 'UPS' => 'NZ', 'PS' => 'New Zealand' },
{ 'Z' => 'Nicaragua', 'ISO' => 'NI', 'PAYPAL' => 'NI', 'FDX' => 'NI', 'UPS' => 'NI', 'ISOX' => 'NI', 'PS' => 'Nicaragua' },
{ 'Z' => 'Niger', 'ISO' => 'NE', 'PAYPAL' => 'NE', 'FDX' => 'NE', 'UPS' => 'NE', 'ISOX' => 'NE', 'PS' => 'Niger' },
{ 'Z' => 'Nigeria', 'ISO' => 'NG', 'PAYPAL' => 'NG', 'FDX' => 'NG', 'UPS' => 'NG', 'ISOX' => 'NG', 'PS' => 'Nigeria' },
{ 'Z' => 'Niue', 'ISOX' => 'NEX', 'SAFE' => 1, 'PS' => 'New Zealand' },
{ 'Z' => 'Norfolk Island', 'UPS' => 'NF', 'ISOX' => 'NIX' },
{ 'Z' => 'Northern Ireland','PAYPAL' => 'GB', 'SAFE' => 1, 'FDX' => 'GB', 'ISOX' => 'GBN', 'UPS' => 'NB', 'PS' => 'Great Britain and Northern Ireland' },
{ 'Z' => 'Northern Mariana Isl.	FDX=  , UPS=MP', 'ISOX' => 'NMX' },
{ 'Z' => 'Norway','PAYPAL' => 'NO', 'SAFE' => 1,  'ISO' => 'NO', 'FDX' => 'NO', 'ISOX' => 'NO', 'UPS' => 'NO', 'PS' => 'Norway' },
{ 'Z' => 'Oman', 'ISO' => 'OM', 'PAYPAL' => 'OM', 'FDX' => 'OM', 'UPS' => 'OM', 'ISOX' => 'OM', 'PS' => 'Oman' },
{ 'Z' => 'Pakistan', 'ISO' => 'PK', 'PAYPAL' => 'PK', 'FDX' => 'PK', 'UPS' => 'PK', 'ISOX' => 'PK', 'PS' => 'Pakistan' },
{ 'Z' => 'Palau', 'ISO' => 'PW', 'PAYPAL' => 'PW', 'FDX' => 'PW', 'UPS' => 'PW', 'ISOX' => 'PW' },
{ 'Z' => 'Panama', 'ISO' => 'PA', 'PAYPAL' => 'PA', 'FDX' => 'PA', 'UPS' => 'PA', 'ISOX' => 'PA', 'PS' => 'Panama' },
{ 'Z' => 'Papua New Guinea', 'ISO' => 'PG', 'PAYPAL' => 'PG', 'FDX' => 'PG', 'UPS' => 'PG', 'ISOX' => 'PG', 'PS' => 'Papua New Guinea' },
{ 'Z' => 'Paraguay', 'ISO' => 'PY', 'PAYPAL' => 'PY', 'FDX' => 'PY', 'UPS' => 'PY', 'ISOX' => 'PY', 'PS' => 'Paraguay' },
{ 'Z' => 'Peru', 'ISO' => 'PE', 'PAYPAL' => 'PE', 'FDX' => 'PE', 'UPS' => 'PE', 'ISOX' => 'PE', 'PS' => 'Peru' },
{ 'Z' => 'Philippines', 'ISO' => 'PH', 'PAYPAL' => 'PH', 'FDX' => 'PH', 'UPS' => 'PH', 'ISOX' => 'PH', 'PS' => 'Philippines' },
{ 'Z' => 'Pitcairn Island', 'ISO'=>'PN', 'ISOX' => 'PIX', 'PS' => 'Pitcairn Island', 'ALT'=>'PITCAIRN ISLANDS', },
{ 'Z' => 'Poland','PAYPAL' => 'PL', 'SAFE' => 1,  'ISO' => 'PL', 'FDX' => 'PL', 'ISOX' => 'PL', 'UPS' => 'PL', 'PS' => 'Poland' },
{ 'Z' => 'Ponape', 'UPS' => 'PO', 'ISOX' => 'POX' },
{ 'Z' => 'Portugal','PAYPAL' => 'PT', 'SAFE' => 1,  'ISO' => 'PT', 'FDX' => 'PT', 'ISOX' => 'PT', 'UPS' => 'PT', 'PS' => 'Portugal' },
{ 'Z' => 'Puerto Rico', 'ISO' => 'PR', 'PAYPAL' => 'PR', 'FDX' => 'PR', 'UPS' => 'PR', 'ISOX' => 'PR', 'SAFE' => '1,' },
{ 'Z' => 'Qatar', 'ISO' => 'QA', 'PAYPAL' => 'QA', 'FDX' => 'QA', 'UPS' => 'QA', 'ISOX' => 'QA', 'PS' => 'Qatar' },
{ 'Z' => 'Reunion Islands', 'ISO' => 'RE', 'PAYPAL' => 'RE', 'FDX' => 'RE', 'UPS' => 'RE', 'ISOX' => 'RE', 'PS' => 'Reunion' },
{ 'Z' => 'Romania', 'ISO' => 'RO', 'PAYPAL' => 'RO', 'FDX' => 'RO', 'UPS' => 'RO', 'ISOX' => 'RO', 'PS' => 'Romania' },
{ 'Z' => 'Rota', 'UPS' => 'RT', 'ISOX' => 'ROX' },
{ 'Z' => 'Russia', 'ISO' => 'RU', 'PAYPAL' => 'RU', 'FDX' => 'RU', 'UPS' => 'RU', 'ISOX' => 'RU', 'PS' => 'Russia' },
{ 'Z' => 'Rwanda', 'ISO' => 'RW', 'PAYPAL' => 'RW', 'FDX' => 'RW', 'UPS' => 'RW', 'ISOX' => 'RW', 'PS' => 'Rwanda' },
{ 'Z' => 'Saba', 'ISO' => 'AN', 'PAYPAL' => 'AN', 'FDX' => 'AN', 'UPS' => 'SS', 'ISOX' => 'AN', 'PS' => 'Netherlands Antilles' },
{ 'Z' => 'Saipan', 'ISO' => 'MP', 'PAYPAL' => 'MP', 'FDX' => 'MP', 'UPS' => 'SP', 'ISOX' => 'MP' },
{ 'Z' => 'San Marino', 'ISO' => 'SM', 'PAYPAL' => 'SM', 'FDX' => 'SM', 'UPS' => 'SM', 'ISOX' => 'SM', 'PS' => 'San Marino' },
{ 'Z' => 'Sao Tome/Principe', 'UPS' => 'ST', 'ISOX' => 'STX', 'PS' => 'Sao Tome and Principe' },
{ 'Z' => 'Saudi Arabia', 'ISO' => 'SA', 'PAYPAL' => 'SA', 'FDX' => 'SA', 'UPS' => 'SA', 'ISOX' => 'SA', 'PS' => 'Saudi Arabia' },
{ 'Z' => 'Scotland','PAYPAL' => 'GB', 'SAFE' => 1, 'FDX' => 'GB', 'ISOX' => 'GBS', 'UPS' => 'SF', 'PS' => 'Great Britain and Northern Ireland' },
{ 'Z' => 'Senegal', 'ISO' => 'SN', 'PAYPAL' => 'SN', 'FDX' => 'SN', 'UPS' => 'SN', 'ISOX' => 'SN', 'PS' => 'Senegal' },
{ 'Z' => 'Serbia', 'ISO' => 'RS', 'PAYPAL' => 'RS', 'FDX' => 'RS', 'UPS' => 'RS', 'ISOX' => 'RS', 'PS' => 'Serbia, Republic of' },
{ 'Z' => 'Seychelles', 'ISO' => 'SC', 'PAYPAL' => 'SC', 'FDX' => 'SC', 'UPS' => 'SC', 'ISOX' => 'SC', 'PS' => 'Seychelles' },
{ 'Z' => 'Sierra Leone', 'ISO' => 'SL', 'PAYPAL' => 'SL', 'FDX' => 'SL', 'UPS' => 'SL', 'ISOX' => 'SL', 'PS' => 'Sierra Leone' },
{ 'Z' => 'Singapore', 'ISO' => 'SG', 'PAYPAL' => 'SG', 'FDX' => 'SG', 'UPS' => 'SG', 'ISOX' => 'SG', 'PS' => 'Singapore' },
{ 'Z' => 'Slovakia', 'ISO' => 'SK', 'PAYPAL' => 'SK', 'FDX' => 'SK', 'UPS' => 'SK', 'ISOX' => 'SK', 'PS' => 'Slovak Republic' },
{ 'Z' => 'Slovenia', 'ISO' => 'SI', 'UPS' => 'SI', 'ISOX' => 'SLX', 'PS' => 'Slovenia' },
{ 'Z' => 'Solomon Islands', 'UPS' => 'SB', 'ISOX' => 'SIX', 'PS' => 'Solomon Islands' },
{ 'Z' => 'Somalia', 'ISO'=>'SO', 'UPS' => 'WS', 'ISOX' => 'SOX' },
{ 'Z' => 'Somaliland', 'ISOX'=>'SOL', 'ALT'=>'SOMALI DEMOCRATIC REPUBLIC', },
{ 'Z' => 'South Africa', 'ISO' => 'ZA', 'PAYPAL' => 'ZA', 'FDX' => 'ZA', 'UPS' => 'ZA', 'ISOX' => 'ZA', 'PS' => 'South Africa' },
{ 'Z' => 'Spain','PAYPAL' => 'ES', 'SAFE' => 1,  'ISO' => 'ES', 'FDX' => 'ES', 'ISOX' => 'ES', 'UPS' => 'ES', 'PS' => 'Spain' },
{ 'Z' => 'Canary Islands', 'UPS' => 'ES', 'ISOX' => 'CIX', 'SAFE' => 1, 'PS' => 'Spain' },
{ 'Z' => 'Sri Lanka', 'ISO' => 'LK', 'PAYPAL' => 'LK', 'FDX' => 'LK', 'UPS' => 'LK', 'ISOX' => 'LK', 'PS' => 'Sri Lanka' },
{ 'Z' => 'St. Barthelemy', 'UPS' => 'NT', 'ISOX' => 'SBX' },
{ 'Z' => 'St. Christopher', 'UPS' => 'SW', 'ISOX' => 'SCX', 'PS' => 'St. Christopher and Nevis' },
{ 'Z' => 'St. Croix', 'ISO' => 'VI', 'PAYPAL' => 'VI', 'FDX' => 'VI', 'UPS' => 'SX', 'ISOX' => 'VI', 'SAFE' => 1 },
{ 'Z' => 'St. Eustatius', 'ISO' => 'AN', 'PAYPAL' => 'AN', 'FDX' => 'AN', 'UPS' => 'EU', 'ISOX' => 'AN', 'PS' => 'Netherlands Antilles' },
{ 'Z' => 'St. John', 'ISO' => 'VI', 'PAYPAL' => 'VI', 'FDX' => 'VI', 'UPS' => 'UV', 'ISOX' => 'VI', 'SAFE' => 1 },
{ 'Z' => 'St. Helena', 'ISO'=>'SH', 'ISOX' => 'SHX', 'PS' => 'St. Helena', 'ALT'=>'SAINT HELENA' },
{ 'Z' => 'St. Kitts / Nevis', 'ISO' => 'KN', 'PAYPAL' => 'KN', 'FDX' => 'KN', 'UPS' => 'KN', 'ISOX' => 'KN', 'PS' => 'St. Christopher and Nevis' },
{ 'Z' => 'St. Lucia', 'ISO' => 'LC', 'PAYPAL' => 'LC', 'FDX' => 'LC', 'UPS' => 'LC', 'ISOX' => 'LC', 'PS' => 'St. Lucia' },
{ 'Z' => 'St. Maarten', 'ISO' => 'SX', 'PAYPAL' => 'AN', 'FDX' => 'AN', 'UPS' => 'MB', 'ISOX' => 'AN', 'PS' => 'Netherlands Antilles', 'ALT'=>'Sint Maarten' }, # notE: dutch part of St. Martin
{ 'Z' => 'St. Martin', 'ISO' => 'AN', 'PAYPAL' => 'AN', 'FDX' => 'AN', 'UPS' => 'TB', 'ISOX' => 'AN' },	# Note: french part of Sint Maarten
{ 'Z' => 'St. Pierre /Miquelon', 'ISO'=>'PM', 'ISOX' => 'SPX', 'PS' => 'St. Pierre and Miquelon', 'ENDICIA'=>'PM2', 'ALT'=>'SAINT PIERRE AND MIQUELON' },
{ 'Z' => 'St. Thomas', 'ISO' => 'VI', 'PAYPAL' => 'VI', 'FDX' => 'VI', 'UPS' => 'VL', 'ISOX' => 'VI', 'SAFE' => 1 },
{ 'Z' => 'St. Vincent', 'ISO' => 'VC', 'PAYPAL' => 'VC', 'FDX' => 'VC', 'UPS' => 'VC', 'ISOX' => 'VC' },
{ 'Z' => 'Sudan', 'ISO' => 'SD', 'PAYPAL' => 'SD', 'FDX' => 'SD', 'UPS' => 'SD', 'ISOX' => 'SD', 'PS' => 'Sudan' },
{ 'Z' => 'Suriname', 'ISO' => 'SR', 'PAYPAL' => 'SR', 'FDX' => 'SR', 'UPS' => 'SR', 'ISOX' => 'SR', 'PS' => 'Suriname' },
{ 'Z' => 'Svalbard/Jan Mayen', 'ISOX' => 'SJX' },
{ 'Z' => 'Swaziland', 'ISO' => 'SZ', 'PAYPAL' => 'SZ', 'FDX' => 'SZ', 'UPS' => 'SZ', 'ISOX' => 'SZ', 'PS' => 'Swaziland' },
{ 'Z' => 'Sweden','PAYPAL' => 'SE', 'SAFE' => 1,  'ISO' => 'SE', 'FDX' => 'SE', 'ISOX' => 'SE', 'UPS' => 'SE', 'PS' => 'Sweden' },
{ 'Z' => 'Switzerland','PAYPAL' => 'CH', 'SAFE' => 1,  'ISO' => 'CH', 'FDX' => 'CH', 'ISOX' => 'CH', 'UPS' => 'CH', 'PS' => 'Switzerland' },
{ 'Z' => 'Syria', 'ISO' => 'SY', 'PAYPAL' => 'SY', 'FDX' => 'SY', 'UPS' => 'SY', 'ISOX' => 'SY', 'PS' => 'Syrian Arab Republic' },
{ 'Z' => 'Tahiti', 'UPS' => 'TA', 'ISOX' => 'TAX' },
{ 'Z' => 'Taiwan', 'ISO' => 'TW', 'PAYPAL' => 'TW', 'FDX' => 'TW', 'UPS' => 'TW', 'ISOX' => 'TW', 'PS' => 'Taiwan' },
{ 'Z' => 'Tajikistan', 'UPS' => 'TJ', 'ISOX' => 'TNX', 'PS' => 'Tajikistan' },
{ 'Z' => 'Tanzania', 'ISO' => 'TZ', 'PAYPAL' => 'TZ', 'FDX' => 'TZ', 'UPS' => 'TZ', 'ISOX' => 'TZ', 'PS' => 'Tanzania' },
{ 'Z' => 'Thailand', 'ISO' => 'TH', 'PAYPAL' => 'TH', 'FDX' => 'TH', 'UPS' => 'TH', 'ISOX' => 'TH', 'PS' => 'Thailand' },
{ 'Z' => 'Tinian', 'UPS' => 'TI', 'ISOX' => 'TIX' },
{ 'Z' => 'Togo', 'UPS' => 'TG', 'ISOX' => 'TOX', 'PS' => 'Togo' },
{ 'Z' => 'Tonga', 'UPS' => 'TO', 'ISOX' => 'TAX', 'PS' => 'Tonga' },
{ 'Z' => 'Tortola', 'UPS' => 'TL', 'ISOX' => 'TTX' },
{ 'Z' => 'Trinidad and Tobago', 'ISO' => 'TT', 'PAYPAL' => 'TT', 'FDX' => 'TT', 'UPS' => 'TT', 'ISOX' => 'TT', 'PS' => 'Trinidad and Tobago' },
{ 'Z' => 'Tristan da Cunha', 'ISOX' => 'TCX', 'PS' => 'Tristan da Cunha' },
{ 'Z' => 'Truk', 'UPS' => 'TU', 'ISOX' => 'TKX' },
{ 'Z' => 'Tunisia', 'ISO' => 'TN', 'PAYPAL' => 'TN', 'FDX' => 'TN', 'UPS' => 'TN', 'ISOX' => 'TN', 'PS' => 'Tunisia' },
{ 'Z' => 'Turkey', 'ISO' => 'TR', 'PAYPAL' => 'TR', 'FDX' => 'TR', 'UPS' => 'TR', 'ISOX' => 'TR', 'PS' => 'Turkey' },
{ 'Z' => 'Turkmenistan', 'ISO' => 'TM', 'PAYPAL' => 'TM', 'FDX' => 'TM', 'ISOX' => 'TM', 'PS' => 'Turkmenistan' },
{ 'Z' => 'Turks and Caicos Isl.', 'ISO' => 'TC', 'PAYPAL' => 'TC', 'FDX' => 'TC', 'UPS' => 'TC', 'ISOX' => 'TC', 'PS' => 'Turks and Caicos Islands' },
{ 'Z' => 'Tuvalu', 'ISO' => 'TV', 'PAYPAL' => 'TV', 'UPS' => 'TV', 'ISOX' => 'TV', 'PS' => 'Tuvalu' },
{ 'Z' => 'Uganda', 'ISO' => 'UG', 'PAYPAL' => 'UG', 'FDX' => 'UG', 'UPS' => 'UG', 'ISOX' => 'UG', 'PS' => 'Uganda' },
{ 'Z' => 'Ukraine', 'ISO' => 'UA', 'PAYPAL' => 'UA', 'FDX' => 'UA', 'UPS' => 'UA', 'ISOX' => 'UA', 'PS' => 'Ukraine' },
{ 'Z' => 'Union Island', 'UPS' => 'UI', 'ISOX' => 'UIX' },
{ 'Z' => 'United Arab Emirates', 'ISO' => 'AE', 'PAYPAL' => 'AE', 'FDX' => 'AE', 'UPS' => 'AE', 'ISOX' => 'AE', 'PS' => 'United Arab Emirates', 'ENDICIA'=>'AE1', 'ALT'=>'ABU DHABI' },
{ 'Z' => 'United Kingdom','PAYPAL' => 'GB', 'SAFE' => 1,  'ISO' => 'GB', 'FDX' => 'GB', 'ISOX' => 'GBU', 'UPS' => 'GB', 'PS' => 'Great Britain and Northern Ireland' },
{ 'Z' => 'United States', 'PAYPAL' => 'US', 'SAFE' => 1,  'ISO' => 'US', 'FDX' => 'US', 'ISOX' => 'US', 'UPS' => 'US', 'PS' => 'United States' },
{ 'Z' => 'United States Minor Outlying Islands', 'ISOX'=>'UMI', 'ISO'=>'UM'  },  ## NOTE: this should PROBABLY be QO "Outlying Oceania"
{ 'Z' => 'Uruguay', 'ISO' => 'UY', 'PAYPAL' => 'UY', 'FDX' => 'UY', 'UPS' => 'UY', 'ISOX' => 'UY', 'PS' => 'Uruguay' },
{ 'Z' => 'Uzbekistan', 'ISO' => 'UZ', 'PAYPAL' => 'UZ', 'FDX' => 'UZ', 'UPS' => 'UZ', 'ISOX' => 'UZ', 'PS' => 'Uzbekistan' },
{ 'Z' => 'Vanuatu', 'ISO' => 'VU', 'PAYPAL' => 'VU', 'FDX' => 'VU', 'UPS' => 'VU', 'ISOX' => 'VU', 'PS' => 'Vanuatu' },
{ 'Z' => 'Vatican City', 'ISO' => 'VA', 'PAYPAL' => 'VA', 'FDX' => 'VA', 'ISOX' => 'VA', 'SAFE' => 1, 'PS' => 'Vatican City' },
{ 'Z' => 'Venezuela', 'ISO' => 'VE', 'PAYPAL' => 'VE', 'FDX' => 'VE', 'UPS' => 'VE', 'ISOX' => 'VE', 'PS' => 'Venezuela' },
{ 'Z' => 'Vietnam', 'ISO' => 'VN', 'PAYPAL' => 'VN', 'FDX' => 'VN', 'UPS' => 'VN', 'ISOX' => 'VN', 'PS' => 'Vietnam' },
{ 'Z' => 'Virgin Islands', 'ISO' => 'VG', 'PAYPAL' => 'VG', 'FDX' => 'VG', 'UPS' => 'VI', 'ISOX' => 'VG', 'SAFE' => 1 },
{ 'Z' => 'Virgin Gorda', 'ISO' => 'VR', 'PAYPAL' => 'VR', 'UPS' => 'VR', 'ISOX' => 'VR' },
{ 'Z' => 'Wake Island', 'ISO' => 'WK', 'PAYPAL' => 'WK', 'UPS' => 'WK', 'ISOX' => 'WK' },
{ 'Z' => 'Wales', 'ISO' => 'GB', 'FDX' => 'GB', 'UPS' => 'WL', 'ISOX' => 'GBW', 'SAFE' => 1, 'PS' => 'Great Britain and Northern Ireland' },
{ 'Z' => 'Wallis / Futuna', 'ISO' => 'WF', 'PAYPAL' => 'WF', 'FDX' => 'WF', 'UPS' => 'WF', 'ISOX' => 'WF', 'PS' => 'Wallis and Futuna Islands' },
{ 'Z' => 'Western Samoa', 'ISOX' => 'WSX', 'PS' => 'Western Samoa' },
{ 'Z' => 'Yap', 'UPS' => 'YA', 'ISOX' => 'YAX' },
{ 'Z' => 'Yemen', 'ISO' => 'YE', 'PAYPAL' => 'YE', 'FDX' => 'YE', 'UPS' => 'YE', 'ISOX' => 'YE', 'PS' => 'Yemen' },
{ 'Z' => 'Yugoslavia', 'ISOX' => 'YUX' },
{ 'Z' => 'Zaire', 'ISO' => 'CG', 'PAYPAL' => 'CG', 'FDX' => 'CG', 'UPS' => 'ZR', 'ISOX' => 'CG' },
{ 'Z' => 'Zambia', 'ISO' => 'ZM', 'PAYPAL' => 'ZM', 'FDX' => 'ZM', 'UPS' => 'ZM', 'ISOX' => 'ZM', 'PS' => 'Zambia' },
{ 'Z' => 'Zimbabwe', 'ISO' => 'ZW', 'PAYPAL' => 'ZW', 'FDX' => 'ZW', 'UPS' => 'ZW', 'ISOX' => 'ZW', 'PS' => 'Zimbabwe' },
# UN/LOCODE assigns XZ to represent installations in international waters.[8]
# The Unicode Common Locale Data Repository assigns QO to represent Outlying Oceania (a multi-territory region containing Antarctica, Bouvet Island, 
# the Cocos (Keeling) Islands, Christmas Island, South Georgia and the South Sandwich Islands, Heard Island and McDonald Islands, the British Indian 
# Ocean Territory, the French Southern Territories, and the United States Minor Outlying Islands), QU to represent the European Union, 
# and ZZ to represent "Unknown or Invalid Territory".[19]
        ];



use strict;

my @HIGH = ();
my @LOW = ();
my @CANADA = ();
my %ISO = ();
my %ISOX = ();
my %ZOOVY = ();
my %PAYPAL = ();



my %LOOKUP = (
	);

foreach my $cref (@{$COUNTRIES}) {
	if (not defined $LOOKUP{$cref->{'Z'}}) {
		$LOOKUP{$cref->{'Z'}} = $cref;
		$LOOKUP{uc($cref->{'Z'})} = $cref;
		}
	elsif (not defined $cref->{'Z'}) {
		}
	else {
		print sprintf("Z COLLISION OF Z:%s TO Z:%s\n",$LOOKUP{$cref->{'Z'}}->{'Z'},$cref->{'Z'});
		}

	if (not defined $LOOKUP{$cref->{'ISO'}}) {
		$LOOKUP{$cref->{'ISO'}} = $cref;
		}
	elsif (not defined $cref->{'ISO'}) {
		}
	else {
		print sprintf("ISO[%s] COLLISION OF Z:%s TO Z:%s\n",$cref->{'ISO'},$LOOKUP{$cref->{'ISO'}}->{'Z'},$cref->{'Z'});
		}


	if (not defined $cref->{'PS'}) {
		}
	elsif (not defined $LOOKUP{$cref->{'PS'}}) {
		$LOOKUP{$cref->{'PS'}} = $cref;
		$LOOKUP{uc($cref->{'PS'})} = $cref;
		}
	elsif (not defined $cref->{'PS'}) {
		}
	else {
		print sprintf("ISO[%s] COLLISION OF Z:%s TO Z:%s\n",$cref->{'ISO'},$LOOKUP{$cref->{'PS'}}->{'Z'},$cref->{'Z'});
		}

	if (not defined $cref->{'ALT'}) {
		}
	elsif (not defined $LOOKUP{$cref->{'ALT'}}) {
		$LOOKUP{$cref->{'ALT'}} = $cref;
		$LOOKUP{uc($cref->{'ALT'})} = $cref;
		}
	elsif (not defined $cref->{'ALT'}) {
		}
	else {
		print sprintf("ISO[%s] COLLISION OF Z:%s TO Z:%s\n",$cref->{'ISO'},$LOOKUP{$cref->{'ALT'}}->{'Z'},$cref->{'Z'});
		}
	}

## lets merge in the ENDICIA data
#my %E = ();
#open F, "<./ENDICIA-COUNTRIES-2008.dat";
#while (<F>) {
#	next if (substr($_,0,1) eq '%');
#
#	my ($Country,$Region,$ZIP,$Code,$Rate,$EISO,$EMSWeight,$UNKNOWN,$GXGRateGrp,$EMIRateGrp,$E2011EMI,$PMIRateGrp,$E2011PMI,$PMIWeight,$PMIInsuranceIndemnity,$FCMIRateGrp) = split(/[\t]/,$_);
#	# print "ENDICIA: $Country [$EISO]\n";
#
#	my $cref = undef;
#	
#	if (defined $LOOKUP{$Country}) {
#		$cref = $LOOKUP{$Country};
#		}
#	elsif (defined $LOOKUP{substr($EISO,0,2)}) {
#		$cref = $LOOKUP{substr($EISO,0,2)};
#		}
#	else {
#		print "ENDICIA MISSED ON: $Country/$EISO ISO:$UNKNOWN\n";
#		}
#	
#	}
#close F;

##
##
##

my @ALL = ();
foreach my $row (@{$COUNTRIES}) {
	push @HIGH, $row;
	$ZOOVY{ uc($row->{'Z'}) } = $row;

	if ($row->{'Z'} =~ /[^a-zA-Z]+/) {
		## strip out spaces and punctuation
		my $x = uc($row->{'Z'});
		$x =~ s/[^A-Z]+//gs;
		$ZOOVY{ $x } = $row;
		}

	if ($row->{'SAFE'}>0) { push @LOW, $row; }
	if ($row->{'ISO'} eq 'CA') { push @CANADA, $row; }

	if ((defined $row->{'ISO'}) && (not defined $ISO{ $row->{'ISO'} })) { $ISO{ $row->{'ISO'} } = $row; }
	if ((defined $row->{'ISO'}) && ($row->{'ISO'} eq $row->{'ISOX'})) { $ISO{ $row->{'ISO'} } = $row; }
	if (defined $row->{'ISO'}) { $ISOX{ $row->{'ISO'} } = $row; }
	if (defined $row->{'ISOX'}) { $ISOX{ $row->{'ISOX'} } = $row; }

	if (defined $row->{'PAYPAL'}) { $PAYPAL{ $row->{'PAYPAL'} } = $row; }
	print Dumper($row);
	push @ALL, $row;
	
	}
close F;

open F, ">/httpd/static/countries.dmp";
print F Dumper(\@ALL);
close F;

Storable::nstore \@HIGH, "/httpd/static/country-highrisk.bin";
Storable::nstore \@LOW, "/httpd/static/country-lowrisk.bin";
Storable::nstore \@CANADA, "/httpd/static/country-canada.bin";
Storable::nstore \%ISO, "/httpd/static/country-isolookup.bin";
Storable::nstore \%ISOX, "/httpd/static/country-isoxlookup.bin";
Storable::nstore \%ZOOVY, "/httpd/static/country-zoovylookup.bin";
Storable::nstore \%PAYPAL, "/httpd/static/country-paypallookup.bin";

print q~
#
#add this to the rdist file:
#
/httpd/static/countries.dmp -> \${HOSTS} install;
/httpd/static/country-highrisk.bin -> \${HOSTS} install;
/httpd/static/country-lowrisk.bin -> \${HOSTS} install;
/httpd/static/country-canada.bin -> \${HOSTS} install;
/httpd/static/country-isolookup.bin -> \${HOSTS} install;
/httpd/static/country-isoxlookup.bin -> \${HOSTS} install;
/httpd/static/country-zoovylookup.bin -> \${HOSTS} install;
/httpd/static/country-paypallookup.bin -> \${HOSTS} install;
~;