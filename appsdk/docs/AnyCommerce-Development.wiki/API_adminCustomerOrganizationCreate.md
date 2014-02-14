# API: adminCustomerOrganizationCreate


## ACCESS REQUIREMENTS: ##
[[CUSTOMER|CONCEPT_customer]] - CREATE




```html

** THESE WILL PROBABLY CHANGE **

| ID              | int(10) unsigned    | NO   | PRI | NULL    | auto_increment |
| MID             | int(10) unsigned    | NO   | MUL | 0       |                |
| USERNAME        | varchar(20)         | NO   |     |         |                |
| PRT             | tinyint(3) unsigned | NO   |     | 0       |                |
| CID             | int(10) unsigned    | NO   |     | 0       |                |
| EMAIL           | varchar(65)         | NO   |     |         |                |
| DOMAIN          | varchar(65)         | YES  |     | NULL    |                |
| firstname       | varchar(25)         | NO   |     |         |                |
| lastname        | varchar(25)         | NO   |     |         |                |
| company         | varchar(100)        | NO   |     |         |                |
| address1        | varchar(60)         | NO   |     |         |                |
| address2        | varchar(60)         | NO   |     |         |                |
| city            | varchar(30)         | NO   |     |         |                |
| region          | varchar(10)         | NO   |     |         |                |
| postal          | varchar(9)          | NO   |     |         |                |
| countrycode     | varchar(9)          | NO   |     |         |                |
| phone           | varchar(12)         | NO   |     |         |                |
| LOGO            | varchar(60)         | NO   |     |         |                |
| BILLING_CONTACT | varchar(60)         | NO   |     |         |                |
| BILLING_PHONE   | varchar(60)         | NO   |     |         |                |
| ALLOW_PO        | tinyint(3) unsigned | NO   |     | 0       |                |
| RESALE          | tinyint(3) unsigned | NO   |     | 0       |                |
| RESALE_PERMIT   | varchar(20)         | NO   |     |         |                |
| CREDIT_LIMIT    | decimal(10,2)       | NO   |     | NULL    |                |
| CREDIT_BALANCE  | decimal(10,2)       | NO   |     | NULL    |                |
| CREDIT_TERMS    | varchar(25)         | NO   |     |         |                |
| ACCOUNT_MANAGER | varchar(10)         | NO   |     |         |                |
| ACCOUNT_TYPE    | varchar(20)         | NO   |     |         |                |
| ACCOUNT_REFID   | varchar(36)         | NO   |     |         |                |
| JEDI_MID        | int(11)             | NO   |     | 0       |                |
| BUYER_PASSWORD


````

## RESPONSE: ##
  * : 
