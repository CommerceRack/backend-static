/* **************************************************************

   Copyright 2011 Zoovy, Inc.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

CHECOUT_PASSIVE.JS (just here to make it easier to know which extension is open)

************************************************************** */

var convertSessionToOrder = function() {
	var theseTemplates = new Array("productListTemplateCartSummary","checkoutSuccess","checkoutTemplateBillAddress","checkoutTemplateShipAddress","checkoutTemplateOrderNotesPanel","checkoutTemplateCartSummaryPanel","checkoutTemplateShipMethods","checkoutTemplatePayOptionsPanel","checkoutTemplate");
	var r = {
	vars : {
//which fieldset is currently in focus.
		focusFieldset : '',
		willFetchMyOwnTemplates : true,
		containerID : '',
//used to both generate and validate the echeck fields.
		echeck : {
			"payment.ea" : "Account #",
			"payment.er" : "Routing #",
			"payment.en" : "Account Name",
			"payment.eb" : "Bank Name",
			"payment.es" : "Bank State",
			"payment.ei" : "Check #"
			},
		legends : {
			"chkoutBillAddress" : "Billing Address",
			"chkoutShipAddress" : "Shipping Address",
			"chkoutShipMethods" : "Shipping Options",
			"chkoutPayOptions" : "Payment Choices",
			"chkoutOrderNotes" : "Order Notes"
			},
//though most extensions don't have the templates specified, checkout does because so much of the code is specific to these templates.
		templates : theseTemplates
		},

					////////////////////////////////////   CALLS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\		

/*
unlike other extensions, checkout calls rarely do a 'fetchData'. The thought here is to make sure we always have the most recent data.
calls should always return the number of dispatches needed. allows for cancelling a dispatchThis if not needed.
   so in most of these, a hard return of 1 is set.

initially, this extension auto-executed. Later, after callbacks were added to the extension object
the startCheckout call was added, which contains the code that was auto-executed as part of the INIT callback.
a callback was also added which just executes this call, so that checkout COULD be auto-started onload.
*/
	calls : {
	
//only run this once, unless the user leaves checkout and comes back.
//if the form needs to be reloaded. use the showCheckoutForm call.
//this call doesn't actually make a call, it executes another. more recycling that way.
//this call also forces a dispatch, which is abnormal.
// #### make this an action at somepoint.
		startCheckout : {
			init : function(containerID)	{
				var r = 0;
//generates the checkout container div and FORM.
//formerly hardcoded to zContent
				myControl.ext.convertSessionToOrder.vars.containerID = containerID;
				$('#'+containerID).append(myControl.renderFunctions.createTemplateInstance('checkoutTemplate','zCheckoutContainer'));

//paypal code need to be in this startCheckout and not showCheckoutForm so that showCheckoutForm can be 
// executed w/out triggering the paypal code (which happens when payment method switches FROM paypal to some other method) because
// the paypalgetdetails cmd only needs to be executed once per session UNLESS the cart contents change.
				var token = myControl.util.getParameterByName('token');
				var payerid = myControl.util.getParameterByName('PayerID');
				if(token && payerid)	{
					r += myControl.calls.cartSet.init({'payment-pt':token,'payment-pi':payerid});
					r += myControl.ext.store_checkout.calls.cartPaypalGetExpressCheckoutDetails.init({'token':token,'payerid':payerid});
					}
				else	{
//if token and/or payerid is NOT set on URI, then this is either not yet a paypal order OR is/was paypal and user left checkout and has returned.
//need to reset paypal vars in case cart/session was manipulated.
// ### NOTE - in an all RIA environment, this isnt needed. the add to cart functions should do this. however, in a hybrid (1PC) it is needed.
					myControl.ext.store_checkout.util.nukePayPalEC();
					}

//inital render is just a container, so no data is needed.
				myControl.renderFunctions.translateTemplate({},'zCheckoutContainer');

				r += myControl.ext.convertSessionToOrder.calls.showCheckoutForm.init();
				myControl.model.dispatchThis("immutable");

// even in passive, this field is needed. Can be set to zero out of the gate. API will return error if not present.
				if(myControl.ext.store_checkout.util.determineAuthentication() == 'authenticated')	{
					myControl.util.dump(" -> user is logged in. set account creation hidden input to 0");
					$('#chkout-create_customer').val(0);
					}

				_gaq.push(['_trackEvent','Checkout','App Event','Checkout Initiated']);

				return r; 
				}			
			},
		


//used to save all the populated checkout fields to the cart. 
		saveCheckoutFields : {
			init : function(callback)	{
				this.dispatch(callback);
				return 1;
				},
			dispatch : function(callback)	{
				myControl.calls.cartSet.init($('#zCheckoutFrm').serializeJSON()); //adds dispatches.
				}
			}, //saveCheckoutFields

		showCheckoutForm : {
			init : function()	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.calls.showCheckoutForm.init');
				$('#chkoutSummaryErrors').empty(); //clear any existing global errors.
				return this.dispatch(); //at least 5 calls will be made here. maybe 6.
				},
			dispatch : function()	{
//r is set to 5 because five of these calls are fixed.
//yes, I could have done a += for each call, but since they're also a guaranteed request, just hard code this. It'll be faster and can always be changed later.
				var r = 5;  
//Do inventory check if inventory matters.
//multiple inv_mode by 1 to treat as number
				if((zGlobals.globalSettings.inv_mode * 1) > 0)	{ 
					r += myControl.ext.store_checkout.calls.cartItemsInventoryVerify.init("handleInventoryUpdate");
					}
				myControl.ext.store_checkout.calls.appPaymentMethods.init();
//only send the request for addresses if the user is logged in or the request will return an error.
				if(myControl.ext.store_checkout.util.determineAuthentication() == 'authenticated')	{
					myControl.ext.store_checkout.calls.buyerAddressList.init();
					}
				myControl.ext.store_checkout.calls.appCheckoutDestinations.init();
				myControl.ext.store_checkout.calls.cartShippingMethodsWithUpdate.init();
				myControl.calls.refreshCart.init({"callback":"loadPanelContent","extension":"convertSessionToOrder"},'immutable');
				return r;
				}
			}, //showCheckoutForm



// formerly updateCartQty
		cartItemUpdate : {
			init : function(stid,qty,tagObj)	{
				myControl.util.dump('BEGIN myControl.ext.store_cart.calls.cartItemUpdate.');
				tagObj = $.isEmptyObject(tagObj) ? {} : tagObj;
				var r = 0;
				if(!stid || isNaN(qty))	{
					myControl.util.dump(" -> cartItemUpdate requires both a stid ("+stid+") and a quantity as a number("+qty+")");
					}
				else	{
					r = 1;
					this.dispatch(stid,qty,tagObj);
					}
				return r;
				},
			dispatch : function(stid,qty,tagObj)	{
//				myControl.util.dump(' -> adding to PDQ. callback = '+callback)
				myControl.model.addDispatchToQ({"_cmd":"updateCart","stid":stid,"quantity":qty,"_zjsid":myControl.sessionId,"_tag": tagObj},'immutable');
				myControl.ext.store_checkout.util.nukePayPalEC(); //require paypal re-authentication anytime the cart is updated.
				}
			 },

			
/*
Run once checkout form has been filled out (or is thought to be filled out).
add all form fields to the session/cart (whether form validates or not)
 -> thought being to collect and store all that information as often as possible.
does a client-side validation of the form.
 -> if errors, they're displayed on screen as part of the individual panel validation scripts.
 -> if success, server-side validation takes place. those errors are handled in the callback (if present).
if server validation passes, the callback handles what to do next (callback is most likely "finishedValidatingCheckout")
*/
		processCheckout : {
			init : function(callback)	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.calls.processCheckout.init');

				$('#chkoutSummaryErrors').empty(); //clear any existing global errors. //blank out any existing global errors so that only new error appear.
				$('#chkoutPlaceOrderBtn').attr('disabled','disabled').addClass('ui-state-disabled loadingButtonBg'); //disable the button to avoid double-click.
//				return; //die here to test
				var checkoutIsValid = myControl.ext.convertSessionToOrder.validate.isValid();
				
			
				myControl.util.dump(' -> checkoutIsValid = '+checkoutIsValid);
//adds dispatches regardless of validation.
				var serializedCheckout = $('#zCheckoutFrm').serializeJSON()
//for security reasons, cc info is removed from cart/session update if the local validation isn't successful.
//they are saved in memory for panel updates. if a user leaves checkout and comes back, cc info will have to be re-entered.
				if(!checkoutIsValid)	{
					serializedCheckout['payment.cc'] = '';
					serializedCheckout['payment.cv'] = '';
					}
//				myControl.util.dump(' -> SANITIZED serialized checkout object: ');
//				myControl.util.dump(serializedCheckout);
				myControl.calls.cartSet.init(serializedCheckout);
				if(checkoutIsValid)	{
					this.dispatch(callback);
					myControl.util.dump(" -> Got to valid checkout and adding to dispatchQ.");
					}
				else	{
//					myControl.util.dump(' -> validation failed.');
//originally, instead of attr(disabled,false) i removed the disabled attribute. This didn't work in ios 5 safari.					
					$('#chkoutPlaceOrderBtn').attr('disabled',false).removeClass('ui-state-disabled').removeClass('loadingButtonBg');
					
//without this jump, the create order button jumps up slightly. 
//this needs to be at the end so all the content above is manipulated BEFORE jumping to the id. otherwise, the up-jump still occurs.
				myControl.util.jumpToAnchor('chkoutSummaryErrors');
					
//space separating two classes in remove class didn't play well with ipad.
					}



_gaq.push(['_trackEvent','Checkout','User Event','Create order button pushed (validated = '+checkoutIsValid+')']);
				
				return 1;
				},
			dispatch : function(callback)	{
				myControl.model.addDispatchToQ({"_cmd":"cartCheckoutValidate","_tag" : {"callback":callback,"extension":"convertSessionToOrder"}},'immutable');
				}
			}
	

		}, //calls









					////////////////////////////////////   CALLBACKS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\









	callbacks : {
//callbacks.init need to return either a true or a false, depending on whether or not the file will execute properly based on store account configuration.
		init : {
			onSuccess : function()	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.init.onSuccess');
				var r; //returns false if checkout can't load due to account config conflict.
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.init.onSuccess');
//start this process as early as possible. Errors will be reported independantly of init (result of ajax req. for templates).
				myControl.model.fetchNLoadTemplates('extensions/checkout_passive/templates.html',theseTemplates);

				if(!zGlobals || $.isEmptyObject(zGlobals.checkoutSettings))	{
					$('#globalMessaging').toggle(true).append(myControl.util.formatMessage({'message':'<strong>Uh Oh!<\/strong> It appears an error occured. Please try again. If error persists, please contact the site administrator.','uiClass':'error','uiIcon':'alert'}));
					r = false;
					}
//store configuration is set to require login, which this version of checkout is not compatible with this version of checkout.
				else if(zGlobals.checkoutSettings.preference_require_login == 1)	{
					myControl.util.dump(" -> zGlobals.checkoutSettings.preference_require_login == 1");
					$('#globalMessaging').toggle(true).append(myControl.util.formatMessage({'message':'<strong>Uh Oh!<\/strong> There appears to be an issue with the store configuration. Please change your checkout setting to \'passive\' if you wish to use this layout.','uiClass':'error','uiIcon':'alert'}));
					r = false;
					}
//user's store setting is set to request a login, which is not compatible with this version of checkout.
				else if(zGlobals.checkoutSettings.preference_request_login == 1)	{
					myControl.util.dump(" -> zGlobals.checkoutSettings.preference_request_login == 1");
					$('#globalMessaging').toggle(true).append(myControl.util.formatMessage({'message':'<strong>Uh Oh!<\/strong> There appears to be an issue with the store configuration. Please change your checkout setting to \'passive\' if you wish to use this layout.','uiClass':'error','uiIcon':'alert'}));
					r = false;
					}
				else if(typeof _gaq === 'undefined')	{
					myControl.util.dump(" -> _gaq is undefined");
					$('#globalMessaging').toggle(true).append(myControl.util.formatMessage({'message':'<strong>Uh Oh!<\/strong> It appears you are not using the Asynchronous version of Google Analytics. It is required to use this checkout.','uiClass':'error','uiIcon':'alert'}));
					r = false;					
					}
//messaging for the test harness 'success'.
				else if(myControl.util.getParameterByName('_testharness'))	{
					$('#globalMessaging').toggle(true).append(myControl.util.formatMessage({'message':'<strong>Excellent!<\/strong> Your store meets the requirements to use this one page checkout extension.','uiIcon':'circle-check','uiClass':'success'}));
					$('#'+myControl.ext.convertSessionToOrder.vars.containerID).removeClass('loadingBG').append("");
					}
				else	{
					r = true;
					}

				if(r == false)	{
//execute error handling for the extension.
//errors are reported to the screen, but 'other' actions may need to be taken.
					this.onError();
					}

				return r;
//				myControl.util.dump('END myControl.ext.convertSessionToOrder.init.onSuccess');
				},
			onError : function()	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.init.error');
				//This would be reached if a templates was not defined in the view.
				$('#'+myControl.ext.convertSessionToOrder.vars.containerID).removeClass('loadingBG');
				}
			}, //init


//SET THIS AS THE CALLBACK ON THE EXTENSION LOADER IF YOU WANT TO IMMEDIATELY START CHECKOUT
		startCheckout : {
			onSuccess : function() {
				myControl.ext.convertSessionToOrder.calls.startCheckout.init('mainContentArea');
				},
			onError : function() {
//to get here, something catastrophic would have happened and other error messaging would have handled it.
				}
			},

		updateCheckoutShipMethods : {
			onSuccess : function(tagObj)	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.updateCheckoutShipMethods.success');
				myControl.ext.convertSessionToOrder.panelContent.shipMethods();
				},
			onError : function(d)	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.updateCheckoutShipMethods.onError - ERROR!');
				myControl.ext.convertSessionToOrder.panelContent.shipMethods(); //reload ship panel or just error shows and there is no way to continue.
				$('#chkoutShipMethodsFieldsetErrors').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			},


		
		
		proceedToGoogleCheckout : {
			onSuccess : function(tagObj)	{
				myControl.util.dump('BEGIN convertSessionToOrder[passive].callbacks.proceedToGoogleCheckout.onSuccess');
				_gaq.push(function() {
					var pageTracker = _gaq._getAsyncTracker();
					setUrchinInputCode(pageTracker);
					});
//				alert(myControl.data[tagObj.datapointer].URL+"?analyticsdata="+getUrchinFieldValue());
				document.location= myControl.data[tagObj.datapointer].URL+"&analyticsdata="+getUrchinFieldValue();
				},
			onError : function(responseData,uuid)	{
				$('#chkoutPlaceOrderBtn').removeAttr('disabled').removeClass('ui-state-disabled'); // re-enable checkout button on checkout page.
				myControl.util.handleErrors(responseData,uuid);
				}
			},



		handleCartPaypalSetECResponse : {
			onSuccess : function(tagObj)	{
				myControl.util.dump('BEGIN convertSessionToOrder[nice].callbacks.handleCartPaypalSetECResponse.onSuccess');
				window.location = myControl.data[tagObj.datapointer].URL
				},
			onError : function(responseData,uuid)	{
				$('#chkoutPlaceOrderBtn').removeAttr('disabled').removeClass('ui-state-disabled'); // re-enable checkout button on cart page.
				myControl.util.handleErrors(responseData,uuid);
				}
			},

//mostly used for the error handling.
		handleCartPaypalGetECDetails : {
			onSuccess : function(tagObj)	{
//				myControl.util.dump('BEGIN convertSessionToOrder[nice].callbacks.handleCartPaypalGetECDetails.onSuccess');
//do NOT execute handlePaypalFormManipulation here. It's run in panel view.
				},
			onError : function(responseData,uuid)	{
				myControl.util.handleErrors(responseData,uuid);
//nuke vars so user MUST go thru paypal again or choose another method.
//nuke local copy right away too so that any cart logic executed prior to dispatch completing is up to date.

				myControl.ext.store_checkout.util.nukePayPalEC();
				myControl.calls.refreshCart.init({},'immutable');
				myControl.model.dispatchThis('immutable');
//### for expediency. this is a set timeout. Need to get this into the proper sequence. needed a quick fix for a production bug tho
				setTimeout("$('#paybySupplemental_PAYPALEC').empty().addClass('ui-state-highlight').append(\"It appears something went wrong with PayPal. Please <a href='#' onClick='myControl.ext.convertSessionToOrder.util.handleChangeFromPayPalEC();'>Click Here</a> to choose an alternate payment method.\")",2000);
				}
			},		


	
		addGiftcardToCart : {
			onSuccess : function(tagObj)	{
				myControl.util.dump('got to addGiftcardToCart success');
//after a gift card is entered, update the payment panel as well as the cart/invoice panel.
				myControl.ext.convertSessionToOrder.panelContent.cartContents();
				myControl.ext.convertSessionToOrder.panelContent.paymentOptions();

				$('#giftcardMessaging').empty().append(myControl.util.formatMessage({'message':'Your gift card has been added. Your cart summary has been updated.','uiIcon':'check','htmlid':'giftcardSuccessMessage','timeoutFunction':"$('#giftcardSuccessMessage').slideUp(1000);"}));

_gaq.push(['_trackEvent','Checkout','User Event','Cart updated - giftcard added']);



				},
			onError : function(d)	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.addGiftcardToCart.onError - ERROR!');
				myControl.ext.convertSessionToOrder.panelContent.paymentOptions(); //regenerate the panel. need to show something or no payments can be selected.
				$('#chkoutPayOptionsFieldsetErrors').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			},//addGiftcardToCart




			
		addCouponToCart : {
			onSuccess : function(tagObj)	{
				myControl.util.dump('BEGIN control.ext.convertSessionToOrder.callbacks.addcouponToCart.onSuccess');
				$('#addCouponBtn').removeAttr('disabled').removeClass('ui-state-disabled').removeClass('loadingButtonBg');
//after a gift card or coupon is entered, update the cart/invoice panel.
				$('#couponMessaging').empty().toggle(true).append(myControl.util.formatMessage({'message':'Your coupon has been added.','uiClass':'success','uiIcon':'check','htmlid':'couponSuccessMessage','timeoutFunction':"$('#couponSuccessMessage').slideUp(1000);"}));

_gaq.push(['_trackEvent','Checkout','User Event','Cart updated - coupon added']);


				},
			onError : function(d)	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.addcouponToCart.onError');
				$('#addCouponBtn').removeAttr('disabled').removeClass('ui-state-disabled').removeClass('loadingButtonBg');
				$('#couponMessaging').empty().toggle(true).append(myControl.util.getResponseErrors(d));
				}
			},//addcouponToCart




//executing this will not only return which items have had an inventory update (in a pretty format) but also create the dispatches
// to update the cart and then to actually update it as well.
// the individual cart update posts (there may be multiple) go without the callback. If callback is added, a ping to execute it is run.
		handleInventoryUpdate : {

				onSuccess : function(tagObj)	{

//					myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.handleInventoryUpdate.onSuccess');
					var r = false; //if false is returned, then no inventory update occured.
	//				var L = myControl.model.countProperties(myControl.data[tagObj.datapointer]);
					if(!$.isEmptyObject(myControl.data[tagObj.datapointer]) && !$.isEmptyObject(myControl.data[tagObj.datapointer]['%changes']))	{
						myControl.util.dump(' -> adjustments are present');
						r = "<div id='inventoryErrors'>It appears that some inventory adjustments needed to be made:<ul>";
						for(var key in myControl.data[tagObj.datapointer]['%changes']) {
							r += "<li>sku: "+key+" was set to "+myControl.data[tagObj.datapointer]['%changes'][key]+" due to availability<\/li>";
							myControl.ext.convertSessionToOrder.calls.cartItemUpdate.init({"stid":key,"quantity":myControl.data[tagObj.datapointer]['%changes'][key]});
							}
						r += "<\/ul><\/div>";
						
						
						$('#globalMessaging').toggle(true).append(myControl.util.formatMessage({'message':r,'uiIcon':'alert'}));

						}


_gaq.push(['_trackEvent','Checkout','App Event','Cart updated - inventory adjusted to reflect availability']);

					return r;
					
					},
				onError : function(d)	{
					myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.handleInventoryUpdate.onError - ERROR!');
					myControl.ext.convertSessionToOrder.panelContent.paymentOptions();
//global errors are emptied when 'complete order' is pushed, so do not empty in the responses or any other errors will be lost.
					$('#globalMessaging').append(myControl.util.getResponseErrors(d)).toggle(true);
					}
				},	//handleInventoryUpdate


		updateCheckoutPayOptions : {
			onSuccess : function(tagObj)	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.updateCheckoutPayOptions.success');
				myControl.ext.convertSessionToOrder.panelContent.paymentOptions();
				},
			onError : function(d)	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.updateCheckoutPayOptions.onError - ERROR!');
				myControl.ext.convertSessionToOrder.panelContent.paymentOptions();  //reload panel or just error shows and user can't proceed.
				$('#chkoutPayOptionsFieldsetErrors').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			},

		updateCheckoutOrderContents : {
			onSuccess : function(){
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.updateCheckoutOrderContents.success (updating cart panel)');
				myControl.ext.convertSessionToOrder.panelContent.cartContents();
				},
			onError : function(d)	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.updateCheckoutOrderContents.onError - ERROR!');
				myControl.ext.convertSessionToOrder.panelContent.cartContents();  //reload panel so more than just error shows up and user can proceed/try again.
				$('#chkoutSummaryErrors').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			},
/*
this gets executed after the server side validating is run.
success would mean the checkout has successfully validated.
error would mean something was not complete. 
 -> In theory, we shouldn't get errors often because the client side validation should handle most, if not all, errors.
*/
		finishedValidatingCheckout : {
			onSuccess : function(tagObj)	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.finishedValidatingCheckout.onSuccess');
//if paypal is selected but a valid token doesn't exist, route to paypal.
				if($("#chkout-payby_PAYPALEC").is(':checked') && !myControl.data.cartItemsList.cart['payment-pt'])	{
					myControl.ext.store_checkout.calls.cartPaypalSetExpressCheckout.init();
					}
				else	{
					myControl.ext.store_checkout.calls.cartOrderCreate.init("checkoutSuccess");
					}
				myControl.model.dispatchThis('immutable');


_gaq.push(['_trackEvent','Checkout','App Event','Server side validation passed']);


				},
			onError : function(responseData,uuid)	{
				$('#chkoutPlaceOrderBtn').removeAttr('disabled').removeClass('ui-state-disabled loadingButtonBg'); //make place order button appear and be clickable.
				responseData['_rtag'] = $.isEmptyObject(responseData['_rtag']) ? {} : responseData['_rtag'];
				responseData['_rtag'].targetID = 'chkoutSummaryErrors';
				myControl.ext.store_checkout.util.showServerErrors(responseData,uuid);
				
_gaq.push(['_trackEvent','Checkout','App Event','Server side validation failed']);


				}
			},


		loadPanelContent : {
			onSuccess : function(tagObj)	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.loadPanelContent.onSuccess');

//had some issues using length. these may have been due to localStorage/expired cart issue. countProperties is more reliable though, so still using that one.			
				var stuffCount = myControl.model.countProperties(myControl.data.cartItemsList.cart.stuff);
//				myControl.util.dump('stuff util.countProperties = '+stuffCount+' and typeof = '+typeof stuffCount);


				if(stuffCount > 0)	{
					
//						myControl.util.dump(' -> authentication passed. Showing panels.');
//						myControl.util.dump(' -> chkout.bill_to_ship = '+myControl.data.cartItemsList.cart['chkout.bill_to_ship']);
//create panels. notes and ship address are hidden by default.
//ship address will make itself visible if user is authenticated.
					myControl.ext.convertSessionToOrder.util.handlePanel('chkoutBillAddress');

//bill to ship will be set to zero if user has disabled it, otherwise it will be 1 or undef.
					myControl.ext.convertSessionToOrder.util.handlePanel('chkoutShipAddress',Number(myControl.data.cartItemsList.cart['chkout.bill_to_ship']) == 0 ? false : true)

					myControl.ext.convertSessionToOrder.util.handlePanel('chkoutShipMethods'); 
					myControl.ext.convertSessionToOrder.util.handlePanel('chkoutPayOptions');
					myControl.ext.convertSessionToOrder.util.handlePanel('chkoutOrderNotes',true);						
//populate panels.						
					myControl.ext.convertSessionToOrder.panelContent.cartContents();
					myControl.ext.convertSessionToOrder.panelContent.billAddress();

					myControl.ext.convertSessionToOrder.panelContent.shipAddress();
					myControl.ext.convertSessionToOrder.panelContent.shipMethods();
					myControl.ext.convertSessionToOrder.panelContent.paymentOptions();
//if order notes is on, show panel and populate content.
					if(zGlobals.checkoutSettings.chkout_order_notes == true)	{
						myControl.ext.convertSessionToOrder.panelContent.orderNotes();
						$('#chkoutOrderNotes').toggle(true); 
						}
						

_gaq.push(['_trackEvent','Checkout','Milestone','Valid email address obtained']);


					}//ends 'if' for whether cart has more than zero items in it.
				else	{
					myControl.ext.convertSessionToOrder.util.cartIsEmptyWarning();
					}
				$('#'+myControl.ext.convertSessionToOrder.vars.containerID).removeClass('loadingBG');
				
//will lock many input fields so they match the paypal response (ship address, shipping, etc).
//needs to executed in here instead of in a callback for the payalget because the get is only run once per cart/session (unless cart is changed)
//but checkout may get load/reloaded and if the cart hasn't changed, the forms still need to be 'locked'.
//needs to run at the end here so that all the dom manipulating is done prior so function can 'lock' fields
				if(myControl.ext.store_checkout.util.thisSessionIsPayPal())	{
					myControl.ext.store_checkout.util.handlePaypalFormManipulation();
					}

				
				},
			onError : function(d)	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.loadPanelContent.onError.');
				$('#globalMessaging').append({"message":"It appears something has gone very wrong. Please try again. If error persists, please contact the site administrator.","uiClass":"error","uiIcon":"alert"})
				$('#globalMessaging').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			
			},//loadPanelContent

/*
this callback is executed after a successful checkout.  'success' is defined as an order created, the order may contain 'payment required' warnings.
this is what would traditionally be called an 'invoice' page, but certainly not limited to just showing the invoice.
*/
		checkoutSuccess : {
			onSuccess : function(tagObj)	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.checkoutSuccess.onSuccess   datapointer = '+tagObj.datapointer);
//empty old form content. not needed anymore. gets replaced with invoice-ish content.
				var $zContent = $('#'+myControl.ext.convertSessionToOrder.vars.containerID).empty();
				var oldSession = myControl.sessionId;
				var orderID = myControl.data[tagObj.datapointer].orderid;

				myControl.util.jumpToAnchor(myControl.ext.convertSessionToOrder.vars.containerID);
//this generates the post-checkout message from the template in the view file.
				$zContent.append(myControl.renderFunctions.createTemplateInstance('checkoutSuccess','checkoutSuccessContent')); 
				myControl.renderFunctions.translateTemplate(myControl.data[tagObj.datapointer],'checkoutSuccessContent');
// ### test this before switching back.
//				$zContent.append(myControl.renderFunctions.transmogrify('checkoutSuccess','checkoutSuccessContent',myControl.data[tagObj.datapointer]))

/*
right now, we're just displaying the payment_status_detail message.  
eventually, it will check the status and do better handling of the response.
the checkoutSuccessPaymentFailure started to do this but for the sake of getting this out, we improvised. ###
*/
				$('.paymentRequired').append(myControl.data[tagObj.datapointer].payment_status_detail);

//				$('.paymentRequired').append(myControl.ext.store_checkout.util.checkoutSuccessPaymentFailure(myControl.data[tagObj.datapointer].payment_success,myControl.data['order|'+orderID].cart['chkout.payby']));
				
				
				
				var cartContentsAsLinks = encodeURI(myControl.ext.store_checkout.util.cartContentsAsLinks('order|'+orderID))
				
				$('.ocmTwitterComment').click(function(){
					window.open('http://twitter.com/home?status='+cartContentsAsLinks,'twitter');
					_gaq.push(['_trackEvent','Checkout','User Event','Tweeted about order']);
					});
//the fb code only works if an appID is set, so don't show banner if not present.				
				if(zGlobals.thirdParty.facebook.appId)	{
					$('.ocmFacebookComment').click(function(){
						myControl.thirdParty.fb.postToWall(cartContentsAsLinks);
						_gaq.push(['_trackEvent','Checkout','User Event','FB message about order']);
						});
					}
				else	{$('.ocmFacebookComment').addClass('displayNone')}

				myControl.calls.appCartCreate.init(); //!IMPORTANT! after the order is created, a new cart needs to be created and used. the old cart id is no longer valid. 
				myControl.calls.refreshCart.init({},'immutable'); //!IMPORTANT! will reset local cart object. 
				myControl.model.dispatchThis('immutable'); //these are auto-dispatched because they're essential.
				


_gaq.push(['_trackEvent','Checkout','App Event','Order created']);
_gaq.push(['_trackEvent','Checkout','User Event','Order created ('+orderID+')']);

//add the html roi to the dom. this likely includes tracking scripts. LAST in case script breaks something.
setTimeout("$('#"+myControl.ext.convertSessionToOrder.vars.containerID+"').append(myControl.data['"+tagObj.datapointer+"']['html:roi']); myControl.util.dump('wrote html:roi to DOM.');",2000); 

				},
			onError : function(responseData,uuid)	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.callbacks.checkoutSuccess.onError');
				$('#chkoutPlaceOrderBtn').removeAttr('disabled').removeClass('ui-state-disabled loadingButtonBg'); //make place order button appear and be clickable.
				
				responseData['_rtag'] = $.isEmptyObject(responseData['_rtag']) ? {} : responseData['_rtag'];
				responseData['_rtag'].targetID = 'chkoutSummaryErrors';
				myControl.ext.store_checkout.util.showServerErrors(responseData,uuid);
				
_gaq.push(['_trackEvent','Checkout','App Event','Order NOT created. error occured. ('+responseData['_msg_1_id']+')']);

				}
			}

		}, //callbacks





////////////////////////////////////   						validation				    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\




	validate : {
			
 

//runs individual panel/fieldset validation and returns whether or not all checkout fields are populated/valid.
//the individual fieldset validator returns a 1/0 depending on whether it passes/fails the validation.
//order notes is NOT validated
//there are six validated fields, so summing up the values will = 6 if all panels pass.
			isValid : function()	{
				var $globalErrors = $('#chkoutSummaryErrors').empty().toggle(false);
				var r = true;
				var sum = 0;
				sum += this.chkoutShipMethodsFieldset(); //myControl.util.dump('ship methods done. sum = '+sum);
				sum += this.chkoutPayOptionsFieldset(); //myControl.util.dump('pay options done. sum = '+sum);
				sum += this.chkoutBillAddressFieldset(); //myControl.util.dump('bill address done. sum = '+sum);
				sum += this.chkoutShipAddressFieldset(); //myControl.util.dump('ship address done. sum = '+sum);

//				myControl.util.dump('END myControl.ext.convertSessionToOrder.validate.isValid. sum = '+sum);
				if(sum != 4)	{
					r = false;
					$globalErrors.append(myControl.util.formatMessage({"message":"Some required fields were left blank or contained errors. (please scroll up)","uiClass":"error","uiIcon":"alert"})).toggle(true);
					}
//				r = true; //for testing error handling. do not deploy with this line uncommented.
				return r;
				}, //isValid
//validation function should be named the same as the id of the fieldset. 



//no validation occurs here by default, but function exists so it can be overridden AND because there's some automated scripting which validates each panel as the user moves on.
			chkoutOrderNotesFieldset : function()	{
				
				},


				
//make sure a shipping method is selected
			chkoutShipMethodsFieldset : function()	{
				var valid = 1;
				var $shipMethod = $("[name='ship.selected_id']:checked");
				$('#chkoutShipMethodsFieldsetErrors').empty().toggle(false);
				if($shipMethod.val())	{
//					myControl.util.dump(' -> ship method validated');
					$('#chkoutShipMethodsFieldset').addClass('validatedFieldset');
					}
				else	{
					valid = 0;
					$('#chkoutShipMethodsFieldsetErrors').toggle(true).append(myControl.util.formatMessage("Please select a shipping method."));
					$('#chkoutShipMethodsFieldset').removeClass('validatedFieldset');
					}
				if(valid == 1)	{


_gaq.push(['_trackEvent','Checkout','Milestone','Shipping method validated']);


					}
				return valid;
				}, //validate.chkoutShipMethodsFieldset
				
//in addition to selecting a pay option, certain extra fields may be present and must be checked for.
			chkoutPayOptionsFieldset : function()	{
				var valid = 1;
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.validate.chkoutPayOptionsFieldset');
				var $payMethod = $("[name='chkout.payby']:checked");
				var $errorDiv = $('#chkoutPayOptionsFieldsetErrors').empty().toggle(false);
				var errMsg = '';
				var safeid,$holder;
				if($payMethod.val())	{
					switch($payMethod.val())	{
						
						case 'CREDIT':
							var $paymentCC = $('#payment-cc').removeClass('mandatory');
							var $paymentMM = $('#payment-mm').removeClass('mandatory');
							var $paymentYY = $('#payment-yy').removeClass('mandatory');
							var $paymentCV = $('#payment-cv').removeClass('mandatory');
							if(!myControl.util.isValidCC($paymentCC.val())){$paymentCC.parent().addClass('mandatory'); valid = 0; errMsg += '<li>please enter a valid credit card #<\/li>'}
							if(!myControl.util.isValidMonth($paymentMM.val())){$paymentMM.parent().addClass('mandatory'); valid = 0; errMsg += '<li>please select an exipration month<\/li>'}
							if(!myControl.util.isValidCCYear($paymentYY.val())){$paymentYY.parent().addClass('mandatory'); valid = 0; errMsg += '<li>please select an expiration year<\/li>'}
							if($paymentCV.val().length < 3){$paymentCV.parent().addClass('mandatory'); valid = 0; errMsg += '<li>please enter a cvv/cid #<\/li>'}
							break;
						
						case 'ECHECK':
							for(var key in myControl.ext.convertSessionToOrder.vars.echeck) {
								$holder = $('#'+myControl.util.makeSafeHTMLId(key)).removeClass('mandatory');
								if(!$holder.val())	{
									$holder.parent().addClass('mandatory');
									valid = 0;
									errMsg += '<li>please enter a '+myControl.ext.convertSessionToOrder.vars.echeck[key]+'<\/li>'
									}
								}
							break;
						
						case 'PO':
							var $paymentPO = $('#payment-po').removeClass('mandatory');
							if(!myControl.util.isSet($paymentPO.val())){$paymentPO.parent().addClass('mandatory'); valid = 0; errMsg += '<li>please enter a PO #<\/li>'}
							break;
							
						default:
							break;
						}
//the errors above get put into a list with a header. handles multiple errors (like CC, potentially) more nicely.
					errMsg = "Some required fields are missing/invalid:<ul>"+errMsg+"<\/ul>"
					}
				else	{
					valid = 0;
					errMsg = 'please select a payment method';
					}

				if(valid == 0){
					$('#chkoutPayOptionsFieldset').removeClass('validatedFieldset');
//					myControl.util.dump(' -> payment options did not pass validation');
					$errorDiv.toggle(true).append(myControl.util.formatMessage(errMsg));
					}
				else{
//					myControl.util.dump(' -> payment options passed validation');
					$('#chkoutPayOptionsFieldset').addClass('validatedFieldset');



_gaq.push(['_trackEvent','Checkout','Milestone','Payment method validated ('+$payMethod.val()+')']);



					}
//				myControl.util.dump('END myControl.ext.convertSessionToOrder.validate.chkoutPayOptionsFieldset. paymethod = '+$payMethod.val()+' and valid = '+valid);
				return valid;
				}, //chkoutPayOptionsFieldset
				
			chkoutBillAddressFieldset: function()	{
				var valid = 1;
				var r = true;
				$('#chkoutBillAddressFieldsetErrors').empty().toggle(false);
				$('#chkoutBillAddressFieldset .mandatory').removeClass('mandatory');
//all of the address validation logic is in this function. that way we can recycle for ship/bill address
				r = this.addressIsPopulated('bill'); 

				if(r)	{
					$('#chkoutBillAddressFieldset').addClass('validatedFieldset');
					}
				else	{
					valid = 0;
					$('#chkoutBillAddressFieldsetErrors').append(myControl.util.formatMessage("Some required fields were left blank or are invalid")).toggle(true);
					$('#chkoutBillAddressFieldset').removeClass('validatedFieldset');
/*
sometimes, a preexisting address may be selected but not have all required fields.
in this case, toggle the address entry form on so that the corrections can be made in an obvious manner.
*/
					$("#billAddressUL").toggle(true);
					}
				if(valid == 1)	{

_gaq.push(['_trackEvent','Checkout','Milestone','billing address obtained']);

					}
				return valid;
				}, //chkoutBillAddressFieldset
				
			chkoutShipAddressFieldset : function()	{
				var valid = 1;
				var r = true;
				$('#chkoutShipAddressFieldsetErrors').empty().toggle(false);
				$('#chkoutShipAddressFieldset .mandatory').removeClass('mandatory');
//copy all the billing address fields to the shipping address fields, if appropriate. if so, don't bother validating.
				if($('#chkout-bill_to_ship_cb').is(':checked')) {
					myControl.ext.store_checkout.util.setShipAddressToBillAddress();
					}
				else	{
					r = this.addressIsPopulated('ship');
					}

				if(r)	{
					$('#chkoutShipAddressFieldset').addClass('validatedFieldset');
					}
				else	{
					valid = 0;
					$('#chkoutShipAddressFieldsetErrors').append(myControl.util.formatMessage("Some required fields were left blank or are invalid")).toggle(true);
					$('#chkoutShipAddressFieldset').removeClass('validatedFieldset');
/*
sometimes, a preexisting address may be selected but not have all required fields.
in this case, toggle the address entry form on so that the corrections can be made in an obvious manner.
*/
					$("#shipAddressUL").toggle(true);
					}
				if(valid == 1)	{

_gaq.push(['_trackEvent','Checkout','Milestone','shipping address obtained']);

					}
				return valid;
				},
//type = ship or bill. will validate the respective address entered in checkout.
			addressIsPopulated : function(TYPE)	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.validate.address');
//				myControl.util.dump(' -> TYPE = '+TYPE);
				var r = true;
//errordiv is specific to the type. 
				var $errorDiv = TYPE=="bill" ? $('#chkoutBillAddressFieldsetErrors') : $('#chkoutShipAddressFieldsetErrors');
				var $firstName = $('#data-'+TYPE+'_firstname').removeClass('mandatory');
				var $lastName = $('#data-'+TYPE+'_lastname').removeClass('mandatory');
				var $address1 = $('#data-'+TYPE+'_address1').removeClass('mandatory');
				var $city = $('#data-'+TYPE+'_city').removeClass('mandatory');
				var $state = $('#data-'+TYPE+'_state').removeClass('mandatory');
				var $zip = $('#data-'+TYPE+'_zip').removeClass('mandatory');
				var $country = $('#data-'+TYPE+'_country').removeClass('mandatory');
				
				if($firstName.val().length < 2){$firstName.parent().addClass('mandatory'); r = false;}				
				if($lastName.val().length < 2){$lastName.parent().addClass('mandatory'); r = false;}
				if($address1.val().length < 2){$address1.parent().addClass('mandatory'); r = false;}
				if($city.val().length < 2){$city.parent().addClass('mandatory'); r = false;}
//state is only validated if country is US (not all countries have a state/province selection
				if($country.val() == 'US' && $state.val().length < 2)	{
					$state.parent().addClass('mandatory'); r = false;
					}
				
				if(TYPE=="bill")	{
					var $email = $('#data-bill_email');
					if($email.val() == '')	{
	//						myControl.util.dump(' -> email is blank');
						$email.parent().addClass('mandatory');
						$errorDiv.append(myControl.util.formatMessage("Please provide an email address")).toggle(true);
						myControl.ext.convertSessionToOrder.vars.validPreflight = 0;
						r = false;
						}
					else if(!myControl.util.isValidEmail($email.val()))	{
	//						myControl.util.dump(' -> email is not valid');
						$errorDiv.append(myControl.util.formatMessage("Please provide a valid email address")).toggle(true);
						$email.parent().addClass('mandatory');
						r = false;
						}
					
					}
				
				if(zGlobals.checkoutSettings.chkout_phone == 'REQUIRED'){
//					myControl.util.dump(' -> phone number IS required');
					var $phone = $('#data-'+TYPE+'_phone').removeClass('mandatory');
					if(myControl.util.isValidPhoneNumber($phone.val(),$country.val()) == true)	{
//						myControl.util.dump(' -> phone number IS valid');
						//don't override what r is already set to if this validates. only override if it DOESN'T validate.
						}
					else if(TYPE == 'ship' && ($('#data-bill_phone').val()))	{
						//set the shipping phone to the billing phone to expedite checkout.
							$phone.val($('#data-bill_phone').val())
						}
					else	{
//						myControl.util.dump(' -> phone number is NOT valid');
						$errorDiv.append(myControl.util.formatMessage("Please provide a valid phone number with area code."));
						$phone.parent().addClass('mandatory');
						r = false;
						}
					}
				
				
				if(!myControl.util.isValidPostalCode($zip.val(),$country.val())){$zip.parent().addClass('mandatory'); r = false;}
				return r;
				} //addressIsPopulated
			}, //validate
		


////////////////////////////////////   						panelContent			    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\





/*
each of these functions creates their respective panel. 
each panel is a fieldset, which is created in a call, then populated in a callback once the 
data sets have been received. Any time checkout is intiated, several requests are made to
make sure all the data is up to date (shipping options, inventory check, etc).

a given panel can update another, but should NOT contain code to modify another panel.
all logic should be in the panel itself. That'll make it easier to maintain.
 -> there is one exception to this. currently, 'ship to billing' will hide/unhide the shipping address panel instead of reloading it. 
 	this is handled differently because it's more efficient to just hide/unhide the panel then reload it each time.
*/ 
		panelContent : {

/*
a guest checkout gets just a standard address entry. 
an existing user gets a list of previous addresses they've used and an option to enter a new address.
*/
			billAddress : function()	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.panelContent.billAddress.  ');
				var data = myControl.data.cartItemsList.cart;
//				myControl.util.dump(data);
				var txt = '';
				var cssClass; //used to hide the form inputs if user is logged in and has predefined addresses. inputs are still generated so user can create a new address.
			 	var authState = myControl.ext.store_checkout.util.determineAuthentication();
				if(authState == 'authenticated' && myControl.ext.store_checkout.util.addressListOptions('bill') != false)	{
//					myControl.util.dump(" -> user is logged in AND has predefined billing address(es)");
					txt = "<span class='addressListPrompt'>Please choose from (click on) billing address(es) below:<\/span>";
					txt += myControl.ext.store_checkout.util.addressListOptions('bill'); // creates pre-defined address blocks.
					cssClass = 'displayNone';
					}
				
//troubleshooting IE issues, so saved to var instead of manipulating directly. may not need this, but test in IE if changed.
				var $panelFieldset = $("#chkoutBillAddressFieldset").removeClass("loadingBG").append("<p>"+txt+"<\/p>");
//				myControl.util.dump(" -> transmogrify billing address.");
				$panelFieldset.append(myControl.renderFunctions.transmogrify({'id':'billAddressUL'},'checkoutTemplateBillAddress',myControl.data.cartItemsList.cart))
				
				$('#billAddressUL').addClass(cssClass);

//update form elements based on cart object.
				if(authState == 'authenticated' && myControl.ext.store_checkout.util.addressListOptions('ship') != false)	{
//					myControl.util.dump(' -> user is logged in and has predefined shipping addresses so bill to ship not displayed.');
					$("#chkout-bill_to_ship_cb").removeAttr("checked");
					$("#chkout-bill_to_ship").val('0');
					$("#chkout-bill_to_ship_cb_container").toggle(false);
					}
				else if(myControl.data.cartItemsList.cart['chkout.bill_to_ship']*1 == 0)	{
//					myControl.util.dump(' -> bill to ship is disabled ('+myControl.data.cartItemsList.cart['chkout.bill_to_ship']+')');
					$("#chkout-bill_to_ship_cb").removeAttr("checked");
					$("#chkout-bill_to_ship").val('0');
					}
				else	{
//					myControl.util.dump(' -> bill to ship is enabled ('+myControl.data.cartItemsList.cart['chkout.bill_to_ship']+')');
					$("#chkout-bill_to_ship").val('1');
					$("#chkout-bill_to_ship_cb").attr("checked","checked");
					}
				
//from a usability perspective, we don't want a single item select list to show up. so hide if only 1 or 0 options are available.
				if(myControl.data.appCheckoutDestinations['@destinations'].length < 2)
					$('#billCountryContainer').toggle(false);

//				myControl.util.dump('END myControl.ext.convertSessionToOrder.panelContent.billAddress.');
				}, //billAddress
				
				
			shipAddress : function()	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.panelContent.shipAddress.  ');
				var txt = '';
				var cssClass = '';  //used around the form fields. turned off if pre-defined addresses exist, but form is still generated so a new address can be added.
				var $panelFieldset = $("#chkoutShipAddressFieldset");
				
				if(myControl.ext.store_checkout.util.determineAuthentication() == 'authenticated' && myControl.ext.store_checkout.util.addressListOptions('ship') != false)	{
					myControl.util.dump(' -> user is authenticated and has predefined shipping addressses.');
// for existing customers/addresses, there is a default bill and a default ship address that could be different. So, the checkbox for bill to ship is NOT checked and the ship address panel is displayed.
					$panelFieldset.toggle(true); //toggles the panel on.
					txt = "<p class='addressListPrompt'>Please choose from (click on) shipping address(es) below:<\/p>";
					txt += myControl.ext.store_checkout.util.addressListOptions('ship'); // creates pre-defined address blocks.
					cssClass = 'displayNone'; 
					}

				$panelFieldset.removeClass('loadingBG').append(txt);
				$panelFieldset.append(myControl.renderFunctions.transmogrify({'id':'shipAddressUL'},'checkoutTemplateShipAddress',myControl.data.cartItemsList.cart))
				
				$('#shipAddressUL').addClass(cssClass); //address form is hidden if user is logged in, in favor of clickable predefined addresses.

//from a usability perspective, we don't want a single item select list to show up. so hide if only 1 or 0 options are available.
				if(myControl.data.appCheckoutDestinations['@destinations'].length < 2)
					$('#shipCountryContainer').toggle(false);
				
				}, //shipAddress


			shipMethods : function()	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.panelContent.shipMethods');

				var $panelFieldset = $("#chkoutShipMethodsFieldset").removeClass("loadingBG");
				$panelFieldset.append(myControl.renderFunctions.createTemplateInstance('checkoutTemplateShipMethods','shipMethodsContainer'));
				myControl.renderFunctions.translateTemplate(myControl.data.cartShippingMethods,'shipMethodsContainer');

//must appear after panel is loaded because otherwise the divs don't exist.
				if(myControl.data.cartShippingMethods['@methods'].length == 0)	{
					$('#noShipMethodsAvailable').toggle(true);
					}
				else if(!$('#data-bill_zip').val() && !$('ship_zip').val()) {
					$('#noZipShipMessage').toggle(true);
					}

/*
it's possible that a ship method is set in the cart that is no longer available.
this could happen if 'local pickup' is selected, then country,zip,state, etc is changed to a destination where local pickup is not available.
in these instances, the selected method in the cart/memory/local storage must get emptied.
*/
				var foundMatchingShipMethodId = false; 
				var L = myControl.data.cartShippingMethods['@methods'].length;
				for(var i = 0; i < L; i += 1)	{
					if(myControl.data.cartShippingMethods['@methods'][i].id == myControl.data.cartItemsList.cart['ship.selected_id'])	{
						foundMatchingShipMethodId = true;
						break; //once a match is found, no need to continue the loop.
						}
					}

				if(foundMatchingShipMethodId == false)	{
					myControl.util.dump(' -> previously selected ship method is no longer available. update session with null value.');
					myControl.calls.cartSet.init({"ship.selected_id":null});  //the set will update the method, session and local storage.
					myControl.calls.refreshCart.init({"callback":"updateCheckoutOrderContents","extension":"convertSessionToOrder"},'immutable');
					myControl.model.dispatchThis('immutable');
					}
					
				}, //shipMethods




//displays the cart contents in a non-editable format	
			cartContents : function()	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.panelContent.cartContents');
				var $container = $('#chkoutCartSummaryContainer').toggle(true); //make sure panel is visible.

/*
checkoutCartSummary is the id given once the 'container' template has been rendered. It only needs to be rendered once. 
 -> this is more efficient. This also solves any error handling issues where the dom isn't updated prior to error messaging being added (the div may not exist yet).
two of it's children are rendered each time the panel is updated (the prodlist and cost summary)
*/
				if($('#chkoutCartSummary').length == 0)	{
//					myControl.util.dump(" -> chkoutCartSummary has no children. render entire panel.");
					$container.append(myControl.renderFunctions.createTemplateInstance('checkoutTemplateCartSummaryPanel','chkoutCartSummary'));
					myControl.renderFunctions.translateTemplate(myControl.data.cartItemsList.cart,'chkoutCartSummary');
					}
				


				}, //cartContents



			paymentOptions : function()	{
//				myControl.util.dump('myControl.ext.convertSessionToOrder.panelContent.paymentOptions has been executed');
				var $panelFieldset = $("#chkoutPayOptionsFieldset").toggle(true).removeClass("loadingBG")
				$panelFieldset.append(myControl.renderFunctions.createTemplateInstance('checkoutTemplatePayOptionsPanel','payOptionsContainer'));
				myControl.renderFunctions.translateTemplate(myControl.data.appPaymentMethods,'payOptionsContainer');	
				myControl.ext.convertSessionToOrder.util.updatePayDetails(myControl.data.cartItemsList.cart['chkout.payby']);
				}, //paymentOptions
		
		
/*
the notes textarea will create a dispacth for the contents when they're updated, but it doesn't send.
after using it, too frequently the dispatch would get cancelled/dominated by another dispatch.
*/
			orderNotes : function()	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.panelContent.orderNotes');
				var $panelFieldset = $("#chkoutOrderNotesFieldset").toggle(true).removeClass("loadingBG")
				$panelFieldset.append(myControl.renderFunctions.createTemplateInstance('checkoutTemplateOrderNotesPanel','orderNotesContainer'));
				myControl.renderFunctions.translateTemplate(myControl.data.cartItemsList.cart,'orderNotesContainer');
//				myControl.util.dump('END myControl.ext.convertSessionToOrder.panelContent.orderNotes');
				} //orderNotes



			}, //panelContent
	



////////////////////////////////////   						utilities			    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


		util : {
//when a country is selected, the required attribute must be added or dropped from state/province.
//this is important because the browser itself will indicate which fields are required.
//some countries do not have state/province, so for international it is automatically not required.
			countryChange : function(type,country)	{
//				myControl.util.dump('BEGIN convertSessionToOrder.util.countryChange. type: '+type+' and country: '+country)
				if(country == 'US')	{
					$('#data-'+type+'_state').attr('required','required');
					}
				else	{
					myControl.util.dump(' -> got here: '+type);
					$('#data-'+type+'_state').removeAttr('required').parent().removeClass('mandatory');
					}
				},
				
//executed when a coupon is submitted. handles ajax call for coupon and also updates cart.
			handleCouponSubmit : function()	{
				$('#chkoutSummaryErrors').empty(); //remove any existing errors.
				$('#addCouponBtn').attr('disabled','disabled').addClass('ui-state-disabled loadingButtonBg');
				myControl.ext.store_checkout.calls.cartCouponAdd.init($('#couponCode').val(),'addCouponToCart'); 
				myControl.calls.refreshCart.init({"callback":"updateCheckoutOrderContents","extension":"convertSessionToOrder"},'immutable');
				myControl.model.dispatchThis('immutable');
				}, //handleCouponSubmit

//executed when a giftcard is submitted. handles ajax call for giftcard and also updates cart.
//no 'loadingbg' is needed on button because entire panel goes to loading onsubmit.
//panel is reloaded in case the submission of a gift card changes the payment options available.
			handleGiftcardSubmit : function()	{
				myControl.ext.store_checkout.calls.cartGiftcardAdd.init($('#giftcardCode').val(),'addGiftcardToCart'); 
				myControl.ext.store_checkout.calls.appPaymentMethods.init();
				myControl.ext.convertSessionToOrder.util.handlePanel('chkoutPayOptions');
				myControl.calls.refreshCart.init({"callback":"updateCheckoutOrderContents","extension":"convertSessionToOrder"},'immutable');
				myControl.model.dispatchThis('immutable');
				}, //handleGiftcardSubmit
			

			handleChangeFromPayPalEC : function()	{
				myControl.ext.store_checkout.util.nukePayPalEC(); //kills all local and session paypal payment vars
				myControl.ext.convertSessionToOrder.util.handlePanel('chkoutPayOptions');
				myControl.ext.convertSessionToOrder.util.handlePanel('chkoutBillAddress');
				myControl.ext.convertSessionToOrder.util.handlePanel('chkoutShipAddress');
				myControl.ext.convertSessionToOrder.util.handlePanel('chkoutShipMethods');
				myControl.ext.convertSessionToOrder.calls.showCheckoutForm.init();  //handles all calls.
				myControl.model.dispatchThis('immutable');
				},




//this is a function so that it can be more easily overridden/customized.
			cartIsEmptyWarning : function()	{
//				myControl.util.dump(' -> checkout clicked but cart empty message appeared. GA Event here. Maybe we add a link to old checkout too.'); //add GA event or zoovy error pixel track code %%%.



_gaq.push(['_trackEvent','Checkout','App Event','Empty Cart Message Displayed']);


				$('#'+myControl.ext.convertSessionToOrder.vars.containerID).empty().append("<p>It appears your cart is empty. If you think you are receiving this message in error, please contact the site administrator.<\/p>");					
				}, //cartIsEmptyWarnin

				

//run when a payment method is selected. updates cart/session and adds a class to the radio/label.
//will also display additional information based on the payment type (ex: purchase order will display PO# prompt and input)
			updatePayDetails : function(paymentID)	{
				myControl.util.dump(" -> PAYID = "+paymentID);
//				var paymentID = $("[name='chkout.payby']:checked").val(), o = '';
				$('#chkoutPayOptionsFieldsetErrors').empty().hide(); //clear any existing errors from previously selected payment method.
				$('#chkout-payOptions li .paycon').removeClass('ui-state-active ui-corner-top ui-corner-bottom');
				$('#chkout-payOptions .paybySupplemental').hide(); //hide all other payment messages/fields.
				$('#payby_'+paymentID+' .paycon').addClass('ui-state-active ui-corner-top');
				$('#paybySupplemental_'+paymentID).show();
				
				var $selectedPayment = $('#paybySupplemental_'+paymentID);
	//only add the 'subcontents' once. if it has already been added, just display it (otherwise, toggling between payments will duplicate all the contents)
				if($selectedPayment.length == 0)	{
					$selectedPayment = $("<ul />").attr("id","paybySupplemental_"+paymentID).addClass("paybySupplemental noPadOrMargin noListStyle ui-widget-content ui-corner-bottom");
					$('#payby_'+paymentID).append($selectedPayment);
					var o = '';
					var safeid;
					switch(paymentID)	{
//for credit cards, we can't store the # or cid in local storage. Save it in memory so it is discarded on close, reload, etc
//expiration is less of a concern
						case 'CREDIT':
							o = "<li><label for='payment-cc'>Credit Card #<\/label><input type='text' size='20' name='payment.cc' id='payment-cc' class=' creditCard' value='";
							if(myControl.ext.convertSessionToOrder.vars['payment.cc']){o += myControl.ext.convertSessionToOrder.vars['payment.cc']}
							o += "' onKeyPress='return myControl.util.numbersOnly(event);' onChange='myControl.ext.convertSessionToOrder.vars[\"payment.cc\"] = this.value' /><\/li>";
							o += "<li><label>Expiration<\/label><select name='payment.mm' id='payment-mm' class='creditCardMonthExp' onChange='myControl.ext.convertSessionToOrder.vars[\"payment.mm\"] = this.value;'><option><\/option>";
							o += myControl.util.getCCExpMonths(myControl.data.cartItemsList.cart['payment.mm']);
							o += "<\/select>";
							o += "<select name='payment.yy' id='payment-yy' class='creditCardYearExp' onChange='myControl.ext.convertSessionToOrder.vars[\"payment.yy\"] = this.value;'><option value=''><\/option>"+myControl.util.getCCExpYears(myControl.data.cartItemsList.cart['payment.yy'])+"<\/select><\/li>";
							o += "<li><label for='payment.cv'>CVV/CID<\/label><input type='text' size='8' name='payment.cv' id='payment-cv' class=' creditCardCVV' onKeyPress='return myControl.util.numbersOnly(event);' value='";
							if(myControl.ext.convertSessionToOrder.vars['payment.cv']){o += myControl.ext.convertSessionToOrder.vars['payment.cv']}
							o += "' onChange='myControl.ext.convertSessionToOrder.vars[\"payment.cv\"] = this.value' /> <span class='ui-icon ui-icon-help' onClick=\"$('#cvvcidHelp').dialog({'modal':true,height:400,width:550});\"></span><\/li>";
							break;
	
						case 'PO':
							o = "<li><label for='payment-po'>PO #<\/label><input type='text' size='2' name='payment.po' id='payment-po' class=' purchaseOrder' onChange='myControl.calls.cartSet.init({\"payment.po\":this.value});' value='";
							if(myControl.data.cartItemsList.cart['payment.po'])
									o += myControl.data.cartItemsList.cart['payment.po'];
							o += "' /><\/li>";
							break;
	
						case 'ECHECK':
							for(var key in myControl.ext.convertSessionToOrder.vars.echeck) {
								safeid = myControl.util.makeSafeHTMLId(key);
//the info below is added to the pdq but not immediately dispatched because it is low priority. this could be changed if needed.
								o += "<li><label for='"+safeid+"'>"+myControl.ext.convertSessionToOrder.vars.echeck[key]+"<\/label><input type='text' size='2' name='"+key+"' id='"+safeid+"' class=' echeck' onChange='myControl.calls.cartSet.init({\""+key+"\":this.value});' value='";
								if(myControl.data.cartItemsList.cart[key])
									o += myControl.data.cartItemsList.cart[key];
								o += "' /><\/li>";
								}
							break;
						default:
//no supplemental material is present. hide it so no styling shows up. add bottom corners to payment method for consistency (with shipping). corners added on supplemental, when present.
							$('#payby_'+paymentID+' .paycon').addClass('ui-corner-bottom');
							$('#paybySupplemental_'+paymentID).hide(); 
							o = '';
						}
					$selectedPayment.append(o);
					}

	//			myControl.util.dump('END myControl.ext.convertSessionToOrder.util.updatePayDetails. paymentID = '+paymentID);			
_gaq.push(['_trackEvent','Checkout','User Event','Payment method selected ('+paymentID+')']);
				}, //updatePayDetails


//used to display errors that are returned on the validateCheckout call if validation fails. 



//panel value could be:  chkoutBillAddress, chkoutShipAddress
//the legend and error ul are here because this is what is used to set the panels to 'loading' when a request is made.
//adding the error container allows errors to be added while the ajax request is still in progress or finished but content hasn't been added yet.
//basically, guarantees the existence of the error container.
			handlePanel : function(panel,hidden)	{
//				myControl.util.dump("BEGIN convertSessionToOrder.panels.handlePanel");
//				myControl.util.dump(" -> panel: "+panel);
//				myControl.util.dump(" -> hidden: "+hidden);
				var cssClass = hidden == true ? 'displayNone' : ''; //if hidden is enabled, add the displayNone class. used for ship address, for example 

//here for troubleshooting.

//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.util.handlePanel.');
//				myControl.util.dump(' -> panel = '+panel);
//				myControl.util.dump(' -> hidden = '+hidden);
//				myControl.util.dump(' -> cssClass = '+cssClass);

//output which is automatically added to each panel. Used for title and error handling.
				var o = "<legend id='"+panel+"Legend' class='ui-widget-header ui-corner-all'>"+myControl.ext.convertSessionToOrder.vars.legends[panel]+"<\/legend>";
				o += "<div id='"+panel+"FieldsetErrors'><\/div>";
//if the panel doesn't already exist, create it.
				if(!$('#'+panel+'Fieldset').length > 0) {
//					myControl.util.dump(' -> panel does not exist');
					$('#zCheckoutFrm').append("<fieldset id='"+panel+"Fieldset' class='ui-widget ui-widget-content ui-corner-all loadingBG "+cssClass+"'>"+o+"<\/fieldset>");
					}
				else{
//					myControl.util.dump(' -> panel exists');
					$('#'+panel+'Fieldset').empty().addClass(' ui-widget ui-widget-content ui-corner-all loadingBG '+cssClass).append(o);
					}
//				myControl.util.dump('END myControl.ext.convertSessionToOrder.util.handlePanel.');				
				}, //handlePanel






//run when a shipping method is selected. updates cart/session and adds a class to the radio/label
//the dispatch occurs where/when this function is executed, NOT as part of the function itself.
			updateShipMethod : function(shipID,safeID)	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.util.');	
//				myControl.util.dump('value = '+shipID);	
				myControl.calls.cartSet.init({'ship.selected_id':shipID});
				myControl.calls.refreshCart.init({"callback":"updateCheckoutOrderContents","extension":"convertSessionToOrder"},'immutable'); //update cart totals to reflect new ship method selected.
				myControl.ext.convertSessionToOrder.util.handlePanel('chkoutPayOptions');  //empty panel and set to loading
				myControl.ext.store_checkout.calls.appPaymentMethods.init("updateCheckoutPayOptions"); //updates payment panel (pay methods may change based on shipping method)
//on radio buttons, a safe id is passed in reference to the container li for style manipulation.
//if the safeid isn't passed, we're likely in a select list or some other format where style changes are not needed.
				if(safeID)	{
					$("#chkout-shipMethods li").removeClass("selected ui-state-active ui-corner-all");
					$('.shipcon_'+safeID).addClass('selected ui-state-active ui-corner-all');
					}

_gaq.push(['_trackEvent','Checkout','User Event','Shipping method selected ('+shipID+')']);


//				myControl.util.dump('END myControl.checkoutFunctions.ShipMethod. shipID = '+shipID);			
				}, //updateShipMethod





//executed when the 'bill to ship' checkbox is checked (either on or off)
			toggleShipAddressPanel : function()	{
				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.util.toggleShipAddressPanel');
//ship to billing
				if($('#chkout-bill_to_ship_cb').is(':checked')) {
					myControl.util.dump(' -> bill to ship IS checked (hide shipping address panel)');
					$('#chkoutShipAddressFieldset').toggle(false); //disable display of ship address panel.
					$('#chkout-bill_to_ship').val('1');  //update hidden input. this is what is actually used in ajax request.
					myControl.ext.store_checkout.util.setShipAddressToBillAddress(); //update all shipping address fields from bill address.
					myControl.ext.convertSessionToOrder.calls.saveCheckoutFields.init(); //update session. all fields are updated because shipping address fields were populated.
					myControl.ext.convertSessionToOrder.util.handlePanel('chkoutShipMethods');  //empties panel. sets to loading.
					myControl.ext.store_checkout.calls.cartShippingMethodsWithUpdate.init("updateCheckoutShipMethods"); //update shipping methods and shipping panel
					myControl.calls.refreshCart.init({"callback":"updateCheckoutOrderContents","extension":"convertSessionToOrder"},'immutable');  //updates cart object and reloads order contents panel.
					}
//do not ship to billing
				else {
					myControl.util.dump('bill to ship is NOT checked (show shipping address panel)');
					myControl.ext.convertSessionToOrder.util.handlePanel('chkoutShipAddress');  //empties panel. sets to loading.
					$('#chkoutShipAddressFieldset').toggle(true);  //make sure panel is visible.
					myControl.ext.convertSessionToOrder.panelContent.shipAddress(); //populate panel.
					$('#chkout-bill_to_ship').val("0");  //update hidden input. this is what is actually used in ajax request.
					myControl.calls.cartSet.init({"chkout.bill_to_ship":"0"}); //update session.
					};
				myControl.model.dispatchThis('immutable');
				}, //toggleShipAddressPanel

/*
CHANGE LOG: 2012-04-04
addressFieldUpdated was changed in such a way that the zip and country inputs should NOT have recalculateShipMethods on them anymore IF addressFieldUpdated is present (bill inputs).
ship inputs or other inputs that do NOT have the addressFieldUpdated function executed can still use recalculateShipMethods directly. SUCR should be blank or false for these instances.

addressFieldUpdated should now also have the fieldID passed in. ex:
myControl.ext.convertSessionToOrder.util.addressFieldUpdated(this.id);

this change was made to reduce duplicate requests AND solve an issue where the session wasn't being updated prior to new ship/pay methods being requested.
recalculateShipMethods function was also modified to support SUCR var.
handleBill2Ship function added.
*/


//executed when any billing address field is updated so that tax is accurately computed/recomputed and displayed in the totals area.
			addressFieldUpdated : function(fieldID)	{
				myControl.util.dump("BEGIN myControl.ext.convertSessionToOrder.util.addressFieldUpdated");
				var SUCR = false; //Sesion Updated. Cart Requested. set to true if these conditions are met so that no duplicate calls are created.
//these changes need to be made before				

				this.handleBill2Ship(); //will set ship vars if bill to ship is checked.
				if(myControl.ext.store_checkout.util.taxShouldGetRecalculated())	{
					myControl.util.dump(" -> saveCheckoutFields originated from addressFieldUpdated");
					myControl.ext.convertSessionToOrder.calls.saveCheckoutFields.init(); //update session with ALL populated fields.
					myControl.calls.refreshCart.init({"callback":"updateCheckoutOrderContents","extension":"convertSessionToOrder"},'immutable');
					SUCR = true;
					}
//when zip or country is updated, we may need to recalculate the ship methods.
				if(fieldID.indexOf('zip') > 0 || fieldID.indexOf('country') > 0)	{
					var TYPE = fieldID.indexOf('ship') > 0 ? 'ship' : 'bill';
					myControl.util.dump(" -> type: "+TYPE);
					this.recalculateShipMethods(TYPE,SUCR);
					}

				
				}, //addressFieldUpdated

//if bill to ship is true, then the ship zip and country fields are updated to make sure API doesn't get confused.
//ok. odd. bill_to_ship is checkout var, but shouldn't it be ship to bill? I'll leave my var as is to be consistent.
			handleBill2Ship : function()	{
				var billToShip = ($('#chkout-bill_to_ship').val())*1;
				if(billToShip) {
					myControl.util.dump(" -> billToShip is true. update ship inputs with current zip/country.");
					myControl.ext.store_checkout.util.setShipAddressToBillAddress(); //update all shipping address fields from bill address.
//					$('#data-ship_zip').val($('#data-bill_zip').val());
//					$('#data-ship_country').val($('#data-bill_country').val());
					}
				myControl.util.dump(" -> handleBill2Ship val: "+billToShip);
				return billToShip;
				},






/*
paypal returns a user to the checkout page, not the order complete page.
if token and payerid are set on URI, then user has just returned to checkout, so do the following:
1. get checkout details (will include paypal info like address)
2. if address is not populated already, populate address. (if logged in, show form, not predefined addresses)
3. lock down address fields so they are not editable.
note - predefined addresses are hidden and the form is shown so that if the user used a paypal address, we don't have to try to 'map' it back to an account address.

4. lock down payment options so they are not editable.
5. select paypal EC as payment option.
6. lock down shipping (a method is selected in paypal)
7. add button near 'place order' that says 'change from paypal to other payment option'.


*/
			handlePaypalFormManipulation : function()	{
			myControl.util.dump("BEGIN convertSessionToOrder.util.handlePaypalFormManipulation ");
//when paypal redirects back to checkout, these two vars will be on URI: token=XXXX&PayerID=YYYY

//uncheck the bill to ship option so that user can see the paypal-set shipping address.
//
var $billToShipCB = $('#chkout-bill_to_ship_cb');
$billToShipCB.attr('disabled','disabled')
if($billToShipCB.is(':checked'))	{
//code didn't like running a .click() here. the trigered function registered the checkbox as checked.
	$billToShipCB.removeAttr("checked");
	myControl.ext.convertSessionToOrder.util.toggleShipAddressPanel();
	}
//hide all bill/ship predefined addresses.
$('#chkoutBillAddressFieldset address').hide();
$('#chkoutShipAddressFieldset address').hide();
//show bill/ship address form
$('#billAddressUL').show();
$('#shipAddressUL').show();
//disable all shipping address inputs that are populated (by paypal) and select lists except phone number (which isn't populated by paypal)
$('#chkoutShipAddressFieldset input, #chkoutShipAddressFieldset select').each(function(){
	if($(this).val() != '')	{
		$(this).attr('disabled','disabled')
		}
	});
$('#data-ship_phone').removeAttr('disabled');

//name and email are disabled for billing address. They'll be populated by paypal and are not allowed to be different.
$('#data-bill_firstname, #data-bill_lastname, #data-bill_email').attr('disabled','disabled');
$('.addressListPrompt').hide(); //this text needs to be hidden if a user is logged in cuz it doesn't make sense at this point.



//make sure paypal is selected payment option. this will trigger a request to select it as well.
//disable all other payment optins.
$('#chkout-payby_PAYPALEC').click(); //payby is not set by default, plus the 'click' is needed to open the subpanel
$('#chkoutPayOptionsFieldset input[type=radio]').attr('disabled','disabled');

//disable all ship methods.
$('#chkoutShipMethodsFieldset input[type=radio]').attr('disabled','disabled');

//disable giftcards
$('#giftcardMessaging').text('PayPal not compatible with giftCards');
//$('#couponMessaging').show().text('PayPal is not compatible with Coupons');
$('#giftcardCode').attr('disabled','disabled'); //, #couponCode
$('#addGiftcardBtn').attr('disabled','disabled').addClass('ui-state-disabled'); //, #addCouponBtn

$('#paybySupplemental_PAYPALEC').empty().append("<a href='#top' onClick='myControl.ext.store_checkout.util.nukePayPalEC();'>Choose Alternate Payment Method<\/a>");
				
				},


//Executed when the bill or ship fields for zip or country are updated.
//will always update the cart object with both the billing and shipping zip and country
//will use billing zip/country to update shipping if ship to billing is checked.
//ship is updated also to make sure we always get the correct shipping rates.
			recalculateShipMethods : function(TYPE,SUCR)	{
				
				var billToShip = this.handleBill2Ship(); //will return a 1 if billToShip is checked.

				if(TYPE == 'bill' && billToShip == 0)	{
//when billing is updated and bill to ship is NOT checked, no need to do any ajax update or panel update.
					myControl.util.dump(" -> bill zip/country changed, but ship to billing is NOT checked, so no update needed.");
					}
				else	{
//to get here, type = ship OR (type = bill AND ship to bill is checked)
					myControl.util.dump(" -> zip/country changed (type = "+TYPE+"). ship to bill = "+billToShip+" and typeof billToShop (should be number) = "+typeof billToShip);
					
/*
in the list of calls below, sequence is important.  The session must be updated first so that all the other calls have accurate data to work with.
the getCartContents call can come second because none of the following calls are updates, just gets.
*/

//save all the checkout fields.  This is cheaper (server side) than doing setSession for several fields according to BH (2012-12-29)
					if(!SUCR)	{
						myControl.util.dump(" -> saveCheckoutFields originated from recalculateShipMethods");
						myControl.ext.convertSessionToOrder.calls.saveCheckoutFields.init();
						myControl.calls.refreshCart.init({"callback":"updateCheckoutOrderContents","extension":"convertSessionToOrder"},'immutable');
						}

//the saveCheckoutFields above this if statement needs to be put in the q prior to the appPaymentMethods below.
					if(billToShip) {
						myControl.ext.convertSessionToOrder.util.handlePanel('chkoutPayOptions'); //empties panel. sets to loading.
						myControl.ext.store_checkout.calls.appPaymentMethods.init("updateCheckoutPayOptions");
						}

					myControl.ext.convertSessionToOrder.util.handlePanel('chkoutShipMethods'); //empties panel. sets to loading.
					myControl.ext.store_checkout.calls.cartShippingMethodsWithUpdate.init("updateCheckoutShipMethods");
					
				
					}
				} //recalculateShipMethods

			},







////////////////////////////////////   						renderFormats			    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\







		renderFormats : {

			shipMethodsAsRadioButtons : function($tag,data)	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.formats.shipMethodsAsRadioButtons');
				var o = '';
				var shipName;
				var L = data.value.length;


				var id,safeid;  // id is actual ship id. safeid is id without any special characters or spaces. isSelectedMethod is set to true if id matches cart shipping id selected.
				var isSelectedMethod = false;
				if(L == 1)	{
					isSelectedMethod = data.value[0].id; //will make the ship method 'selected' if it's the only choice.
					}
				for(var i = 0; i < L; i += 1)	{
					
					safeid = myControl.util.makeSafeHTMLId(data.value[i].id);
					id = data.value[i].id;

//whether or not this iteration is for the selected method should only be determined once, but is used on a couple occasions, so save to a var.
					if(id == myControl.data.cartItemsList.cart['ship.selected_id'])	{
						isSelectedMethod = true;
						}

//myControl.util.dump(' -> id = '+id+' and ship.selected_id = '+myControl.data.cartItemsList.cart['ship.selected_id']);
					
					shipName = myControl.util.isSet(data.value[i].pretty) ? data.value[i].pretty : data.value[i].name
					
					o += "<li class='shipcon "
					if(isSelectedMethod)
						o+= ' ui-state-active selected ui-corner-all ';
					o += "shipcon_"+safeid; //hhhmmm... seems to cause issues sometimes. add it last so ui-state-active and selected always get added.
					o += "'><input type='radio' name='ship.selected_id' id='ship-selected_id_"+safeid+"' value='"+id+"' onClick='myControl.ext.convertSessionToOrder.util.updateShipMethod(this.value,\""+safeid+"\"); myControl.model.dispatchThis(\"immutable\"); '";
					if(isSelectedMethod)
						o += " checked='checked' "
					o += "/><label for='ship-selected_id_"+safeid+"'>"+shipName+": <span >"+myControl.util.formatMoney(data.value[i].amount,'$','',false)+"<\/span><\/label><\/li>";
					isSelectedMethod = false;
					}
				$tag.html(o);
				}, //shipMethodsAsRadioButtons 
			




			payMethodsAsRadioButtons : function($tag,data)	{
//				myControl.util.dump('BEGIN myControl.ext.convertSessionToOrder.renderFormats.payOptionsAsRadioButtons');
//				myControl.util.dump(data);
				var L = data.value.length;
				var o = "";
				var id = '';
				var isSelectedMethod = false;
				if(L == 1)	{
					isSelectedMethod = data.value[0].id; //will make the ship method 'selected' if it's the only choice.
					}
				
				for(var i = 0; i < L; i += 1)	{
					id = data.value[i].id;

					o += "<li class='paycon_"+id+"' id='payby_"+id+"'><div class='paycon'><input type='radio' name='chkout.payby' id='chkout-payby_"+id+"' value='"+id+"' onClick='myControl.ext.convertSessionToOrder.utilities.updatePayDetails(this.value); myControl.calls.cartSet.init({\"chkout.payby\":this.value}); myControl.model.dispatchThis(\"immutable\"); $(\"#chkoutPayOptionsFieldsetErrors\").addClass(\"displayNone\");' ";
					
					if(id == myControl.data.cartItemsList.cart['chkout.payby'])	{
						isSelectedMethod = true;
						o += " checked='checked' ";
						}					
					
					o += "/><label for='chkout-payby_"+id+"'>"+data.value[i].pretty+"<\/label></div><\/li>";
					}

				$tag.html(o);
				if(isSelectedMethod)	{
					myControl.util.dump(" -> isSelectedMethod: "+isSelectedMethod);
					$(':radio[value='+isSelectedMethod+']').change(); //triggering the change works, but trying to set attr checked didn't, so it's set above.
					}
				} //payMethodsAsRadioButtons		
			
			
			}




		}
	return r;
	}