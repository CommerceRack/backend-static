# API: cartGoogleCheckoutURL




## INPUT PARAMETERS: ##
  * _cartid: 
  * analyticsdata:  (required, but may be blank) obtained by calling getUrchinFieldValue() 
in the pageTracker or _gaq Google Analytics object.

  * edit_cart_url: 
  * continue_shopping_url: 

_HINT: 

Google has extensive documentation on it's checkout protocols, you need use buttons served by google.
MORE INFO: http://code.google.com/apis/checkout/developer/index.html#google_checkout_buttons

NOTE: googleCheckoutMerchantId is passed in the config.js if it's blank, the configuration is incomplete and don't
try using it as a payment method.

To select a button you will need to know the merchant id (which is returned by this call), the style and
variant type of the button. Examples are provided below so hopefully you can skip reading it! 
You must use their button(s). Possible: style: white|trans, Possible variant: text|disable

_

**CAUTION: 

note: if one or more items in the cart has 'gc:blocked' set to true - then google checkout button must be
shown as DISABLED using code below:
https://checkout.google.com/buttons/checkout.gif?merchant_id=[merchantid]&w=160&h=43&style=[style]&variant=[variant]&loc=en_US

These are Googles branding guidelines, hiding the button (on a website) can lead to stern reprimand and even termination from 
Google programs such as "trusted merchant".

**

_HINT: 

Here is example HTML that would be used with the Asynchronous Google Analytics tracker (_gaq).

<a href="javascript:_gaq.push(function() {
   var pageTracker = _gaq._getAsyncTracker();setUrchinInputCode(pageTracker);});
   document.location='$googlecheckout_url?analyticsdata='+getUrchinFieldValue();">
<img height=43 width=160 border=0 
	src="https://checkout.google.com/buttons/checkout.gif?merchant_id=[merchantid]&w=160&h=43&style=[style]&variant=[variant]&loc=en_US"
	></a>

_

## RESPONSE: ##
  * googleCheckoutMerchantId: 
  * URL: 
