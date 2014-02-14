zController=function(params,extensions){this.util.dump('zController has been initialized');if(typeof Prototype=='object'){alert("Oh No! you appear to have the prototype ajax library installed. This library is not compatible. Please change to a non-prototype theme (2011 series).");}
else{this.initialize(params,extensions);}}
$.extend(zController.prototype,{initialize:function(P,E){myControl=this;myControl.model=zoovyModel();myControl.vars={};myControl.vars['_admin']=null;myControl.vars.cid=null;myControl.vars.fbUser={};myControl.vars.profile=zGlobals.appSettings.profile;myControl.vars.username=zGlobals.appSettings.username;myControl.vars.secureURL=zGlobals.appSettings.https_app_url;myControl.vars.sdomain=zGlobals.appSettings.sdomain;if('https:'==document.location.protocol){myControl.vars.jqurl=zGlobals.appSettings.https_api_url;}
else{myControl.vars.jqurl=zGlobals.appSettings.http_api_url}
myControl.vars.passInDispatchV='';myControl.vars.release='unspecified';myControl.vars=$.extend(myControl.vars,P);myControl.vars.passInDispatchV+=myControl.util.getBrowserInfo()+";OS:"+myControl.util.getOSInfo()+';';myControl.ext={};myControl.data={};myControl.util.dump(' -> v: '+myControl.model.version+'.'+myControl.vars.release);myControl.templates={};myControl.q={};myControl.q.mutable=new Array();myControl.q.passive=new Array();myControl.q.immutable=new Array();myControl.ajax={};myControl.ajax.overrideAttempts=0;myControl.ajax.lastDispatch=null;myControl.ajax.requests={"mutable":{},"immutable":{},"passive":{}};myControl.sessionId;if(P.noVerifyzjsid&&P.sessionId){myControl.sessionId=P.sessionId}
else if(P.noVerifyzjsid){}
else{P.sessionId?myControl.calls.appCartExists.init(P.sessionId,{'callback':'handleTrySession','datapointer':'appCartExists'}):myControl.calls.getValidSessionID.init('handleNewSession');myControl.model.dispatchThis('immutable');}
myControl.util.handleThirdPartyInits();if(E&&E.length>0){myControl.model.addExtensions(E);}},calls:{authentication:{facebook:{init:function(tagObj){myControl.util.dump('BEGIN myControl.calls.authentication.facebook.init');_gaq.push(['_trackEvent','Authentication','User Event','Logged in through Facebook']);this.dispatch(tagObj);return 1;},dispatch:function(tagObj){myControl.model.addDispatchToQ({'_cmd':'appVerifyTrustedPartner','partner':'facebook','appid':zGlobals.thirdParty.facebook.appId,'token':FB['_authResponse'].accessToken,'state':myControl.sessionID,"_tag":tagObj},'immutable');}},zoovy:{init:function(obj,tagObj){myControl.calls.cartSet.init({"data.bill_email":obj.login})
this.dispatch(obj,tagObj);return 1;},dispatch:function(obj,tagObj){obj["_cmd"]="appBuyerLogin";obj['method']="unsecure";obj["_tag"]=tagObj;obj["_tag"]["datapointer"]="appBuyerLogin";myControl.model.addDispatchToQ(obj,'immutable');}},zoovyLogout:{init:function(tagObj){this.dispatch(tagObj);return 1;},dispatch:function(tagObj){myControl.model.addDispatchToQ({'_cmd':'buyerLogout',"_tag":tagObj},'immutable');}},appAdminInit:{init:function(){$('#loginFormContainer .button').attr('disabled','disabled').addClass('ui-state-disabled');$('#loginFormContainer .zMessage').empty().remove();this.dispatch();return 1;},dispatch:function(){myControl.model.addDispatchToQ({"_cmd":"appAdminInit","login":$('#loginFormLogin').val(),"_tag":{"callback":"handleNewAdminResponse","datapointer":"appAdminInit"}},'immutable');}},appAdminAuthenticate:{init:function(obj){this.dispatch(obj);return 1;},dispatch:function(obj){obj["_tag"]={};obj["_cmd"]="appAdminAuthenticate";obj["_tag"].callback="handlePasswordResponse";myControl.model.addDispatchToQ(obj,'immutable');}}},getValidSessionID:{init:function(callback){var sid=myControl.model.fetchSessionId();if(sid){myControl.calls.appCartExists.init(sid,{'callback':'handleTrySession','datapointer':'appCartExists'});}
else{this.dispatch(callback);}
return 1;},dispatch:function(callback){myControl.model.addDispatchToQ({"_cmd":"appCartCreate","_tag":{"callback":callback}},'immutable');}},appCartExists:{init:function(zjsid,tagObj){myControl.sessionId=zjsid;this.dispatch(zjsid,tagObj);return 1;},dispatch:function(zjsid,tagObj){var obj={};obj["_cmd"]="appCartExists";obj["_zjsid"]=zjsid;obj["_tag"]=tagObj;myControl.model.addDispatchToQ(obj,'immutable');}},whoAmI:{init:function(tagObj,Q){var r=1;this.dispatch(tagObj,Q);return r;},dispatch:function(tagObj,Q){tagObj=$.isEmptyObject(tagObj)?{}:tagObj;tagObj.datapointer="whoAmI"
myControl.model.addDispatchToQ({"_cmd":"whoAmI","_zjsid":myControl.sessionId,"_tag":tagObj},Q);}},canIUse:{init:function(flag,Q){this.dispatch(flag,Q);return 1;},dispatch:function(flag,Q){myControl.model.addDispatchToQ({"_cmd":"canIUse","flag":flag,"_tag":{"datapointer":"canIUse|"+flag}},Q);}},cartSet:{init:function(obj,tagObj){this.dispatch(obj,tagObj);return 1;},dispatch:function(obj,tagObj){obj["_cmd"]="cartSet";if(tagObj){obj["_tag"]=tagObj;}
myControl.model.addDispatchToQ(obj,'immutable');}},ping:{init:function(tagObj,Q){this.dispatch(tagObj,Q);return 1;},dispatch:function(tagObj,Q){myControl.model.addDispatchToQ({"_cmd":"ping","_tag":tagObj},Q);}},appCartCreate:{init:function(callback){this.dispatch(callback);return 1;},dispatch:function(callback){myControl.model.addDispatchToQ({"_cmd":"appCartCreate","_tag":{"callback":callback}},'immutable');}},appProfileInfo:{init:function(profileID,tagObj,Q){var r=0;tagObj=typeof tagObj=='object'?tagObj:{};tagObj.datapointer='appProfileInfo|'+profileID;if(myControl.model.fetchData(tagObj.datapointer)==false){r=1;this.dispatch(profileID,tagObj,Q);}
else{myControl.util.handleCallback(tagObj)}
return r;},dispatch:function(profileID,tagObj,Q){obj={};obj['_cmd']="appProfileInfo";obj['profile']=profileID;obj['_tag']=tagObj;myControl.model.addDispatchToQ(obj,Q);}},refreshCart:{init:function(tagObj,Q){var r=1;tagObj=$.isEmptyObject(tagObj)?{}:tagObj;tagObj.datapointer="cartItemsList";this.dispatch(tagObj,Q);return r;},dispatch:function(tagObj,Q){myControl.model.addDispatchToQ({"_cmd":"cartItemsList","_zjsid":myControl.sessionId,"_tag":tagObj},Q);}}},callbacks:{handleNewAdminResponse:{onSuccess:function(tagObj){myControl.util.dump('BEGIN myControl.callbacks.handleNewAdminResponse.onSuccess');var obj={};myControl.sessionId=myControl.data[tagObj.datapointer]['_zjsid'];obj['_zjsid']=myControl.data[tagObj.datapointer]['_zjsid'];obj.hashtype='md5';obj.login=$('#loginFormLogin').val();obj.hashpass=Crypto.MD5($('#loginFormPassword').val()+myControl.data[tagObj.datapointer]['_zjsid']);myControl.calls.authentication.appAdminAuthenticate.init(obj);myControl.model.dispatchThis('immutable');},onError:function(responseData){myControl.util.dump('BEGIN myControl.callbacks.handleNewAdminResponse.onError');$('#loginFormContainer .button').removeAttr('disabled').removeClass('ui-state-disabled');$('#loginFormContainer').prepend(myControl.util.getResponseErrors(responseData)).toggle(true);}},handlePasswordResponse:{onSuccess:function(tagObj){myControl.util.dump("session ID from cookie (with timeout) "+myControl.storageFunctions.readCookie('zjsid'));setTimeout("window.location = 'https://www.zoovy.com/biz/'",2000);},onError:function(responseData){myControl.util.dump('BEGIN myControl.callbacks.handlePasswordResponse.onError');$('#loginFormContainer').prepend(myControl.util.getResponseErrors(responseData)).toggle(true);}},handleNewSession:{onSuccess:function(tagObj){myControl.util.dump('BEGIN myControl.callbacks.handleNewSession.onSuccess');},onError:function(responseData){myControl.util.dump('BEGIN myControl.callbacks.handleNewSession.onError');$('#globalMessaging').append(myControl.util.getResponseErrors(responseData)).toggle(true);}},handleTrySession:{onSuccess:function(tagObj){if(myControl.data.appCartExists.exists==1){}
else{}},onError:function(responseData){$('#globalMessaging').toggle(true).append(myControl.util.getResponseErrors(responseData));myControl.sessionId=null;}},handleAdminSession:{onSuccess:function(tagObj){myControl.util.dump('BEGIN myControl.callbacks.handleAdminSession.onSuccess');},onError:function(responseData){myControl.util.dump('BEGIN myControl.callbacks.handleAdminSession.onError');$('#globalMessaging').append(myControl.util.getResponseErrors(responseData)).toggle(true);}},translateTemplate:{onSuccess:function(tagObj){var dataSrc;if(tagObj.datapointer=='cartItemsList'){dataSrc=myControl.data[tagObj.datapointer].cart}
else if(tagObj.datapointer.indexOf('appPageGet')>=0){dataSrc=myControl.data[tagObj.datapointer]['%page']}
else{dataSrc=myControl.data[tagObj.datapointer]};myControl.renderFunctions.translateTemplate(dataSrc,tagObj.parentID);},onError:function(responseData){$('#'+responseData.tagObj.parentID).empty().toggle(true)
myControl.util.handleErrors(responseData,uuid)}},showMessaging:{onSuccess:function(tagObj){if(tagObj.parentID){var htmlid='random_'+Math.floor(Math.random()*10001);$('#'+tagObj.parentID).prepend(myControl.util.formatMessage({'message':tagObj.message,'htmlid':htmlid,'uiIcon':'check','timeoutFunction':"$('#"+htmlid+"').slideUp(1000);"}));}
else if(tagObj.targetID){$('#'+tagObj.targetID).append(myControl.util.formatMessage({'message':tagObj.message,'uiIcon':'check'}));}},onError:function(responseData,uuid){myControl.util.handleErrors(responseData,uuid)}}},util:{handleCallback:function(tagObj){var callback;if(tagObj&&tagObj.datapointer){myControl.data[tagObj.datapointer]['_rtag']=tagObj}
if(tagObj&&tagObj.callback){callback=tagObj.extension?myControl.ext[tagObj.extension].callbacks[tagObj.callback]:myControl.callbacks[tagObj.callback];if(typeof callback.onSuccess=='function')
callback.onSuccess(tagObj);}
else{}},logBuyerOut:function(){myControl.calls.authentication.zoovyLogout.init({'callback':'showMessaging','message':'Thank you, you are now logged out','targetID':'logMessaging'});myControl.calls.refreshCart.init({},'immutable');myControl.vars.cid=null;myControl.model.dispatchThis('immutable');},thisIsAnAdminSession:function(){var r=false;if(myControl.sessionId&&myControl.sessionId.substring(0,2)!='**'){r=true;}
return r;},jumpToAnchor:function(id){window.location.hash=id;},handleErrors:function(d,uuid){myControl.util.dump("BEGIN control.util.handleErrors for uuid: "+uuid);var $target;if(!d||!d['_rtag']){myControl.util.dump(" -> responseData (d) or responseData['_rtag'] is blank.");var DQ=myControl.model.whichQAmIFrom(uuid);d['_rtag']=myControl.q[DQ][uuid]['_tag'];}
if(d['_rtag'].targetID){$target=$('#'+d['_rtag'].targetID)}
else if(d['_rtag'].parentID){$target=$('#'+d['_rtag'].parentID)}
else{$target=$('#globalMessaging')}
if($target.length==0){$target=$("<div \/>").dialog({modal:true,width:500,height:500}).appendTo('body');}
$target.removeClass('loadingBG').show().append(this.getResponseErrors(d));},getResponseErrors:function(d){var r;if(!d){r='unknown error has occured';}
else if(typeof d=='string'){r=d;}
else if(typeof d=='object'){r="";if(d['_msgs']){for(var i=1;i<=d['_msgs'];i+=1){myControl.util.dump(d['_msg_'+i+'_type']+": "+d['_msg_'+i+'_id']);r+="<div>"+d['_msg_'+i+'_txt']+"<\/div>";}}
else if(d['errid']>0){r+="<div>"+d.errmsg+" ("+d.errid+")<\/div>";}}
else{myControl.util.dump(" -> getResponseErrors 'else' hit. Should not have gotten to this point");r='unknown error has occured';}
return myControl.util.formatMessage(r);},formatMessage:function(messageData){var obj={};if(typeof messageData=='string'){obj.message=messageData;obj.uiClass='highlight';obj.uiIcon='info';}
else{obj=messageData;obj.uiClass=obj.uiClass?obj.uiClass:'highlight';obj.uiIcon=obj.uiIcon?obj.uiIcon:'notice'}
var r=obj.htmlid?"<div class='ui-widget zMessage' id='"+obj.htmlid+"'>":"<div class='ui-widget zMessage'>";r+="<div class='ui-state-"+obj.uiClass+" ui-corner-all appMessage'>";r+="<div class='clearfix'><span style='float: left; margin-right: .3em;' class='ui-icon ui-icon-"+obj.uiIcon+"'></span><div style='float:left;' >"+obj.message+"<\/div><\/div>";r+="<\/div><\/div>";if(obj.htmlid&&obj.timeoutFunction){setTimeout(obj.timeoutFunction,6000);}
return r;},getParameterByName:function(name){name=name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");var regexS="[\\?&]"+name+"=([^&#]*)";var regex=new RegExp(regexS);var results=regex.exec(window.location.href);if(results==null)
return"";else
return decodeURIComponent(results[1].replace(/\+/g," "));},getParametersAsObject:function(string){var url=string?string:location.search;myControl.util.dump(url);var params={};if(string||url.indexOf('?')>0){url=url.replace('?','');var queries=url.split('&');for(var q in queries){var param=queries[q].split('=');params[param[0]]=decodeURIComponent(param[1].replace(/\+/g," "));}}
return params;},removeDuplicatesFromArray:function(arrayName){var newArray=new Array();label:for(var i=0;i<arrayName.length;i++){for(var j=0;j<newArray.length;j++){if(newArray[j]==arrayName[i])
continue label;}
newArray[newArray.length]=arrayName[i];}
return newArray;},getBrowserInfo:function(){var r;var BI=jQuery.browser;jQuery.each(BI,function(i,val){if(val===true){r='browser:'+i;}});r+='-'+BI.version;return r;},getOSInfo:function(){var OSName="Unknown OS";if(navigator.appVersion.indexOf("Win")!=-1)OSName="Windows";if(navigator.appVersion.indexOf("Mac")!=-1)OSName="MacOS";if(navigator.appVersion.indexOf("X11")!=-1)OSName="UNIX";if(navigator.appVersion.indexOf("Linux")!=-1)OSName="Linux";return OSName;},numbersOnly:function(e){var unicode=e.charCode?e.charCode:e.keyCode
if(unicode<8||unicode>9){if(unicode<48||unicode>57)
return false}},unixNow:function(){return Math.round(new Date().getTime()/1000.0)},unix2Pretty:function(unix_timestamp,showtime){var date=new Date(Number(unix_timestamp)*1000);var r;r=myControl.util.jsMonth(date.getMonth());r+=' '+date.getDate();r+=', '+date.getFullYear();if(showtime){r+=date.getHours();r+=':'+date.getMinutes();}
return r;},jsMonth:function(m){var month=new Array();month[0]="Jan.";month[1]="Feb.";month[2]="Mar.";month[3]="Apr.";month[4]="May";month[5]="June";month[6]="July";month[7]="Aug.";month[8]="Sep.";month[9]="Oct.";month[10]="Nov.";month[11]="Dec.";return month[m];},isValidEmail:function(str){myControl.util.dump("BEGIN isValidEmail for: "+str);var r=true;if(!str||str==false)
r=false;var at="@"
var dot="."
var lat=str.indexOf(at)
var lstr=str.length
var ldot=str.indexOf(dot)
if(str.indexOf(at)==-1){myControl.util.dump(" -> email does not contain an @");r=false}
if(str.indexOf(at)==-1||str.indexOf(at)==0||str.indexOf(at)==lstr){myControl.util.dump(" -> @ in email is in invalid location (first or last)");r=false}
if(str.indexOf(dot)==-1||str.indexOf(dot)==0||str.indexOf(dot)==lstr){myControl.util.dump(" -> email does not have a period or it is in an invalid location (first or last)");r=false}
if(str.indexOf(at,(lat+1))!=-1){myControl.util.dump(" -> email contains two @");r=false}
if(str.substring(lat-1,lat)==dot||str.substring(lat+1,lat+2)==dot){myControl.util.dump(" -> email contains multiple periods");r=false}
if(str.indexOf(dot,(lat+2))==-1){r=false}
if(str.indexOf(" ")!=-1){r=false}
myControl.util.dump("util.isValidEmail: "+r);return r;},dump:function(msg){if(typeof console!='undefined'){if(typeof console.dir=='function'&&typeof msg=='object'){console.dir(msg);}
else if(typeof console.dir=='undefined'&&typeof msg=='object'){console.log('object output not supported');}
else
console.log(msg);}},formatMoney:function(A,currencySign,decimalPlace,hideZero){decimalPlace=isNaN(decimalPlace)?decimalPlace:2;var r;var a=new Number(A);if(hideZero==true&&(a*1)==0){r='';}
else{var isNegative=false;if(a<0){a=a*-1;isNegative=true;}
var b=a.toFixed(decimalPlace);a=parseInt(a);b=(b-a).toPrecision(decimalPlace);b=parseFloat(b).toFixed(decimalPlace);a=a.toLocaleString();if(a.indexOf('.00')>0){a=a.substr(0,a.length-3);}
r=a+b.substr(1);if(r.split('.')[0]==0){r='.'+r.split('.')[1]}
if(currencySign){r=currencySign+r;}
if(isNegative)
r="-"+r;}
return r},isSet:function(s){var r;if(s==null||s=='undefined'||s=='')
r=false;else if(typeof s!='undefined')
r=s;else
r=false;return r;},makeImage:function(a){a.lib=myControl.util.isSet(a.lib)?a.lib:myControl.vars.username;a.m=a.m?'M':'';if(a.name==null)
a.name='i/imagenotfound';var url,tag;if(a.h==null||a.h=='undefined'||a.h==0)
a.h='';if(a.w==null||a.w=='undefined'||a.w==0)
a.w='';url=location.protocol==='https:'?'https:':'http:';url+='\/\/static.zoovy.com\/img\/'+a.lib+'\/';if((a.w=='')&&(a.h==''))
url+='-';else{if(a.w){url+='W'+a.w+'-';}
if(a.h){url+='H'+a.h+'-';}
if(a.b){url+='B'+a.b+'-';}
url+=a.m;}
if(url.charAt(url.length-1)=='-'){url=url.slice(0,url.length-1);}
url+='\/'+a.name;if(a.tag==true){a['class']=typeof a['class']=='string'?a['class']:'';a['id']=typeof a['id']=='string'?a['id']:'img_'+a.name;a['alt']=typeof a['alt']=='string'?a['alt']:a.name;var tag="<img src='"+url+"' alt='"+a.alt+"' id='"+a['id']+"' class='"+a['class']+"' \/>";return tag;}
else{return url;}},truncate:function(t,len){var r;if(!t){r=false}
else if(!len){r=false}
else if(t.length<=len){r=t}
else{var trunc=t;if(trunc.length>len){trunc=trunc.substring(0,len);trunc=trunc.replace(/\w+$/,'');trunc+='...';r=trunc;}}
return r;},makeSafeHTMLId:function(string){var r=false;if(string){r=string.replace(/[^a-zA-Z 0-9 - _]+/g,'');}
return r;},isValidMonth:function(val){var valid=true;if(isNaN(val)){valid=false}
else if(!myControl.util.isSet(val)){valid=false}
else if(val>12){valid=false}
else if(val<=0){valid=false}
return valid;},isValidCCYear:function(val){var valid=true;if(isNaN(val)){valid=false}
else if(val==0){valid=false}
else if(val.length!=4){valid=false}
return valid;},getCCExpYears:function(focusYear){var date=new Date();var year=date.getFullYear();var thisYear;var r='';for(var i=0;i<11;i+=1){thisYear=year+i;r+="<option value='"+(thisYear)+"' id='ccYear_"+(thisYear)+"' ";if(focusYear*1==thisYear)
r+=" selected='selected' ";r+=">"+(thisYear)+"</option>";}
return r;},getCCExpMonths:function(focusMonth){var r="";var month=new Array(12);month[1]="01";month[2]="02";month[3]="03";month[4]="04";month[5]="05";month[6]="06";month[7]="07";month[8]="08";month[9]="09";month[10]="10";month[11]="11";month[12]="12";for(i=1;i<13;i+=1){r+="<option value='"+i+"' id='ccMonth_"+i+"' ";if(i==focusMonth)
r+="selected='selected'";r+=">"+month[i]+"</option>";}
return r;},isValidCC:function(ccNumb){var valid="0123456789"
var len=ccNumb.length;var iCCN=parseInt(ccNumb);var sCCN=ccNumb.toString();sCCN=sCCN.replace(/^\s+|\s+$/g,'');var iTotal=0;var bNum=true;var bResult=false;var temp;var calc;for(var j=0;j<len;j++){temp=""+sCCN.substring(j,j+1);if(valid.indexOf(temp)=="-1"){bNum=false;}}
if(!bNum){bResult=false;}
if((len==0)&&(bResult)){bResult=false;}
else{if(len>=15){for(var i=len;i>0;i--){calc=parseInt(iCCN)%10;calc=parseInt(calc);iTotal+=calc;i--;iCCN=iCCN/10;calc=parseInt(iCCN)%10;calc=calc*2;switch(calc){case 10:calc=1;break;case 12:calc=3;break;case 14:calc=5;break;case 16:calc=7;break;case 18:calc=9;break;default:calc=calc;}
iCCN=iCCN/10;iTotal+=calc;}
if((iTotal%10)==0){bResult=true;}
else{bResult=false;}}}
return bResult;},isValidPhoneNumber:function(phoneNumber,country){var r;if(country=='US'||!country){var regex=/^(?:\+?1[-. ]?)?\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/;r=regex.test(phoneNumber)}
else{r=phoneNumber?true:false;}
return r;},isValidPostalCode:function(postalCode,countryCode){var postalCodeRegex;switch(countryCode){case"US":postalCodeRegex=/^([0-9]{5})(?:[-\s]*([0-9]{4}))?$/;break;case"CA":postalCodeRegex=/^([a-zA-Z][0-9][a-zA-Z])\s*([0-9][a-zA-Z][0-9])$/
break;default:postalCodeRegex=/^(?:[A-Z0-9]+([- ]?[A-Z0-9]+)*)?$/;}
return postalCodeRegex.test(postalCode);},handleThirdPartyInits:function(){if(typeof zGlobals!=='undefined'&&zGlobals.thirdParty.facebook.appId&&typeof FB!=='undefined'){FB.init({appId:zGlobals.thirdParty.facebook.appId,cookie:true,status:true,xfbml:true});myControl.thirdParty.fb.saveUserDataToSession();}
else{myControl.util.dump(" -> did not init FB app because either appid isn't set or FB is undefined ("+typeof FB+").");}
},getUsernameFromCart:function(){var r=false;if(myControl.util.isSet(myControl.data.cartItemsList.cart['login'])){r=myControl.data.cartItemsList.cart['login'];}
else if(myControl.util.isSet(myControl.data.cartItemsList.cart['data.bill_email'])){r=myControl.data.cartItemsList.cart['data.bill_email'];}
else if(!$.isEmptyObject(myControl.vars.fbUser)){r=myControl.vars.fbUser.email;}
return r;}
},renderFunctions:{transmogrify:function(eleAttr,templateID,data){if(!templateID||typeof data!='object'||!myControl.templates[templateID]){myControl.util.dump(" -> templateID ("+templateID+") not set or typeof data ("+typeof data+") not object or template doesn't exist not present/correct.");myControl.util.dump(eleAttr);}
else{var $r=myControl.templates[templateID].clone();$r.attr('data-templateid',templateID);if(typeof eleAttr=='string'){$r.attr('id',myControl.util.makeSafeHTMLId(eleAttr))}
else if(typeof eleAttr=='object'){for(index in eleAttr){$r.attr('data-'+index,eleAttr[index])}
if(eleAttr.id){$r.attr('id',myControl.util.makeSafeHTMLId(eleAttr.id))}}
$r.find('[data-bind]').each(function(){var $focusTag=$(this);if(myControl.util.isSet($focusTag.attr('data-bind'))){var bindData=myControl.renderFunctions.parseDataBind($focusTag.attr('data-bind'))
if(bindData['var']){value=myControl.renderFunctions.getAttributeValue(bindData['var'],data);}
if(!myControl.util.isSet(value)&&bindData.defaultVar){value=myControl.renderFunctions.getAttributeValue(bindData['defaultVar'],data);}
if(!myControl.util.isSet(value)&&bindData.defaultValue){value=bindData['defaultValue']
}
bindData.cleanValue=value;}
if((value==0||value=='0.00')&&bindData.hideZero){}
else if(value){if(myControl.util.isSet(bindData.className)){$focusTag.addClass(bindData.className)}
if(bindData.pretext){value=bindData.pretext+value}
if(bindData.posttext){value+=bindData.posttext}
if(myControl.util.isSet(bindData.format)){if(bindData.extension&&typeof myControl.ext[bindData.extension].renderFormats[bindData.format]=='function'){myControl.ext[bindData.extension].renderFormats[bindData.format]($focusTag,{"value":value,"bindData":bindData});}
else if(typeof myControl.renderFormats[bindData.format]=='function'){myControl.renderFormats[bindData.format]($focusTag,{"value":value,"bindData":bindData});}
else{myControl.util.dump(" -> "+bindData.format+" is not a valid format. extension = "+bindData.extension);}
}}
else{if($focusTag.prop('tagName')=='IMG'){$focusTag.remove()}}
value='';});$r.removeClass('loadingBG');return $r;}},createTemplateInstance:function(templateID,eleAttr){var r;if(!templateID){myControl.util.dump(" -> ERROR! templateID not specified in createTemplateInstance. eleAttr = "+eleAttr);r=false;}
else if(myControl.templates[templateID]){r=myControl.templates[templateID].clone();if(typeof eleAttr=='string'){r.attr('id',myControl.util.makeSafeHTMLId(eleAttr))}
else if(typeof eleAttr=='object'){for(index in eleAttr){r.attr('data-'+index,eleAttr[index])}
if(eleAttr.id){r.attr('id',myControl.util.makeSafeHTMLId(eleAttr.id));}}
r.attr('data-templateid',templateID);}
else{myControl.util.dump(" -> ERROR! createTemplateInstance -> templateID ("+templateID+") does not exist! eleAttr = "+eleAttr);r=false;}
return r;},translateTemplate:function(data,target){var safeTarget=myControl.util.makeSafeHTMLId(target);var $divObj=$('#'+safeTarget);var templateID=$divObj.attr('data-templateid');var dataObj=$divObj.data();if(dataObj){dataObj.id=safeTarget}
else{dataObj=safeTarget;}
var $tmp=myControl.renderFunctions.transmogrify(dataObj,templateID,data);$('#'+safeTarget).replaceWith($tmp);},parseDataVar:function(v){var r;r=v.replace(/.*\(|\)/gi,'');return r;},getAttributeValue:function(v,data){if(!v||!data){value=false;}
else{var value;var attributeID=this.parseDataVar(v);var namespace=v.split('(')[0];if(attributeID.charAt(0)==='%'&&namespace=='category'){value=data['%meta'][attributeID.substr(6)];}
else if(namespace=='order'){if(attributeID.substring(0,4)=='data'){value=data['data'][attributeID.substr(5)];}
else if(attributeID.substring(0,8)=='payments'){value=data['payments'][attributeID.substr(9)];}
else if(attributeID.substring(0,12)=='full_product'){myControl.util.dump(" -> full_product MATCH ("+attributeID.substr(13)+")");value=data['full_product'][attributeID.substr(13)];}
else{value=data[attributeID]}}
else if(namespace=='product'){if(attributeID.substring(0,10)=='@inventory'&&!$.isEmptyObject(data['@inventory'])){value=typeof data['@inventory'][data.pid]!='undefined'?data['@inventory'][data.pid][attributeID.substr(11)]:'';}
else if(attributeID.substring(0,12)=='full_product'){myControl.util.dump(' -> attributeID: '+attributeID+'[ '+attributeID.substr(13)+']');value=data.full_product[attributeID.substr(13)]
myControl.util.dump(' -> value: '+value);}
else if(attributeID.indexOf(':')<0){value=data[attributeID]}
else{if(data['%attribs'])
value=data['%attribs'][attributeID];}}
else if(attributeID.indexOf(':')<0){value=data[attributeID]}
else{value=data[attributeID]}}
return value;},parseDataBind:function(data){var rule={};if(data){var declarations=data.split(';');declarations.pop();var len=declarations.length;for(var i=0;i<len;i++){var loc=declarations[i].indexOf(':');var property=$.trim(declarations[i].substring(0,loc));var value=declarations[i].substring(loc+1);if(property!=""&&value!=""){rule[property]=(property!='pretext'&&property!='posttext')?$.trim(value):value;}}}
return rule;}},renderFormats:{imageURL:function($tag,data){var bgcolor=data.bindData.bgcolor?data.bindData.bgcolor:'ffffff'
if(data.value){var imgSrc=myControl.util.makeImage({'tag':0,'w':$tag.attr('width'),'h':$tag.attr('height'),'name':data.value,'b':bgcolor});$tag.attr('src',imgSrc);}
else{$tag.style('display','none');}},elastimage1URL:function($tag,data){var bgcolor=data.bindData.bgcolor?data.bindData.bgcolor:'ffffff'
if(data.value[0]){$tag.attr('src',myControl.util.makeImage({"name":data.value[0],"w":$tag.attr('width'),"h":$tag.attr('height'),"b":bgcolor,"tag":0}))}
else{$tag.style('display','none');}},showIfSet:function($tag,data){if(data.value){$tag.show().css('display','block');}},youtubeVideo:function($tag,data){var r="<iframe style='z-index:1;' width='560' height='315' src='http://www.youtube.com/embed/"+data.bindData.cleanValue+"' frameborder='0' allowfullscreen></iframe>";if(data.bindData.pretext){r=data.bindData.pretext+r}
if(data.bindData.posttext){r+=data.bindData.posttext}
$tag.append(r);},paypalECButton:function($tag,data){$tag.empty().append("<img width='145' id='paypalECButton' height='42' border='0' src='https://www.paypal.com/en_US/i/btn/btn_xpressCheckoutsm.gif' alt='' />").one('click',function(){myControl.ext.convertSessionToOrder.calls.cartPaypalSetExpressCheckout.init();$(this).addClass('disabled').attr('disabled','disabled');myControl.model.dispatchThis('immutable');});},googleCheckoutButton:function($tag,data){var payObj=myControl.sharedCheckoutUtilities.which3PCAreCompatible();if(payObj.googlecheckout){$tag.append("<img height=43 width=160 id='googleCheckoutButton' border=0 src='https://checkout.google.com/buttons/checkout.gif?merchant_id="+zGlobals.checkoutSettings.googleCheckoutMerchantId+"&w=160&h=43&style=trans&variant=text&loc=en_US' \/>").one('click',function(){myControl.ext.convertSessionToOrder.calls.cartGoogleCheckoutURL.init();$(this).addClass('disabled').attr('disabled','disabled');myControl.model.dispatchThis('immutable');});}
else{$tag.append("<img height=43 width=160 id='googleCheckoutButton' border=0 src='https://checkout.google.com/buttons/checkout.gif?merchant_id="+zGlobals.checkoutSettings.googleCheckoutMerchantId+"&w=160&h=43&style=trans&variant=disable&loc=en_US' \/>")}},addClass:function($tag,data){$tag.addClass(data.value);},wiki:function($tag,data){var $tmp=$('<div \/>').attr('id','TEMP_'+$tag.attr('id')).hide().appendTo('body');var target=document.getElementById('TEMP_'+$tag.attr('id'));myCreole.parse(target,data.value,{},data.bindData.wikiFormats);$tag.append($tmp.html());$tmp.empty().remove();},truncText:function($tag,data){var o=myControl.util.truncate(data.value,data.bindData.numCharacters)
$tag.text(o);},selectedOptionsDisplay:function($tag,data){var o='';for(var key in data.value){o+="<div><span class='prompt'>"+data.value[key]['prompt']+"<\/span> <span class='value'>"+data.value[key]['value']+"<\/span><\/div>";}
$tag.html(o);},unix2mdy:function($tag,data){var r;r=myControl.util.unix2Pretty(data.bindData.cleanValue)
if(data.bindData.pretext){r=data.bindData.pretext+r}
if(data.bindData.posttext){r+=data.bindData.posttext}
$tag.text(r)},text:function($tag,data){var o='';if($.isEmptyObject(data.bindData)){o=data.value}
else{o+=data.value;}
$tag.text(o);},popVal:function($tag,data){$tag.val(data.bindData.cleanValue);},assignAttribute:function($tag,data){if(data.bindData.attribute=='id')
data.value=myControl.util.makeSafeHTMLId(data.value);$tag.attr(data.bindData.attribute,data.value);},money:function($tag,data){var amount=data.bindData.cleanValue;if(amount){var r;r=myControl.util.formatMoney(amount,data.bindData.currencySign,'',data.bindData.hideZero);if(data.bindData.pretext){r=data.bindData.pretext+r}
if(data.bindData.posttext){r+=data.bindData.posttext}
$tag.text(r)}}},storageFunctions:{writeLocal:function(key,value){var r=false;if('localStorage'in window&&window['localStorage']!==null&&typeof localStorage!='undefined'){r=true;if(typeof value=="object"){value=JSON.stringify(value);}
try{localStorage.setItem(key,value);}
catch(e){r=false;}}
return r;},readLocal:function(key){if(typeof localStorage=='undefined'){return myControl.storageFunctions.readCookie(key);}
else{var value=localStorage.getItem(key);if(value==null){return myControl.storageFunctions.readCookie(key);}
if(value&&value[0]=="{"){value=JSON.parse(value);}
return value}},readCookie:function(c_name){var i,x,y,ARRcookies=document.cookie.split(";");for(i=0;i<ARRcookies.length;i++){x=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));y=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);x=x.replace(/^\s+|\s+$/g,"");if(x==c_name){return unescape(y);}}
return false;},writeCookie:function(c_name,value){var myDate=new Date();myDate.setTime(myDate.getTime()+(1*24*60*60*1000));document.cookie=c_name+"="+value+";expires="+myDate+";domain=.zoovy.com;path=/";},deleteCookie:function(c_name){var date=new Date();date.setDate(date.getDate()-1);document.cookie=c_name+"=''; expires="+date+"; path=/";myControl.util.dump(" -> DELETED cookie "+c_name);}},thirdParty:{fb:{postToWall:function(msg){myControl.util.dump('BEGIN thirdpartyfunctions.facebook.posttowall. msg = '+msg);FB.ui({method:"feed",message:msg});},share:function(a){a.method='send';FB.ui(a);},saveUserDataToSession:function(){FB.Event.subscribe('auth.statusChange',function(response){if(response.status=='connected'){FB.api('/me',function(user){if(user!=null){myControl.vars.fbUser=user;myControl.calls.cartSet.init({"data.bill_email":user.email});if(_gaq.push(['_setCustomVar',1,'gender',user.gender,1]))
myControl.util.dump(" -> fired a custom GA var for gender.");else
myControl.util.dump(" -> ARGH! GA custom var NOT fired. WHY!!!");}});}});}}},sharedCheckoutUtilities:{which3PCAreCompatible:function(){myControl.util.dump("BEGIN sharedCheckoutUtilities.which3PCAreCompatible");var obj={};obj.paypalec=true;obj.amazonpayment=true;obj.googlecheckout=true;var L=myControl.data.cartItemsList.cart.stuff.length;for(var i=0;i<L;i+=1){if(myControl.data.cartItemsList.cart.stuff[i].full_product['gc:blocked']){obj.googlecheckout=false}}
return obj;},determineAuthentication:function(){var r='none';if(myControl.vars.cid&&myControl.util.getUsernameFromCart()){r='authenticated'}
else if(myControl.model.fetchData('cartItemsList')&&myControl.util.isSet(myControl.data.cartItemsList.cart.cid)){r='authenticated';myControl.vars.cid=myControl.data.cartItemsList.cart.cid;}
else if(typeof FB!='undefined'&&!$.isEmptyObject(FB)&&FB['_userStatus']=='connected'){r='thirdPartyGuest';}
else if(myControl.model.fetchData('cartItemsList')&&myControl.data.cartItemsList.cart['data.bill_email']){r='guest';}
else{}
return r;},fetchPreferredAddress:function(TYPE){var r=false;if(!TYPE){r=false}
else{var L=myControl.data.buyerAddressList['@'+TYPE].length;for(var i=0;i<L;i+=1){if(myControl.data.buyerAddressList['@'+TYPE][i]['_is_default']==1){r=myControl.data.buyerAddressList['@'+TYPE][i]['_id'];break;}}
if(r==false){r=myControl.data.buyerAddressList['@'+TYPE][0]['_id']}}
return r;},setShipAddressToBillAddress:function(){$('#chkoutBillAddressFieldset > ul').children().children().each(function(){if($(this).is(':input')){$('#'+this.id.replace('bill_','ship_')).val(this.value)}});},setAddressFormFromPredefined:function(addressType,addressId){var L=myControl.data.buyerAddressList['@'+addressType].length
var a,i;var r=false;for(i=0;i<L;i+=1){if(myControl.data.buyerAddressList['@'+addressType][i]['_id']==addressId){a=myControl.data.buyerAddressList['@'+addressType][i];r=true;break;}}
$('#data-'+addressType+'_address1').val(a[addressType+'_address1']);if(myControl.util.isSet(a[addressType+'_address2'])){$('#data-'+addressType+'_address2').val(a[addressType+'_address2'])};$('#data-'+addressType+'_city').val(a[addressType+'_city']);$('#data-'+addressType+'_state').val(a[addressType+'_state']);$('#data-'+addressType+'_zip').val(a[addressType+'_zip']);$('#data-'+addressType+'_country').val(a[addressType+'_country']?a[addressType+'_country']:"US");$('#data-'+addressType+'_firstname').val(a[addressType+'_firstname']);$('#data-'+addressType+'_lastname').val(a[addressType+'_lastname']);if(myControl.util.isSet(a[addressType+'_phone'])){$('#data-'+addressType+'_phone').val(a[addressType+'_phone'])};return r;},resetAddress:function(fieldsetId){$('#'+fieldsetId+' :input').each(function(){if($(this).is('select')){$(this).val($(this).find('option[selected]').val());}
else{$(this).val(this.defaultValue);}});}}});