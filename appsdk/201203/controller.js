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

************************************************************** */



zController = function(params,extensions) {
	this.util.dump('zController has been initialized');
	if(typeof Prototype == 'object')	{
		alert("Oh No! you appear to have the prototype ajax library installed. This library is not compatible. Please change to a non-prototype theme (2011 series).");
		}
	else if(typeof zGlobals == 'undefined')	{
		alert("Uh Oh! A required include (config.js) is not present. This document is required.");
		}
	else	{
		this.initialize(params,extensions);
		}
//bind an unload event to the window.  This will save all the checkout fields to the DQ, then dispatch them and any others that are waiting.
//this will display a 'do you want to leave' warning. We need to bind this only during checkout and unbind it when not in checkout (or finished checking out). !!!
//this works in safari and FF reliably. In IE it works so-so. test to see if the jquery vs. js works better.
//	$(window).unload(function() {});
//	window.onbeforeunload = function(){
//		myControl.calls.saveCheckoutFields.init();
//		myControl.model.dispatchThis();
//		alert('test 2 (returns false)');
//		return 'there are unsaved changes'  //IE will display this message.
//		};
	}
	
$.extend(zController.prototype, {
	
	initialize: function(P,E) {
		myControl = this;
		myControl.model = zoovyModel(); // will return model as object. so references are myControl.model.dispatchThis et all.

		myControl.vars = {};
		myControl.vars['_admin'] = null; //set to null. could get overwritten in 'P' or as part of newAdminSession.
		myControl.vars.cid = null; //gets set on login. ??? I'm sure there's a reason why this is being saved outside the normal cart object. Figure it out and document it.
		myControl.vars.fbUser = {};

// can be used to pass additional variables on all request and that get logged for certain requests (like createOrder). 
// default to blank, not 'null', or += below will start with 'undefined'.
//vars should be passed as key:value;  _v will start with zmvc:version.release.
		myControl.vars.passInDispatchV = '';  
		myControl.vars.release = 'unspecified'; //will get overridden if set in P. this is defualt.

//set after individual defaults are set above so that what is passed in can override. Should give priority to vars set in P.
		myControl.vars = $.extend(myControl.vars,P); 
//!!! - this needs to be addressed.
//if a merchant has a ssl cert, secure url is formatted as .com but if no ssl, formatted as .com/
//so for now, compensate by adding / to the end so we can depend on it being there.
		if(myControl.vars.secureURL && myControl.vars.secureURL.charAt( myControl.vars.secureURL.length-1 ) != "/")
			myControl.vars.secureURL = myControl.vars.secureURL+"/";
			
//myControl.util.dump(myControl.vars); //here just to test is safari will output an obj to the console.

// += is used so that this is appended to anything passed in P.
		myControl.vars.passInDispatchV += myControl.util.getBrowserInfo()+";OS:"+myControl.util.getOSInfo()+';'; 
		
		myControl.extensions = {}; //for holding extensions, including checkout.
		myControl.data = {}; //used to hold all data retrieved from ajax requests.
		
/* some diagnostic reporting info */
		myControl.util.dump(' -> model version: '+myControl.model.version);
		myControl.util.dump(' -> release : '+myControl.vars.release);		
		
/*
myControl.templates holds a copy of each of the templates declared in an extension but defined in the view.
copying the template into memory was done for two reasons:
1. faster reference when template is needed.
2. solve any duplicate 'id' issues within the spec itself when original spec and cloned template are present.
   -> this solution was selected over adding a var for subbing in the templates because the interpolation was thought to be too heavy.
*/
		myControl.templates = {};
		myControl.dispatchQ = new Array();  //used to store all ajax requests.
		myControl.priorityDispatchQ = new Array();  //used to store all immutable ajax requests (for checkout). referred to as PDQ in comments.
		myControl.ajax = {}; //holds ajax related vars.
		myControl.ajax.overrideAttempts = 0; //incremented when an override occurs. allows for a cease after X attempts.
		myControl.ajax.request = {}; //'holds' each ajax request and is used to see if an ajax request is in progress (so no two requests at same time)
		myControl.ajax.dispatchQInUse = 'dispatchQ'; //changed to reflext which q is being used. gets changed at exec of dispatchThis and defaulted to dispatchQ at end of each request.
//session ID can be passed in via the params (for use in one page checkout on a non-ajax storefront). If one is passed, it must be validated as active session.
//if no session id is passed, the getValidSessionID function will look to see if one is in local storage and use it or request a new one.
		P.sessionId ? myControl.calls.canIHaveSession.init(P.sessionId,{'callback':'handleTrySession','datapointer':'canIHaveSession'}) :  myControl.calls.getValidSessionID.init('handleNewSession');
		myControl.model.dispatchThis('priorityDispatchQ'); //handles dispatching for session validation. want this run prior to extensions.
//		myControl.util.dump('zController method has been initialized');
//if third party inits are not done before extensions, the extensions can't use any vars loaded by third parties. yuck. would rather load our code first.
// -> EX: username from FB and OPC.
		myControl.util.handleThirdPartyInits();
//E is the extensions. if there are any (and most likely there always will be) add then to the controller
		if(E.length > 0)	{
			myControl.model.addExtensions(E);
			}
		}, //initialize





					////////////////////////////////////   CALLS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\		


/*
calls all have an 'init' as well as a 'dispatch'.
the init allows for the call to check if the data being retrieved is already in the session or local storage and, if so, avoid a request.
If the data is not there, or there's no data to be retrieved (a setSession, for instance) the init will execute the dispatch.
*/
	calls : {

	
		authentication : {
//the authentication through FB sdk has already taken place and this is an internal server check to verify integrity.	
//the getFacebookUserData function also updates bill_email and adds the fb.user info into memory in a place quickly accessed
//the obj passed in is passed into the request as the _tag
			facebook : {
				init : function(tagObj)	{
					myControl.util.dump('BEGIN myControl.calls.authentication.facebook.init');
//					myControl.thirdParty.fb.saveUserDataToSession(); ///hhhhmmm... shouldn't this be on the callback? commented out on 2012-01-11

//Sanity - this call occurs AFTER a user has already logged in to facebook. So though server authentication may fail, the login still occured.
_gaq.push(['_trackEvent','Authentication','User Event','Logged in through Facebook']);


					this.dispatch(tagObj);
					},
				dispatch : function(tagObj)	{
//note - was using FB['_session'].access_token pre v-1202. don't know how long it wasn't working, but now using _authRepsonse.accessToken
					myControl.model.addDispatchToQ({'_cmd':'verifyTrustedPartner','partner':'facebook','appid':zGlobals.thirdParty.facebook.appId,'token':FB['_authResponse'].accessToken,'state':myControl.sessionID,"_tag":tagObj},'priorityDispatchQ');
					}
				}, //facebook
//obj is login/password.
//tagObj is everything that needs to be put into the tag node, including callback, datapointer and/or extension.
			zoovy : {
				init : function(obj,tagObj)	{
//					myControl.util.dump('BEGIN myControl.calls.authentication.zoovy.init ');
//					myControl.util.dump(' -> username: '+obj.login);
//email should be validated prior to call.  allows for more custom error handling based on use case (login form vs checkout login)
					myControl.calls.setSessionVars.init({"data.bill_email":obj.login}) //whether the login succeeds or not, set data.bill_email in cart/session
					this.dispatch(obj,tagObj);
					},
				dispatch : function(obj,tagObj)	{
					obj["_cmd"] = "tryCustomerLogin";
					obj['method'] = "unsecure";
					obj["_tag"] = tagObj;
					obj["_tag"]["datapointer"] = "tryCustomerLogin";
					
					myControl.model.addDispatchToQ(obj,'priorityDispatchQ');
					}
				} //zoovy
			}, //authentication
			
		getValidSessionID : {
			init : function(callback)	{
//				myControl.util.dump('BEGIN myControl.calls.getValidSessionID.init');
				var sid = myControl.model.fetchSessionId();  //will return a sessionid from control or cookie/local.
//				myControl.util.dump(' -> sessionId = '+sid);
//if there is a sid, make sure it is still valid.
				if(sid)	{
//					myControl.util.dump(' -> sessionid was set, verify it is valid.');
//make sure the session id is valid. 'handleTrySession' overrides the callback because error handling/logic is different between create new and verify one exists.
					myControl.calls.canIHaveSession.init(sid,{'callback':'handleTrySession','datapointer':'canIHaveSession'}); 
					}
				else	{
//					myControl.util.dump(' -> no session id. get a new one.');
					this.dispatch(callback); 
					}
				},
			dispatch : function(callback)	{
				myControl.model.addDispatchToQ({"_cmd":"newSession","_tag":{"callback":callback}},'priorityDispatchQ');
				}
			},//getValidSessionID

//getProfile and getQuickProd are going to be used often enough to justify putting them into the myControl.calls

	
		canIHaveSession : {
			init : function(zjsid,tagObj)	{
//				myControl.util.dump('BEGIN myControl.calls.canIHaveSession');
				myControl.sessionId = zjsid; //needed for the request. may get overwritten if not valid.
				this.dispatch(zjsid,tagObj);
				},
			dispatch : function(zjsid,tagObj)	{
				var obj = {};
				obj["_cmd"] = "canIHaveSession"; 
				obj["_zjsid"] = zjsid; 
				obj["_tag"] = tagObj;
				myControl.model.addDispatchToQ(obj,'priorityDispatchQ');
				}
			}, //canIHaveSession
			
		setSessionVars : {
			init : function(obj,tagObj)	{
				this.dispatch(obj,tagObj);
				},
			dispatch : function(obj,tagObj)	{
				obj["_cmd"] = "setSession";
				if(tagObj)	{obj["_tag"] = tagObj;}
				myControl.model.addDispatchToQ(obj,'priorityDispatchQ');
				}
			}, //setSessionVars
			
		getNewSessionId : {
			init : function(callback)	{
				this.dispatch(callback);
				},
			dispatch : function(callback)	{
				myControl.model.addDispatchToQ({"_cmd":"newSession","_tag":{"callback":callback}},'priorityDispatchQ'); //get new session id.
				}
			},//getNewSessionId

	
			newAdminSession : {
			 init : function(formObj,tagObj) {
				this.dispatch(formObj,tagObj);
				},
			 dispatch : function(formObj,tagObj)   {
				 if(typeof tagObj === 'undefined')
				 	tagObj = {};
				tagObj.extension = "admin_medialibrary";
				formObj["_tag"] = tagObj;
				formObj["_cmd"] = "newAdminSession";
				myControl.model.addDispatchToQ(formObj);
				}
			 } //newAdminSession

		}, //calls











					////////////////////////////////////   CALLBACKS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\











	callbacks : {
		handleNewSession : {
//myControl.sessionID is set in the method. no need to set it here.
//but having a callback does allow for behavioral changes (update new session with old cart contents which 'should' still be available.
//myControl.sessionid is set in the model. this function is mostly used for the onError.
			onSuccess : function(tagObj)	{
//				myControl.util.dump('BEGIN myControl.callbacks.handleNewSession.onSuccess');
//				myControl.util.dump(' -> session id = '+myControl.data[tagObj.datapointer]['_zjsid']);
				},
			onError : function(d)	{
				myControl.util.dump('BEGIN myControl.callbacks.handleNewSession.onError');
				$('#globalMessaging').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			},//convertSessionToOrder

//executed when canIHaveSession is requested.
//myControl.sessionID is already set by this point. need to reset it onError.
		handleTrySession : {
			onSuccess : function(tagObj)	{
//				myControl.util.dump('BEGIN myControl.callbacks.handleTrySession.onSuccess');
				if(myControl.data.canIHaveSession.exists == 1)	{
//					myControl.util.dump(' -> valid session id.  Proceed.');
					}
				else	{
					myControl.util.dump(' -> UH OH! invalid session ID. Generate a new session. ');
//					$('#globalMessaging').append(myControl.util.formatMessage("It appears the cart you were using has expired. We will go ahead and build you a new one. You should be able to continue as normal.")).toggle(true);
					}
				},
			onError : function(d)	{
				myControl.util.dump('BEGIN myControl.callbacks.handleTrySession.onError');
				$('#globalMessaging').toggle(true).append(myControl.util.getResponseErrors(d));
				myControl.sessionId = null;
				}
			}, //handleTrySession
		
		handleAdminSession : {
			onSuccess : function(tagObj)	{
				myControl.util.dump('BEGIN myControl.callbacks.handleAdminSession.onSuccess');
//				myControl.vars['_admin'] is set in the model.
				},
			onError : function(d)	{
				myControl.util.dump('BEGIN myControl.callbacks.handleAdminSession.onError');
				$('#globalMessaging').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			}

//doesn't appear to be used. commented out on 2012-01-11
/*
		logMeIn : {
			onSuccess : function(datapointer)	{
//				$('#loginFrm').remove();
				myControl.vars.cid = myControl.data[datapointer].cid;
//				myControl.util.dump('got to logMeIn success');
				},
			onError : function(d)	{
				myControl.util.dump('got to logMeIn error!');
				}
			},//logMeIn
			

		showDetailedCart : {
			onSuccess : function(tagObj)	{
				myControl.util.dump('got to showDetailedCart success');
//				var action = myControl.util.isSet(myControl.data.showCart.cart['cart.add_item_count']) ? zView.showDetailedCart() : zView.showEmptyCart();
				var $targetObj = $('#miniCartItemList');
				var sku, stid, i;
	//add product data.
				var L = myControl.data.showCart.cart.stuff.length;
				for(i = 0; i < L; i += 1)	{
					stid = myControl.data.showCart.cart.stuff[i].stid
					$targetObj.append(myControl.renderFunctions.createTemplateInstance('myCartSpec',{id:'myCartSpec_'+stid,'pid':stid}));
					myControl.renderFunctions.translateTemplate(myControl.data.showCart.cart.stuff[i],'myCartSpec_'+stid);
					}
	//add cart summary.
				$targetObj.append("<div class='clearAll'></div>");
				$targetObj.append(myControl.renderFunctions.createTemplateInstance('cartSummaryTotalsSpec','miniCartSummaryTotals'));
				myControl.renderFunctions.translateTemplate(myControl.data.showCart.cart,'miniCartSummaryTotals');
				
				$( "#miniCartContainer" ).dialog({
					height: '600',
					width: '95%',
					modal: true
					});
				
				},
			onError : function(d)	{
				myControl.util.dump('got to showDetailedCart error!');
				}
			} //showDetailedCart

*/

		}, //callbacks







			////////////////////////////////////   UTIL [the method formerly known as utilityFunctions]    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\






	util : {
//jump to an anchor. can use a name='' or id=''.  anchor is used in function name because that's the common name for this type of action. do not need to pass # sign.
		jumpToAnchor : function(id)	{
			window.location.hash=id;
			},

/*
for handling app messaging to the user.
pass in just a message and warning will be displayed.
pass in additional information for more control, such as css class of 'error' and/or a different jqueryui icon.
*/
		formatMessage	: function(messageData)	{
//			myControl.util.dump("BEGIN myControl.util.formatMessage");
// message data may be a string, so obj is used to build a new object. if messagedata is an object, it is saved into obj.
			var obj = {}; 
			if(typeof messageData == 'string')	{
//				myControl.util.dump(" -> is a string. show warning.");
				obj.message = messageData;
				obj.uiClass = 'highlight';
				obj.uiIcon = 'info';
				}
			else	{
				obj = messageData;
//default to a 'highlight' state, which is a warning instead of error.
//				myControl.util.dump(" -> is an object. show message specific class.");
				obj.uiClass = obj.uiClass ? obj.uiClass : 'highlight'; //error, highlight
				obj.uiIcon = obj.uiIcon ? obj.uiIcon : 'info'
				}

			var r = obj.htmlid ? "<div class='ui-widget' id='"+obj.htmlid+"'>": "<div class='ui-widget'>";
			r += "<div class='ui-state-"+obj.uiClass+" ui-corner-all appMessage'>";
			r += "<p><span style='float: left; margin-right: .3em;' class='ui-icon ui-icon-"+obj.uiIcon+"'></span>"+obj.message+"<\/p>";
			r += "<\/div><\/div>";
			if(obj.htmlid && obj.timeoutFunction)	{
				myControl.util.dump(" -> error message has timeout function.");
				setTimeout(obj.timeoutFunction, 6000);
				}
			return r;
			},
		
		getParameterByName : function(name)	{
			name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
			var regexS = "[\\?&]" + name + "=([^&#]*)";
			var regex = new RegExp(regexS);
			var results = regex.exec(window.location.href);
			if(results == null)
				return "";
			else
				return decodeURIComponent(results[1].replace(/\+/g, " "));
			},
// .browser returns an object of info about the browser (name and version).
//this is a function because .browser is deprecated and will need to be replaced, but I need something now. !!! fix in next version.
		getBrowserInfo : function()	{
			var r;
			var BI = jQuery.browser; //browser information. returns an object. will set 'true' for value of browser 
			jQuery.each(BI, function(i, val) {
				if(val === true){r = 'browser:'+i;}
				});
			r += '-'+BI.version;
//			myControl.util.dump(' r = '+r);
			return r;
			},
			
		getOSInfo : function()	{

			var OSName="Unknown OS";
			if (navigator.appVersion.indexOf("Win")!=-1) OSName="Windows";
			if (navigator.appVersion.indexOf("Mac")!=-1) OSName="MacOS";
			if (navigator.appVersion.indexOf("X11")!=-1) OSName="UNIX";
			if (navigator.appVersion.indexOf("Linux")!=-1) OSName="Linux";
			return OSName;
			},
			
		numbersOnly : function(e)	{
			var unicode=e.charCode? e.charCode : e.keyCode
			// if (unicode!=8||unicode!=9)
			if (unicode<8||unicode>9)        {
				if (unicode<48||unicode>57) //if not a number
				return false //disable key press
				}
			},


//pass in the response and an li for each error (parent ul not returned) will be generated.
//called frequently in checkout, but univeral enough to justify being in main control.
// note that if you use this, you may need to also update a panel so that more than just an error shows up or the user may not be able to proceed.
		getResponseErrors : function(d)	{
			myControl.util.dump("BEGIN myControl.util.getResponseErrors");
//			myControl.util.dump(d);
			var r;
			if(!d)	{
				r = 'unknown error has occured';
				}
			else if(typeof d == 'string')	{
				r = d;
				}
			else if(typeof d == 'object')	{
				r = "";
//error messages start at 1, not 0, so the loop starts at 1.		
				for(var i = 1; i <= d['_msgs']; i += 1)	{
					myControl.util.dump(d['_msg_'+i+'_type']+": "+d['_msg_'+i+'_id']);
					r += "<div>"+d['_msg_'+i+'_txt']+"<\/div>";
					}
				}
			else	{
				myControl.util.dump(" -> getResponseErrors 'else' hit. Should not have gotten to this point");
				r = 'unknown error has occured';
				}
			myControl.util.dump(r);
			return myControl.util.formatMessage(r);
			},
		
//current time in unix format.
		unixNow : function()	{
			return Math.round(new Date().getTime()/1000.0)
			}, //unixnow
			
		isValidEmail : function(str) {
			if(!str || str == false)
				return false;
			var at="@"
			var dot="."
			var lat=str.indexOf(at)
			var lstr=str.length
			var ldot=str.indexOf(dot)
			if (str.indexOf(at)==-1){
				return false
				}
			if (str.indexOf(at)==-1 || str.indexOf(at)==0 || str.indexOf(at)==lstr){
				return false
				}
			if (str.indexOf(dot)==-1 || str.indexOf(dot)==0 || str.indexOf(dot)==lstr){
				return false
				}
			if (str.indexOf(at,(lat+1))!=-1){
				return false
				}
			if (str.substring(lat-1,lat)==dot || str.substring(lat+1,lat+2)==dot){
				return false
				}
			if (str.indexOf(dot,(lat+2))==-1){
				return false
				}
			if (str.indexOf(" ")!=-1){
				return false
				}
			return true					
			}, //isValidEmail

//used frequently to throw errors or debugging info at the console.
//called within the throwError function too
		dump : function(msg)	{
//if the console isn't open, an error occurs, so check to make sure it's defined. If not, do nothing.
			if(typeof console != 'undefined')	{
				if(typeof console.dir == 'function' && typeof msg == 'object')	{
				//IE8 doesn't support console.dir.
					console.dir(msg);
					}
				else if(typeof console.dir == 'undefined' && typeof msg == 'object')	{
					//browser doesn't support writing object to console. probably IE8.
					console.log('object output not supported');
					}
				else
					console.log(msg);
				}
			}, //dump
//javascript doesn't have a great way of easily formatting a string as money.
//top that off with each browser handles some of these functions a little differently. nice.
	formatMoney : function(A, currencySign, decimalPlace,hideZero){
//		myControl.util.dump("BEGIN util.formatMoney");
		decimalPlace = isNaN(decimalPlace) ? decimalPlace : 2; //if blank or NaN, default to 2
		var r;
		var a = new Number(A);
		
		if(hideZero == true && (a * 1) == 0)	{
			r = '';
			}
		else	{
			
			var isNegative = false;
//only deal with positive numbers. makes the math work easier. add - sign at end.
//if this is changed, the a+b.substr(1) line later needs to be adjusted for negative numbers.
			if(a < 0)	{
				a = a * -1;
				isNegative = true;
				}
			
			var b = a.toFixed(decimalPlace); //get 12345678.90
//			myControl.util.dump(" -> b = "+b);
			a = parseInt(a); // get 12345678
			b = (b-a).toPrecision(decimalPlace); //get 0.90
			b = parseFloat(b).toFixed(decimalPlace); //in case we get 0.0, we pad it out to 0.00
			a = a.toLocaleString();//put in commas - IE also puts in .00, so we'll get 12,345,678.00
//			myControl.util.dump(" -> a = "+a);
			//if IE (our number ends in .00)
			if(a.indexOf('.00') > 0)	{
				a=a.substr(0, a.length-3); //delete the .00
//				myControl.util.dump(" -> trimmed. a. a now = "+a);
				}
			r = a+b.substr(1);//remove the 0 from b, then return a + b = 12,345,678.90
//			myControl.util.dump(" -> r = "+r);
			if(currencySign)	{
				r = currencySign + r;
				}
			if(isNegative)
				r = "-"+r;
			}
		return r
		}, //formatMoney

//used for validating strings only. checks to see if value is defined, not null, no false etc.
//returns value (s), if it has a value .
	isSet : function(s)	{
	//	zStdErr('in isSet for '+s);
		var r;
		if(s == null || s == 'undefined' || s == '')
			r = false;
		else if(typeof s != 'undefined')
			r = s;
		else
			r = false;
		return r;
		}, //isSet

/*
name is the image location/filename
a is an object.  ex:
"w":"300","h":"300","alt":"this is the alt text","name":"folder/filename","b":"FFFFFF"
supported attributes are:
w = width
h = height
b = bgcolor (used to pad if original image aspect ratio doesn't conform to aspect ratio passed into function. 
 -> use TTTTTT for transparent png (will result in larger file sizes)
class = css class
tag = boolean. Set to true to output the <img tag. set to false or blank to just get url
*/
		makeImage : function(a)	{
		//	myControl.util.dump('W = '+a.w+' and H = '+a.h);
			a.lib = myControl.util.isSet(a.lib) ? a.lib : myControl.vars.username;  //determine protocol
//			myControl.util.dump('library = '+a.lib);
			if(a.name == null)
				a.name = 'i/imagenotfound';
			
			var url, tag;
		
		//default height and width to blank. setting it to zero or NaN is bad for IE.
			if(a.h == null || a.h == 'undefined' || a.h == 0)
				a.h = '';
			if(a.w == null || a.w == 'undefined' || a.w == 0)
				a.w = '';
			
			url = location.protocol === 'https:' ? 'https:' : 'http:';  //determine protocol
			url += '\/\/static.zoovy.com\/img\/'+a.lib+'\/';
		
			if((a.w == '') && (a.h == ''))
				url += '-';
			else	{
				if(a.w)	{
					url += 'W'+a.w+'-';
					}
				if(a.h)	{
					url += 'H'+a.h+'-';
					}
				if(a.b)	{
					url += 'B'+a.b+'-';
					}
				}
		
			url += '\/'+a.name;
		
		//		myControl.util.dump(url);
			
			if(a.tag == true)	{
				a['class'] = typeof a['class'] == 'string' ? a['class'] : ''; //default class to blank
				a['id'] = typeof a['id'] == 'string' ? a['id'] : 'img_'+a.name; // default id to filename (more or less)
				a['alt'] = typeof a['alt'] == 'string' ? a['alt'] : a.name; //default alt text to filename
				var tag = "<img src='"+url+"' alt='"+a.alt+"' id='"+a['id']+"' class='"+a['class']+"' />";
				return tag;
				}
			else	{
				return url;
				}
			}, //makeImage





//simple text truncate. doesn't handle html tags.
//t = text to truncate. len = # chars to truncate to (100 = 100 chars)
		truncate : function(t,len)	{
			var r;
			if(!t){r = false}
			else if(!len){r = false}
			else if(t.length <= len){r = t}
			else	{
				var trunc = t;
				if (trunc.length > len) {
/* Truncate the content of the string, then go back to the end of the
previous word to ensure that we don't truncate in the middle of
a word */
					trunc = trunc.substring(0, len);
					trunc = trunc.replace(/\w+$/, '');
		
/* Add an ellipses to the end*/
					trunc += '...';
					r = trunc;
					}
				}
				return r;
			}, //truncate
			
		makeSafeHTMLId : function(string)	{
			var r;
			r = string.replace(/[^a-zA-Z 0-9 - _]+/g,'');
			return r;
			}, //makeSafeHTMLId

		isValidMonth : function(val)	{
			var valid = true;
			if(isNaN(val)){valid = false}
			else if(!myControl.util.isSet(val)){valid = false}
			else if(val > 12){valid = false}
			else if(val < 0){valid = false}
			return valid;
			}, //isValidMonth

		isValidCCYear : function (val)	{
			var valid = true;
			if(isNaN(val)){valid = false}
			else if(val.length != 4){valid = false}
			return valid;
			}, //isValidCCYear

		getCCExpYears : function (focusYear)	{
			var date = new Date();
			var year = date.getFullYear();
			var thisYear; //this year in the loop.
			var r = '';
			for(var i = 0; i < 11; i +=1)	{
				thisYear = year + i;
				r += "<option value='"+(thisYear)+"' id='ccYear_"+(thisYear)+"' ";
				if(focusYear*1 == thisYear)
					r += " selected='selected' ";
				r += ">"+(thisYear)+"</option>";
				}
			return r;
			}, //getCCYears

		getCCExpMonths : function(focusMonth)	{
			var r = "";
			var month=new Array(12);
			month[1]="January";
			month[2]="February";
			month[3]="March";
			month[4]="April";
			month[5]="May";
			month[6]="June";
			month[7]="July";
			month[8]="August";
			month[9]="September";
			month[10]="October";
			month[11]="November";
			month[12]="December";
			for(i = 1; i < 13; i += 1)	{
				r += "<option value='"+i+"' id='ccMonth_"+i+"' ";
				if(i == focusMonth)
					r += "selected='selected'";
				r += ">"+month[i]+" ("+i+")</option>";
				}
			return r;				
			},



/* This script and many more are available free online at
The JavaScript Source!! http://javascript.internet.com
Created by: David Leppek :: https://www.azcode.com/Mod10

Basically, the alorithum takes each digit, from right to left and muliplies each second
digit by two. If the multiple is two-digits long (i.e.: 6 * 2 = 12) the two digits of
the multiple are then added together for a new number (1 + 2 = 3). You then add up the 
string of numbers, both unaltered and new values and get a total sum. This sum is then
divided by 10 and the remainder should be zero if it is a valid credit card. Hense the
name Mod 10 or Modulus 10. */
		isValidCC : function (ccNumb) {  // v2.0
			var valid = "0123456789"  // Valid digits in a credit card number
			var len = ccNumb.length;  // The length of the submitted cc number
			var iCCN = parseInt(ccNumb);  // integer of ccNumb
			var sCCN = ccNumb.toString();  // string of ccNumb
			sCCN = sCCN.replace (/^\s+|\s+$/g,'');  // strip spaces
			var iTotal = 0;  // integer total set at zero
			var bNum = true;  // by default assume it is a number
			var bResult = false;  // by default assume it is NOT a valid cc
			var temp;  // temp variable for parsing string
			var calc;  // used for calculation of each digit
		
			// Determine if the ccNumb is in fact all numbers
			for (var j=0; j<len; j++) {
				temp = "" + sCCN.substring(j, j+1);
				if (valid.indexOf(temp) == "-1"){bNum = false;}
				}
		
			// if it is NOT a number, you can either alert to the fact, or just pass a failure
			if(!bNum){
				/*alert("Not a Number");*/bResult = false;
				}
		
		// Determine if it is the proper length 
			if((len == 0)&&(bResult)){  // nothing, field is blank AND passed above # check
				bResult = false;
				}
			else	{  // ccNumb is a number and the proper length - let's see if it is a valid card number
				if(len >= 15){  // 15 or 16 for Amex or V/MC
					for(var i=len;i>0;i--){  // LOOP throught the digits of the card
						calc = parseInt(iCCN) % 10;  // right most digit
						calc = parseInt(calc);  // assure it is an integer
						iTotal += calc;  // running total of the card number as we loop - Do Nothing to first digit
						i--;  // decrement the count - move to the next digit in the card
						iCCN = iCCN / 10;                               // subtracts right most digit from ccNumb
						calc = parseInt(iCCN) % 10 ;    // NEXT right most digit
						calc = calc *2;                                 // multiply the digit by two
		// Instead of some screwy method of converting 16 to a string and then parsing 1 and 6 and then adding them to make 7,
		// I use a simple switch statement to change the value of calc2 to 7 if 16 is the multiple.
						switch(calc){
							case 10: calc = 1; break;       //5*2=10 & 1+0 = 1
							case 12: calc = 3; break;       //6*2=12 & 1+2 = 3
							case 14: calc = 5; break;       //7*2=14 & 1+4 = 5
							case 16: calc = 7; break;       //8*2=16 & 1+6 = 7
							case 18: calc = 9; break;       //9*2=18 & 1+8 = 9
							default: calc = calc;           //4*2= 8 &   8 = 8  -same for all lower numbers
							}                                               
						iCCN = iCCN / 10;  // subtracts right most digit from ccNum
						iTotal += calc;  // running total of the card number as we loop
						}  // END OF LOOP
					if ((iTotal%10)==0){  // check to see if the sum Mod 10 is zero
						bResult = true;  // This IS (or could be) a valid credit card number.
						}
					else {
						bResult = false;  // This could NOT be a valid credit card number
						}
					}
				}
			return bResult; // Return the results
			}, //isValidCC

// http://blog.stevenlevithan.com/archives/validate-phone-number
		isValidPhoneNumber : function(phoneNumber,country)	{
//			myControl.util.dump('BEGIN myControl.util.isValidPhoneNumber. phone = '+phoneNumber);
			var r;

//if country is undefinded, treat as domestic.
			if(country == 'US' || !country)	{
				var regex = /^(?:\+?1[-. ]?)?\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/;
				
				}
			else	{var regex = /^(\+[1-9][0-9]*(\([0-9]*\)|-[0-9]*-))?[0]?[1-9][0-9\- ]*$/;}

			r = regex.test(phoneNumber)
//			myControl.util.dump("regex.text ="+r);
			
			return r;
			},

		//found here: http://www.blog.zahidur.com/usa-and-canada-zip-code-validation-using-javascript/
		 isValidPostalCode : function(postalCode,countryCode) {
			var postalCodeRegex;
			switch (countryCode) {
				case "US":
					postalCodeRegex = /^([0-9]{5})(?:[-\s]*([0-9]{4}))?$/;
					break;
				case "CA":
			/* postalCodeRegex = /^([A-Z][0-9][A-Z])\s*([0-9][A-Z][0-9])$/; */
					postalCodeRegex = /^([a-zA-Z][0-9][a-zA-Z])\s*([0-9][a-zA-Z][0-9])$/
					break;
				default:
					postalCodeRegex = /^(?:[A-Z0-9]+([- ]?[A-Z0-9]+)*)?$/;
				}
			return postalCodeRegex.test(postalCode);
			}, //isValidPostalCode


/*
executed during control init. 
for now, all it does is save the facebook user data as needed, if the user is authenticated.
later, it will handle other third party plugins as well.
*/
		handleThirdPartyInits : function()	{
//			myControl.util.dump("BEGIN myControl.util.handleThirdPartyInits");
//initial init of fb app.
			if(typeof zGlobals !== 'undefined' && zGlobals.thirdParty.facebook.appId && typeof FB !== 'undefined')	{
//				myControl.util.dump(" -> facebook appid set. load user data.");
				FB.init({appId:zGlobals.thirdParty.facebook.appId, cookie:true, status:true, xfbml:true});
				myControl.thirdParty.fb.saveUserDataToSession();
				}
			else	{
				myControl.util.dump(" -> did not init FB app because either appid isn't set or FB is undefined ("+typeof FB+").");
				}
//			myControl.util.dump("END myControl.util.handleThirdPartyInits");
			},

//executed inside handleTHirdPartyInits as well as after a facebook login.
//



//used in checkout to populate username: so either login or bill.email will work.
//never use this to populate the value of an email form field because it may not be an email address.
//later, this could be expanded to include a facebook id.
		getUsernameFromCart : function()	{
//			myControl.util.dump('BEGIN util.getUsernameFromCart');
			var r = false;
			if(myControl.util.isSet(myControl.data.showCart.cart['login']))	{
				r = myControl.data.showCart.cart['login'];
//				myControl.util.dump(' -> login was set. email = '+r);
				}
			else if(myControl.util.isSet(myControl.data.showCart.cart['data.bill_email'])){
				r = myControl.data.showCart.cart['data.bill_email'];
//				myControl.util.dump(' -> data.bill_email was set. email = '+r);
				}
			else if(!$.isEmptyObject(myControl.vars.fbUser))	{
//				myControl.util.dump(' -> user is logged in via facebook');
				r = myControl.vars.fbUser.email;
				}
			return r;
			}

		}, //util





					////////////////////////////////////   RENDERFUNCTIONS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\






	renderFunctions : {
		
//templateID should be set in the original html file (or generated with script and added to the dom). It is the layout/spec to be used.
//eleid is optional and allows for the instance of this template to have a unique id. used in 'lists' like results.
		createTemplateInstance : function(templateID,eleID)	{
			
//			myControl.util.dump('BEGIN myControl.renderFunctions.createTemplateInstance. ');
//			myControl.util.dump(' -> templateID: '+templateID);
//creates a copy of the template.
			var r = myControl.templates[templateID].clone();

			if(typeof eleID == 'string')	{
//				myControl.util.dump(" -> assigned a new id: "+eleID);
				r.attr('id',myControl.util.makeSafeHTMLId(eleID))  
				}
			else if(typeof eleID == 'object')	{
//!!! allow for more attributes to be set, such as data-sku, to be more flexible in allowing references.
//may eliminiate some need for renderformats to do simple things like 'onClick'.
//for now, only id and data-sku are accepted. if we stick with this, we'll add a loop to convert all.
				if(eleID.id)	{
//					myControl.util.dump(" -> assigned a new id: "+eleID);
					r.attr('id',myControl.util.makeSafeHTMLId(eleID.id));
					}
				if(eleID.pid)	{
//					myControl.util.dump(" -> assigned a data-pid attr: "+eleID.pid);
					r.attr('data-pid',myControl.util.makeSafeHTMLId(eleID.pid));
					}
				}
//			myControl.util.dump('END myControl.renderFunctions.createTemplateInstance.');
			return r;
			}, //createTemplateInstance

//each template may have a unique set of required parameters.
//this function should probably be moved to the controller.
/*
function parameters...

data
 -> this is one of the few cases that the datapointer is not used, in favor of the actual data. it's necessary to have the flexibility needed to translate a template. Otherwise a translator would be needed for each data type (cart, product, etc).

target
 -> right now, this just wants a string representing the target tag id.
 -> target should already have an empty template in place.
 -> at some point, target may support a jquery object. template could also be passed in and the object returned would be a populate template.

The code will loop through all first level children (only first level are subbed so far) and populate the tag based on the attribute set in data-attrib on the tag itself.


### NOTE

*/
		translateTemplate : function(data,target)	{
//		myControl.util.dump('BEGIN translateTemplate (target = '+target+')');
		var safeTarget = myControl.util.makeSafeHTMLId(target); //jquery doesn't like special characters in the id's.
		
//		myControl.util.dump(' -> safeTarget = '+safeTarget);
//		myControl.util.dump(data);
			
		var $divObj = $('#'+safeTarget); //jquery object of the target tag. template was already rendered to screen using createTemplate.
		var $focusTag; //this is the child tag currently in focus (a span, div or img), reset on each iteration through the children.

		var value;  //the actual value of the attribute (ex: 'this is my product name')
		
//locates all children/grandchildren/etc that have a data-bind attribute within the parent id.
		$divObj.find('*[data-bind]').each(function()	{
//			myControl.util.dump(' -> data-bind match found.');
			$focusTag = $(this);
//proceed if data-bind has a value (not empty).
//			myControl.util.dump(' -> data-bind attr: '+$focusTag.attr('data-bind'))
			if(myControl.util.isSet($focusTag.attr('data-bind'))){
				var bindData = myControl.renderFunctions.parseDataBind($focusTag.attr('data-bind'))  
//				myControl.util.dump(bindData);
				if(bindData['var'])	{
					value = myControl.renderFunctions.parseDataVar(bindData['var'],data);  //set value to the actual value
					}
				if(!value && bindData.defaultVar)	{
					value = myControl.renderFunctions.parseDataVar(bindData['defaultVar'],data);
//					myControl.util.dump(' -> used defaultVar because var had no value.');
					}
				if(!value && bindData.defaultValue)	{
					value = bindData['defaultValue']
//					myControl.util.dump(' -> used defaultValue ("'+bindData.defaultValue+'") because var had no value.');
					}
//in some cases, the format function needs a 'clean' version of the value, such as money.
//pre and post text are likely still necessary, but math or some other function may be needed prior to pre and post being added.
//in cases where cleanValue is used inside the renderFormats.function, pre and post text must also be added.
				bindData.cleanValue = value;
				}

// SANITY - value should be set by here. If not, likely this is a null value or isn't properly formatted.

//				myControl.util.dump(' -> value = '+value);
//				myControl.util.dump(' -> attribute = '+bindData['var']);
//				myControl.util.dump(' -> format = '+bindData.format);

//				myControl.util.dump(data);
//			myControl.util.dump(' -> value * 1 = '+(value * 1)+' and hideZero = '+bindData.hideZero);			

			if((value  == 0 || value == '0.00') && bindData.hideZero)	{
//				myControl.util.dump(' -> no pretext/posttext or anything else done because value = 0 and hideZero = '+bindData.hideZero);			
				}
			else if(value)	{
				
				if(myControl.util.isSet(bindData.className)){$focusTag.addClass(bindData.className)} //css class added if the field is populated. If the class should always be there, add it to the template.

				if(bindData.pretext){value = bindData.pretext + value}
				if(bindData.posttext){value += bindData.posttext}

				if(myControl.util.isSet(bindData.format)){
					if(bindData.extension && typeof myControl.extensions[bindData.extension].renderFormats[bindData.format] == 'function')	{
//						myControl.util.dump(" -> extension specified ("+bindData.extension+") and "+bindData.format+" is a function. executing.");
						myControl.extensions[bindData.extension].renderFormats[bindData.format]($focusTag,{"value":value,"bindData":bindData,"safeTarget":safeTarget,"attributes":data});
						}
					else if(typeof myControl.renderFormats[bindData.format] == 'function'){
//						myControl.util.dump(" -> no extension specified. "+bindData.format+" is a valid default function. executing.");
						myControl.renderFormats[bindData.format]($focusTag,{"value":value,"bindData":bindData,"safeTarget":safeTarget}); 
						}
					else	{
//						myControl.util.dump(" -> "+bindData.format+" is not a valid format. extension = "+bindData.extension);
//						myControl.util.dump(bindData);
						}
//					myControl.util.dump(' -> custom display function "'+bindData.format+'" is defined');
					
					}
				}
			else	{
//				myControl.util.dump(' -> data-bind is set, but it has no/invalid value.');
				}
			value = ''; //reset value.
			}); //end each for children.
		$divObj.removeClass('loadingBG');
//		myControl.util.dump('END translateTemplate');
		}, //translateTemplate
		
		
//as part of the data-bind is a var: for the data location (product: or cart:).
//this is used to parse that to get to the data.
//if no namespace is passed (zoovy: or user:) then the 'root' of the object is used.
//%attribs is passed in a cart spec because that's where the data is stored.
		parseDataVar : function(v,data)	{
			var value;
			var attributeID = v.replace(/.*\(|\)/gi,''); //used to store the attribute id (ex: zoovy:prod_name), not the actual value.
			var namespace = v.split('(')[0];
//myControl.util.dump('BEGIN myControl.renderFunctions.parseDataVar');
//myControl.util.dump(' -> attributeID = '+attributeID);
//myControl.util.dump(' -> namespace = '+namespace);

			 
			if(!v || !data)	{
				value = false;
				}
			else	{
//				myControl.util.dump(' -> attribute info and data are both set.');
				
//In some cases, like categories, some data is in the root and some is in %meta.
//pass %meta.cat_thumb, for instance.  currenlty, only %meta is supported. if/when another %var is needed, this'll need to be expanded. !!!
//just look for % to be the first character.  Technically, we could deal with prod info this way, but the method in place is fewer characters
				if(attributeID.charAt(0) === '%')	{
					myControl.util.dump(' -> % attribute = '+attributeID.substr(6));
					value = data['%meta'][attributeID.substr(6)];
					myControl.util.dump(" -> value = "+value);
					}

//if the attribute ID contains a semi colon, than an attribute (such as product: or profile:) is being referenced. 
// sometimes an attribute is not used, such as sku or reviews, or when using sku to execute another display function (ex: add to cart).
// technically, these would fall under the 'else', but I want to keep them separate now... for comfort. 2011-09-29
				else if(attributeID.indexOf(':') < 0)	{
//					myControl.util.dump(' -> attribute does not contain :');
					value = data[attributeID]
					}
				else if(namespace == 'product')	{
					value = data['%attribs'][attributeID];
					}
	//it's assumed at this point in the history of time that if a product isn't in focus, the data is not in a sub node (like %attribs).
	//if subnodes are used, they'll need to be added as an 'else if' above.
				else	{
					value = data[attributeID]
					}
				}
			return value;
			},

//this parses the 'css-esque' format of the data-bind.  It's pretty simple (fast) but will not play well if a : or ; is in any of the values.
//css can be used to add or remove those characters for now.
//will convert key/value pairs into an object.
		parseDataBind : function(data)	{
//			myControl.util.dump('BEGIN parseDataBind');
			var rule = {};
			if(data)	{
				var declarations = data.split(';');
				declarations.pop();
				var len = declarations.length;
				for (var i = 0; i < len; i++)	{
					var loc = declarations[i].indexOf(':'); //splits at first :. this may mean : in the values is okay. test.
//remove whitespace from property otherwise could get invalid 'key'.
					var property = $.trim(declarations[i].substring(0, loc)); 
//					var value = $.trim(declarations[i].substring(loc + 1));  //commented out 12/15/12. may want a space in the value.
					var value = declarations[i].substring(loc + 1);
//						myControl.util.dump(' -> property['+i+']: '+property);
//						myControl.util.dump(' -> value['+i+']: "'+value+'"');
					if (property != "" && value != "")	{
//						rule[property] = value;
//need to trim whitespace from values except pre and post text. having whitespace in the value causes things to not load. However, it's needed in pre and post text.
						rule[property] = (property != 'pretext' && property != 'posttext') ? $.trim(value) : value; 
						}
					}
				}

//			myControl.util.dump('END parseDataBind');
			return rule;
			}


	
		}, //renderFunctions


					////////////////////////////////////   renderFormats    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

	renderFormats : {

		imageURL : function($tag,data){
//				myControl.util.dump('got into displayFunctions.image: "'+data.value+'"');
			var imgSrc = myControl.util.makeImage({'tag':0,'w':$tag.width(),'h':$tag.height(),'name':data.value});
//				myControl.util.dump('IMGSRC => '+imgSrc);
			$tag.attr('src',imgSrc);
			}, //imageURL
			
		truncText : function($tag,data){
			var o = myControl.util.truncate(data.value,data.bindData.numCharacters)
			$tag.text(o);
			}, //truncText
//formerly bindClick. don't think it's in use anymore. commented out on 12/29/2011
/*
		bindWindowOpen : function($tag,data)	{
			myControl.util.dump('BEGIN myControl.renderFormats.bindWindowOpen');
			data.windowName = myControl.util.isSet(data.windowName) ? data.windowName : '';//default to blank window name, not 'null' or 'undefined'
			$tag.click(function(){window.open(data.value),data.windowName});
			}, //bindWindowOpen
*/
//used in a cart or invoice spec to display which options were selected for a stid.
		selectedOptionsDisplay : function($tag,data)	{
			var o = '';
			for(var key in data.value) {
//				myControl.util.dump("in for loop. key = "+key);
				o += "<div><span class='prompt'>"+data.value[key]['prompt']+"<\/span> <span class='value'>"+data.value[key]['value']+"<\/span><\/div>";
				}
			$tag.html(o);
			},

	
		text : function($tag,data){
			var o = '';
			if($.isEmptyObject(data.bindData))	{o = data.value}
			else	{
				o += data.value;
				}
			$tag.text(o);
			}, //text
//for use on inputs. populates val() with the value
		popVal : function($tag,data){
			$tag.val(data.value);
			}, //text

		money : function($tag,data)	{
			
//			myControl.util.dump('BEGIN view.formats.money');
//			myControl.util.dump(' -> value = "'+data.value+'" and cleanValue = '+data.bindData.cleanValue);
			var amount = data.bindData.cleanValue;
			if(amount)	{
				var r;
				r = myControl.util.formatMoney(amount,data.bindData.currencySign,'',data.bindData.hideZero);
				if(data.bindData.pretext){r = data.bindData.pretext + r}
				if(data.bindData.posttext){r += data.bindData.posttext}
//					myControl.util.dump(' -> attempting to use var. value: '+data.value);
//					myControl.util.dump(' -> currencySign = "'+data.bindData.currencySign+'"');
//					myControl.util.dump(' -> pretext = '+data.bindData.pretext);
//					myControl.util.dump(' -> posttext = '+data.bindData.posttext);
//					myControl.util.dump(' -> r = '+r);
				$tag.text(r)
				}
			} //money

			
		},





////////////////////////////////////   						STORAGEFUNCTIONS						    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
					
					
	storageFunctions : {
		
		// SANITY -> readlocal does not work if testing locally in FF or IE, must be on a website. Safari does support local file local storage

		writeLocal : function (key,value)	{
		//	myControl.util.dump("WRITELOCAL: Key = "+key);
			var r = false;
			if('localStorage' in window && window['localStorage'] !== null && typeof localStorage != 'undefined')	{
				r = true;
				if (typeof value == "object") {
					value = JSON.stringify(value);
					}
//				localStorage.removeItem(key);//this was an attempt to fix an ios issue. it wreaked havoc in IE. do not use.
// this 'try' was added on 2012-01-30 to solve an IOS/safari 'out of space' error. cause by a full localStorage or 'private' browsing.
				try	{
					localStorage.setItem(key, value);
					}
				catch(err)	{
					myControl.util.dump(' -> localStorage defined but no available (no space? no write permissions?)');
					}
				
				}
			return r;
			}, //writeLocal
		
		readLocal : function(key)	{
		//	myControl.util.dump("GETLOCAL: key = "+key);
			if(typeof localStorage == 'undefined')	{
				return myControl.storageFunctions.readCookie(key); //return blank if no cookie exists. needed because getLocal is used to set vars in some if statements and 'null'	
				}
			else	{
				var value = localStorage.getItem(key);
				if(value == null)	{
					return myControl.storageFunctions.readCookie(key);
					}
		// assume it is an object that has been stringified
				if(value && value[0] == "{") {
					value = JSON.parse(value);
					}
				return value
				}
			}, //readLocal

// read this.  see if there's a better way of handing cookies using jquery.
//http://www.jquery4u.com/data-manipulation/jquery-set-delete-cookies/
		readCookie : function(c_name){
			var i,x,y,ARRcookies=document.cookie.split(";");
			for (i=0;i<ARRcookies.length;i++)	{
				x=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
				y=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
				x=x.replace(/^\s+|\s+$/g,"");
				if (x==c_name)	{
					return unescape(y);
					}
				}
			return false;  //return false if not set.
			}

		}, //storageFunctions
	
	


////////////////////////////////////   			thirdPartyFunctions		    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



	thirdParty : {
		
		fb : {
			
			postToWall : function(msg)	{
				myControl.util.dump('BEGIN thirdpartyfunctions.facebook.posttowall. msg = '+msg);
				FB.ui({ method : "feed", message : msg}); // name: 'Facebook Dialogs', 
				},
			
			share : function(a)	{
				a.method = 'send';
				FB.ui(a);
				},
				
		
			saveUserDataToSession : function()	{
//				myControl.util.dump("BEGIN myControl.thirdParty.fb.saveUserDataToSession");
				
				FB.Event.subscribe('auth.statusChange', function(response) {
//					myControl.util.dump(" -> FB response changed. status = "+response.status);
					if(response.status == 'connected')	{
	//save the fb user data elsewhere for easy access.
						FB.api('/me',function(user) {
							if(user != null) {
//								myControl.util.dump(" -> FB.user is defined.");
								myControl.vars.fbUser = user;
								myControl.calls.setSessionVars.init({"data.bill_email":user.email});

//								myControl.util.dump(" -> user.gender = "+user.gender);

if(_gaq.push(['_setCustomVar',1,'gender',user.gender,1]))
	myControl.util.dump(" -> fired a custom GA var for gender.");
else
	myControl.util.dump(" -> ARGH! GA custom var NOT fired. WHY!!!");


								}
							});
						}
					});
//				myControl.util.dump("END myControl.thirdParty.fb.saveUserDataToSession");
				}
			}
		},


////////////////////////////////////   						sharedCheckoutUtilities				    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

/*
these functions are fairly generic and contain no extentension specific calls.
some id's may be hard coded (can change this later if need be), but they're form field id's(bill_email), fieldsets, or obvious enough to be shared(addresses)
*/




	sharedCheckoutUtilities : 	{
//pretty straightforward. If a cid is set, the session has been authenticated.
//if the cid is in the cart/local but not the control, set it. most likely this was a cart passed to us where the user had already logged in or (local) is returning to the checkout page.
//if no cid but email, they are a guest.
//if logged in via facebook, they are a thirdPartyGuest.
//this could easily become smarter to take into account the timestamp of when the session was authenticated.
			
			determineAuthentication : function(){
				var r = 'none';
//was running in to an issue where cid was in local, but user hadn't logged in to this session yet, so now both cid and username are used.
				if(myControl.vars.cid && myControl.util.getUsernameFromCart())	{r = 'authenticated'}
				else if(myControl.model.fetchData('showCart') && myControl.util.isSet(myControl.data.showCart.cart.cid))	{
					r = 'authenticated';
					myControl.vars.cid = myControl.data.showCart.cart.cid;
					}

//need to run third party checks prior to default 'guest' check because data.bill_email will get set for third parties
//and all third parties would get 'guest'
				else if(FB && !$.isEmptyObject(FB) && FB['_userStatus'] == 'connected')	{
					r = 'thirdPartyGuest';
//					myControl.thirdParty.fb.saveUserDataToSession();
					}
				else if(myControl.model.fetchData('showCart') && myControl.data.showCart.cart['data.bill_email'])	{
					r = 'guest';
					}
				else	{
					//catch.
					}
//				myControl.util.dump('myControl.sharedCheckoutUtilities.determineAuthentication run. authstate = '+r); 

				return r;
				},

/*
sometimes _is_default is set for an address in the list of bill/ship addresses.
sometimes it isn't. sometimes, apparently, it's set more than once.
this function closely mirrors core logic.
*/
			fetchPreferredAddress : function(TYPE)	{
//				myControl.util.dump("BEGIN sharedCheckoutUtilities.fetchPreferredAddress  ("+TYPE+")");
				var r = false; //what is returned
				if(!TYPE){ r = false}
				else	{
					var L = myControl.data.getCustomerAddresses['@'+TYPE].length;
//look to see if a default is set. if so, take the first one.
					for(var i = 0; i < L; i += 1)	{
						if(myControl.data.getCustomerAddresses['@'+TYPE][i]['_is_default'] == 1)	{
							r = myControl.data.getCustomerAddresses['@'+TYPE][i]['_id'];
							break; //no sense continuing the loop.
							}
						}
//if no default is set, use the first address.
					if(r == false)	{
						r =myControl.data.getCustomerAddresses['@'+TYPE][0]['_id']
						}
					}
//				myControl.util.dump("address id = "+r);
				
				return r;
				},



	

				
//sets the values of the shipping address to what is set in the billing address fields.
//can't recycle the setAddressFormFromPredefined here because it may not be a predefined address.
			setShipAddressToBillAddress : function()	{
//				myControl.util.dump('BEGIN sharedCheckoutUtilities.setShipAddressToBillAddress');
				$('#chkoutBillAddressFieldset > ul').children().children().each(function() {
					if($(this).is(':input')){$('#'+this.id.replace('bill_','ship_')).val(this.value)}
					});
				},


//allows for setting of 'ship' address when 'ship to bill' is clicked and a predefined address is selected.
			setAddressFormFromPredefined : function(addressType,addressId)	{
//				myControl.util.dump('BEGIN sharedCheckoutUtilities.setAddressFormFromPredefined');
//				myControl.util.dump(' -> address type = '+addressType);
//				myControl.util.dump(' -> address id = '+addressId);
				
				var L = myControl.data.getCustomerAddresses['@'+addressType].length
				var a,i;
				var r = false;
//looks through predefined addresses till it finds a match for the address id. sets a to address object.
				for(i = 0; i < L; i += 1)	{
					if(myControl.data.getCustomerAddresses['@'+addressType][i]['_id'] == addressId){
						a = myControl.data.getCustomerAddresses['@'+addressType][i];
						r = true;
						break;
						}
					}
				
//				myControl.util.dump(' -> a = ');
//				myControl.util.dump(a);
				$('#data-'+addressType+'_address1').val(a[addressType+'_address1']);
				if(myControl.util.isSet(a[addressType+'_address2'])){$('#data-'+addressType+'_address2').val(a[addressType+'_address2'])};
				$('#data-'+addressType+'_city').val(a[addressType+'_city']);
				$('#data-'+addressType+'_state').val(a[addressType+'_state']);
				$('#data-'+addressType+'_zip').val(a[addressType+'_zip']);
				$('#data-'+addressType+'_country').val(a[addressType+'_country'] ? a[addressType+'_country'] : "US"); //country is sometimes blank. This appears to mean it's a US company?
				$('#data-'+addressType+'_firstname').val(a[addressType+'_firstname']);
				$('#data-'+addressType+'_lastname').val(a[addressType+'_lastname']);
				if(myControl.util.isSet(a[addressType+'_phone'])){$('#data-'+addressType+'_phone').val(a[addressType+'_phone'])};
				return r;
				}, //setAddressFormFromPredefined


//will blank all fields in a fieldset. in theory, this would work even on a non-address field but not tested.
			resetAddress : function(fieldsetId)	{
				$('#'+fieldsetId+' :input').each(function() {
					if ($(this).is('select')) {
						$(this).val($(this).find('option[selected]').val());
						}
					else {
						$(this).val(this.defaultValue);
						}
					});
				} //resetAddress

		} //sharedCheckoutUtilities
	

	});

