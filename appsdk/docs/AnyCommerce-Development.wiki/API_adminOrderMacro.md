# API: adminOrderMacro


## ACCESS REQUIREMENTS: ##
[[ORDER|CONCEPT_order]] - U


uses the embedded macro language to set order parameters, depending on access levels macros may not be available.

## INPUT PARAMETERS: ##
  * orderid _(required)_ : order id of the order# to update
  * @updates _(required)_ : macro content


```json



@updates:[
	'cmd',
	'cmd?some=param',
	]


```

_HINT: 


**Using Order Macros (@updates)**

Order Macros provide a developer with a way to make easy, incremental, non-destructive updates to orders. 
The syntax for a macro payload uses a familiar dsn format cmd?key=value&key=value, along with the same
uri encoding rules, and one command per line (making the files very easy to read) -- here is an example:
"SETPOOL?pool=COMPLETED" (without the quotes). A complete list of available commands is below:

* CREATE
* SETPOOL?pool=[pool]\n
* CAPTURE?amount=[amount]\n
* ADDTRACKING?carrier=[UPS|FDX]&track=[1234]\n
* EMAIL?msg=[msgname]\n
* ADDPUBLICNOTE?note=[note]\n
* ADDPRIVATENOTE?note=[note]\n
* ADDCUSTOMERNOTE?note=[note]\n
* SET?key=value	 (for setting attributes)
* SPLITORDER
* MERGEORDER?oid=src orderid
* ADDPAYMENT?tender=CREDIT&amt=0.20&UUID=&ts=&note=&CC=&CY=&CI=&amt=
* ADDPROCESSPAYMENT?VERB=&same_params_as_addpayment<br>
	NOTE: unlike 'ADDPAYMENT' the 'ADDPROCESSPAYMENT' this will add then run the specified verb.
	Verbs are: 'INIT' the payment as if it had been entered by the buyer at checkout,
	other verbs: AUTHORIZE|CAPTURE|CHARGE|VOID|REFUND
* PROCESSPAYMENT?VERB=verb&UUID=uuid&amt=<br>
	Possible verbs: AUTHORIZE|CAPTURE|CHARGE|VOID|REFUND
* SETSHIPADDR?ship/company=&ship/firstname=&ship/lastname=&ship/phone=&ship/address1=&ship/address2=&ship/city=&ship/country=&ship/email=&ship/state=&ship/province=&ship/zip=&ship/int_zip=
* SETBILLADDR?bill/company=&bill/firstname=&bill/lastname=&bill/phone=&bill/address1=&bill/address2=&bill/city=&bill/country=&bill/email=&bill/state=&bill/province=&bill/zip=&bill/int_zip=
* SETSHIPPING?shp_total=&shp_taxable=&shp_carrier=&hnd_total=&hnd_taxable=&ins_total=&ins_taxable=&spc_total=&spc_taxable=
* SETADDRS?any=attribute&anyother=attribute
* SETTAX?sum/tax_method=&sum/tax_total&sum/tax_rate_state=&sum/tax_rate_zone=&
* SETSTUFFXML?xml=encodedstuffxml
* ITEMADD?uuid=&sku=xyz&
* ITEMREMOVE?uuid=
* ITEMUPDATE?uuid=&qty=&price=&
* SAVE
* ECHO


_
