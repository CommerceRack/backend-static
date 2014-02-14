# API: cartPaymentQ


Manipulate or display the PaymentQ (a list of payment types for a given cart/order)

## INPUT PARAMETERS: ##
  * cmd _(required)_ : reset|delete|insert|sync
  * ID: required for cmd=delete|insert
  * TN: required for cmd=insert ex: CASH|CREDIT|PO|etc.
  * $$: optional for cmd=insert (max to charge on this payment method)
  * TWO_DIGIT_TENDER_VARIABLES: required for cmd=insert, example: CC, MM, YY, CV for credit card

## RESPONSE: ##
  * paymentQ[].ID: unique id # for this
  * paymentQ[].TN: ex: CASH|CREDIT|ETC.
  * paymentQ[].OTHER_TWO_DIGIT_TENDER_VARIABLES: 
