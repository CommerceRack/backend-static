# API: adminCustomerUpdate


## ACCESS REQUIREMENTS: ##
[[CUSTOMER|CONCEPT_customer]] - U




## INPUT PARAMETERS: ##
  * CID: Customer ID
  * @updates: 

<ul>
* PASSWORDRESET?password=xyz    (or leave blank for random)
* HINTRESET
* SET?firstname=&lastname=&is_locked=&newsletter_1=
* ADDRCREATE?SHORTCUT=DEFAULT&TYPE=BILL|SHIP&firstname=&lastname=&phone=&company=&address1&email=.. 
* ADDRUPDATE? [see ADDRCREATE]
* ADDRREMOVE?TYPE=&SHORTCUT=
* SENDEMAIL?MSGID=&MSGSUBJECT=optional&MSGBODY=optional
* ORGCREATE?firstname=&middlename=&lastname=&company=&address1=&address2=&city=&region=&postal=&countrycode=&phone=&email=&ALLOW_PO=&SCHEDULE=&RESALE=&RESALE_PERMIT=&CREDIT_LIMIT=&CREDIT_BALANCE=&CREDIT_TERMS=&ACCOUNT_MANAGER=&ACCOUNT_TYPE=&ACCOUNT_REFID=&JEDI_MID=&DOMAIN=&LOGO=&IS_LOCKED=&BILLING_PHONE=&BILLING_CONTACT=&
* ORDERLINK?OID=
* NOTECREATE?TXT=
* NOTEREMOVE?NOTEID=
* WALLETCREATE?CC=&YY=&MM=
* WALLETDEFAULT?SECUREID=
* WALLETREMOVE?SECUREID=
* REWARDUPDATE?i=&reason=&
* SETORIGIN?origin=integer
* ADDTODO?title=&note=
* ADDTICKET?title=&note=
* DEPRECATED: WSSET?SCHEDULE=&ALLOW_PO=&RESALE=&RESALE_PERMIT=&CREDIT_LIMIT=&CREDIT_BALANCE=&ACCOUNT_MANAGER=& 
</ul>



## RESPONSE: ##
  * *C: Customer Object

```json


example needed.

```

[Concept - wallet](concept_wallet)
