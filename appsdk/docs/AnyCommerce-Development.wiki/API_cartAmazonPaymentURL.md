# API: cartAmazonPaymentURL




## INPUT PARAMETERS: ##
  * _cartid: 
  * shipping:  1|0 	(prompt for shipping address)
  * CancelUrl:  URL to redirect user to if cancel is pressed.
  * ReturnUrl:  URL to redirect user to upon order completion
  * YourAccountUrl:  URL where user can be directed to by amazon if they wish to lookup order status. (don't stree about this, rarely used)

_HINT: 

Returns parameters necessary for CBA interaction:

merchantid: the checkout by amazon assigned merchantid (referred to as [merchantid] in the example below)
b64xml: a base64 encoded xml order object based on the current cart geometry referred to as [b64xml], BUT passed to amazon following "order:"
signature: a sha1, base64 encoded concatenation of the b64xml and the configured cba secret key refrerred to as [signature] in the example below, AND passed to amazon following "signature:"
aws-access-key-id: a public string cba needs to identify this merchant refrred to as [aws-access-key-id] AND passed to amazon following the "aws-access-key-id:" parameter

To generate/create a payment button, suggested parameters are: color: orange, size: small, background: white
https://payments.amazon.com/gp/cba/button?ie=UTF8&color=[color]&background=[background]&size=[size]
ex:
https://payments.amazon.com/gp/cba/button?ie=UTF8&color=orange&background=white&size=small
Use this as the **your button image url** in the example.

The [formurl] is created by the developer using the merchant id, specify either sandbox or non-sandbox (live):
https://payments.amazon.com/checkout/[merchantid]
https://payments-sandbox.amazon.com/checkout/[merchantid]?debug=true

_

```json


&lt;!- NOTE: you do NOT need to include jquery if you already are using jquery -&gt;
<script type="text/javascript" src="https://images-na.ssl-images-amazon.com/images/G/01/cba/js/jquery.js"></script>

<script type="text/javascript" src="https://images-na.ssl-images-amazon.com/images/G/01/cba/js/widget/widget.js"></script>
<form method=POST action="https://payments.amazon.com/checkout/[merchantid]">
<input type="hidden" name="order-input" value="type:merchant-signed-order/aws-accesskey/1;order:[b64xml];signature:[signature];aws-access-key-id:[aws-access-key-id]">
<input type="image" id="cbaImage" name="cbaImage" src="**your button image url**" onClick="this.form.action='[formurl]'; checkoutByAmazon(this.form)">
</form>


```
