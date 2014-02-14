function zoovyModel(){var r={version:"201215",getLastIndex:function(obj){var prop,r;for(prop in obj){r=prop;}
myControl.util.dump('END model.getLastIndex r = '+r);return r;},countProperties:function(obj){var prop;var propCount=0;for(prop in obj){propCount++;}
return propCount;},addDispatchToQ:function(dispatch,QID){var r;if(dispatch['_cmd']=='undefined'){r=false;}
else{QID=QID===undefined?'mutable':QID;var uuid=myControl.model.fetchUUID()
dispatch["_uuid"]=uuid;dispatch["status"]='queued';dispatch["_v"]='zmvc:'+myControl.model.version+'.'+myControl.vars.release+';'+myControl.vars.passInDispatchV;dispatch["attempts"]=dispatch["attempts"]===undefined?0:dispatch["attempts"];myControl.q[QID][uuid]=dispatch;r=uuid;}
return r;},changeDispatchStatusInQ:function(QID,UUID,STATUS){var r=true;if(!QID||!UUID)
r=false;else{STATUS=STATUS===undefined?'UNSET':STATUS;myControl.q[QID][UUID].status=STATUS;}
return r;},filterQ:function(QID){var c=0;var myQ=new Array();for(var index in myControl.q[QID]){if(myControl.q[QID][index].status=='queued'){myControl.q[QID][index]['status']="requesting";myQ.push(myControl.q[QID][index]);c+=1;if(c>100){setTimeout("myControl.model.dispatchThis('"+QID+"');",1000);break}}}
return myQ;},abortQ:function(QID){myControl.ajax.overrideAttempts=0;var r=0;for(index in myControl.ajax.requests[QID]){myControl.ajax.requests[QID][index].abort();delete myControl.ajax.requests[QID][index];r+=1;}
return r;},handleDualRequests:function(){var inc=0;for(var index in myControl.q.mutable){if(myControl.q.mutable[index].status=='requesting'){myControl.model.changeDispatchStatusInQ('mutable',index,"muted");inc+=1;}}
return inc;},handleReDispatch:function(QID){if(myControl.ajax.overrideAttempts<11){setTimeout("myControl.model.dispatchThis('"+QID+"')",500);}
else if(myControl.ajax.overrideAttempts<22){setTimeout("myControl.model.dispatchThis('"+QID+"')",1000);}
else{myControl.util.dump(' -> stopped trying to override because many attempts were already made.');}},dispatchThis:function(QID){var r=true;QID=QID===undefined?'mutable':QID;var Q=myControl.model.filterQ(QID);var immutableRequestInProgress=$.isEmptyObject(myControl.ajax.requests.immutable)?false:true;var L=Q.length;if(L==0){r=false;}
else if(immutableRequestInProgress){myControl.ajax.overrideAttempts+=1;this.handleReQ(Q,QID);this.handleReDispatch(QID);r=false;}
else if(QID=='immutable'){this.abortQ('mutable');myControl.model.handleDualRequests();}
else{}
if(r){var UUID=myControl.model.fetchUUID();myControl.ajax.lastDispatch=myControl.util.unixNow();myControl.ajax.overrideAttempts=0;myControl.ajax.requests[QID][UUID]=$.ajax({type:"POST",url:myControl.vars.jqurl,context:myControl,async:true,contentType:"text/json",dataType:"json",data:JSON.stringify({"_uuid":UUID,"_zjsid":myControl.sessionId,"_cmd":"pipeline","@cmds":Q}),error:function(j,textStatus,errorThrown){myControl.util.dump(' -> REQUEST FAILURE! Request returned high-level errors or did not request.');myControl.util.dump(' -> textStatus = '+textStatus);myControl.util.dump(' -> errorThrown = '+errorThrown);myControl.model.handleReQ(Q,QID,true);delete myControl.ajax.requests[QID][UUID];setTimeout("myControl.model.dispatchThis('"+QID+"')",1000);},success:function(d){delete myControl.ajax.requests[QID][UUID];myControl.model.handleResponse(d,QID);}});}
return r;},handleReQ:function(Q,QID,adjustAttempts){var uuid,callbackObj;for(var index in Q){uuid=Q[index]['_uuid'];if(myControl.q[QID][uuid].attempts>=1){myControl.util.dump(' -> uuid '+uuid+' has had three attempts. changing status to: cancelledDueToErrors');myControl.model.changeDispatchStatusInQ(QID,uuid,'cancelledDueToErrors');if(Q[index]['_tag']&&Q[index]['_tag']['callback']){myControl.util.dump(' -> callback ='+Q[index]['_tag']['callback']);callbackObj=Q[index]['_tag']['extension']?myControl.ext[Q[index]['_tag']['extension']].callbacks[Q[index]['_tag']['callback']]:myControl.callbacks[Q[index]['_tag']['callback']];if(callbackObj&&typeof callbackObj.onError=='function'){callbackObj.onError('It seems something went wrong. Please continue, refresh the page, or contact the site administrator if error persists. Sorry for any inconvenience. (error: most likely a request failure after multiple attempts [uuid = '+uuid+'])')}}
else{myControl.util.dump(' -> no callback defined');}}
else{if(adjustAttempts){myControl.q[QID][uuid].attempts+=1;}
myControl.model.changeDispatchStatusInQ(QID,uuid,'queued');}
}
},handleResponse:function(responseData,QID){if(responseData){if(responseData&&responseData['_rcmd']=='err'){myControl.util.dump(' -> High Level Error in response!');myControl.model.handleReQ(myControl.dispatchQ,QID,true)}
else if(responseData&&responseData['_rcmd']=='pipeline'){for(var i=0,j=responseData['@rcmds'].length;i<j;i+=1){responseData['@rcmds'][i].ts=myControl.util.unixNow()
if(typeof this['handleResponse_'+responseData['@rcmds'][i]['_rcmd']]=='function'){this['handleResponse_'+responseData['@rcmds'][i]['_rcmd']](responseData['@rcmds'][i])
}
else{this.handleResponse_defaultAction(responseData['@rcmds'][i],null);}}}
else{if(responseData['_rcmd']&&typeof this['handleResponse_'+responseData['_rcmd']]=='function'){this['handleResponse_'+responseData['_rcmd']](responseData)}
else{this.handleResponse_defaultAction(responseData,null);}
myControl.util.dump(' -> non-pipelined response. not supported at this time.');}}
else{alert("Uh oh! Something has gone very wrong with our app. We apologize for any inconvenience. Please try agian. If error persists, please contact the site administrator.");}
},handleResponse_defaultAction:function(responseData){var callbackObj={};var callback=false;var uuid=responseData['_uuid'];var datapointer=null;var status=null;var hasErrors=myControl.model.responseHasErrors(responseData);if(!$.isEmptyObject(responseData['_rtag'])&&myControl.util.isSet(responseData['_rtag']['callback'])){callback=responseData['_rtag']['callback'];if(responseData['_rtag']['extension']&&!$.isEmptyObject(myControl.ext[responseData['_rtag']['extension']].callbacks[callback])){callbackObj=myControl.ext[responseData['_rtag']['extension']].callbacks[callback];}
else if(!$.isEmptyObject(myControl.callbacks[callback])){callbackObj=myControl.callbacks[callback];}
else{callback=false;}}
if(!$.isEmptyObject(responseData['_rtag'])&&myControl.util.isSet(responseData['_rtag']['datapointer'])&&hasErrors==false){datapointer=responseData['_rtag']['datapointer'];if(responseData['_rcmd']=='ping'||responseData['_rcmd']=='appPageGet'){}
else{myControl.data[datapointer]=responseData;myControl.storageFunctions.writeLocal(datapointer,responseData);}}
else{}
if(hasErrors){if(callback==false){myControl.util.dump('WARNING response for uuid '+uuid+' had errors. no callback was defined.')}
else if(!$.isEmptyObject(callbackObj)&&typeof callbackObj.onError!='undefined'){myControl.util.dump('WARNING response for uuid '+uuid+' had errors. callback defined and executed.');callbackObj.onError(responseData,uuid);}
else{myControl.util.dump('ERROR response for uuid '+uuid+'. callback defined but does not exist or is not valid type. callback = '+callback+' datapointer = '+datapointer)}
status='error';}
else if(callback==false){status='completed';}
else{status='completed';if(!$.isEmptyObject(callbackObj)&&typeof callbackObj.onSuccess!=undefined){callbackObj.onSuccess(responseData['_rtag']);}
else{myControl.util.dump(' -> successful response for uuid '+uuid+'. callback defined ('+callback+') but does not exist or is not valid type.')}}
myControl.q[myControl.model.whichQAmIFrom(uuid)][Number(uuid)]['status']=status;return status;},handleResponse_cartOrderCreate:function(responseData){var datapointer="order|"+responseData.orderid;myControl.storageFunctions.writeLocal(datapointer,myControl.data.cartItemsList);myControl.data[datapointer]=myControl.data.cartItemsList;myControl.data[datapointer].cart['payment.cc']=null;myControl.data[datapointer].cart['payment.cv']=null;myControl.model.handleResponse_defaultAction(responseData);return responseData.orderid;},handleResponse_appCategoryDetail:function(responseData){if(responseData['_rtag']&&responseData['_rtag'].detail){responseData.detail=responseData['_rtag'].detail;}
if(responseData['_rtag']&&responseData['_rtag'].datapointer)
responseData.id=responseData['_rtag'].datapointer.split('|')[1];myControl.model.handleResponse_defaultAction(responseData);return responseData.id;},handleResponse_appPageGet:function(responseData){if(responseData['_rtag']&&responseData['_rtag'].datapointer){var datapointer=responseData['_rtag'].datapointer;if(myControl.data[datapointer]){myControl.data[datapointer]['%page']=$.extend(myControl.data[datapointer]['%page'],responseData['%page']);}
else{myControl.data[datapointer]=responseData;}
myControl.storageFunctions.writeLocal(datapointer,myControl.data[datapointer]);}
myControl.model.handleResponse_defaultAction(responseData);},handleResponse_appAdminAuthenticate:function(responseData){myControl.util.dump("BEGIN model.handleResponse_newAdminSession . ("+responseData['_uuid']+")");myControl.util.dump(" -> _zjsid = "+responseData['_zjsid']);if(myControl.util.isSet(responseData['_zjsid'])){this.handleResponse_appCartCreate(responseData);myControl.storageFunctions.writeLocal('zjsid',responseData['_zjsid']);myControl.storageFunctions.writeCookie('zjsid',responseData['_zjsid']);}
else{myControl.model.handleResponse_defaultAction(responseData);}},handleResponse_appCartExists:function(responseData){if(responseData.exists==1){this.handleResponse_appCartCreate(responseData);}
else{myControl.model.handleResponse_defaultAction(responseData);}},handleResponse_appCartCreate:function(responseData){myControl.util.dump(" --> appCartCreate Response executed. ("+responseData['_uuid']+")");myControl.storageFunctions.writeLocal('sessionId',responseData['_zjsid']);myControl.sessionId=responseData['_zjsid'];myControl.model.handleResponse_defaultAction(responseData);myControl.util.dump("sessionID = "+responseData['_zjsid']);return responseData['_zjsid'];},responseHasErrors:function(responseData){var r=false;switch(responseData['_rcmd']){case'getProduct':if(!responseData['%attribs']['db:id']){r=true;responseData['errid']="MVC-M-100";responseData['errtype']="apperr";responseData['errmsg']="could not find product (may not exist)";}
break;case'categoryDetail':if(responseData.errid>0||responseData['exists']==0){r=true
responseData['errid']="MVC-M-200";responseData['errtype']="apperr";responseData['errmsg']="could not find category (may not exist)";}
break;case'searchResult':break;case'addSerializedDataToCart':case'addToCart':if(responseData['_msgs']>0){r=true};break;case'createOrder':if(!myControl.util.isSet(responseData['orderid'])){r=true;}
break;default:if(responseData['_msgs']>0&&responseData['_msg_1_id']>0){r=true}
if(responseData['errid']>0){r=true}
break;}
return r;},fetchUUID:function(){var uuid=false;var L;if(myControl.vars.uuid){uuid=myControl.vars.uuid;}
else if(L=myControl.storageFunctions.readLocal("uuid")){L=Math.ceil(L*1);if($.isEmptyObject(myControl.q.mutable[L+1])&&$.isEmptyObject(myControl.q.immutable[L+1])&&$.isEmptyObject(myControl.q.passive[L+1])){uuid=L;}}
if(uuid==false||isNaN(uuid)){if(myControl.q.mutable.length+myControl.q.immutable.length+myControl.q.passive.length==0){uuid=999;}
else{var lastImutableUUID=myControl.model.getLastIndex(myControl.q.immutable);var lastMutableUUID=myControl.model.getLastIndex(myControl.q.mutable);var lastPassiveUUID=myControl.model.getLastIndex(myControl.q.passive);uuid=lastMutableUUID>lastImutableUUID?lastMutableUUID:lastImutableUUID;uuid=uuid>lastPassiveUUID?uuid:lastPassiveUUID;}}
uuid+=1;myControl.vars.uuid=uuid;myControl.storageFunctions.writeLocal('uuid',uuid);return uuid;},whichQAmIFrom:function(uuid){var r;if(typeof myControl.q.mutable[uuid]!=='undefined')
r='mutable'
else if(typeof myControl.q.immutable[uuid]!=='undefined')
r='immutable'
else if(typeof myControl.q.passive[uuid]!=='undefined')
r='passive'
else{r=false;}
return r;},fetchSessionId:function(callback){var s=false;if(myControl.sessionId){s=myControl.sessionId}
else if(s=myControl.storageFunctions.readLocal('sessionId')){}
else{}
return s;},fetchData:function(datapointer){var local;var r=false;if(!$.isEmptyObject(myControl.data[datapointer])){r=true;}
else if(local=myControl.storageFunctions.readLocal(datapointer)){if(local.ts){if(myControl.util.unixNow()-local.ts>60*60*24){r=false;}
else{myControl.data[datapointer]=local;r=true;}}
else{myControl.util.dump(' -> neither the control nor local storage have this data.');r=false;}}
return r;},loadTemplates:function(namespace){var errors='';var templateID;var $templateSpec;var L=myControl.ext[namespace].vars.templates.length
for(var i=0;i<L;i+=1){templateID=myControl.ext[namespace].vars.templates[i];$templateSpec=$('#'+templateID);if($templateSpec.length<1){errors+="<li>Template '"+templateID+"' is not defined in the view<\/li>";}
else{myControl.templates[templateID]=$templateSpec.attr('data-templateid',templateID).clone();}
$('#'+templateID).empty().remove();$templateSpec.empty();}
return errors;},fetchExtension:function(extensionObjItem){var errors='';var url=extensionObjItem.filename;var namespace=extensionObjItem.namespace;var ajaxLoadExt=$.ajax({url:url,dataType:'script',success:function(data){},complete:function(data){if(data.statusText=='success'||data.statusText=='OK'){myControl.ext[namespace]=eval(namespace+'()');var callback=extensionObjItem.callback;if(typeof myControl.ext[namespace].callbacks.init==='object'){var initPassed=myControl.ext[namespace].callbacks.init.onSuccess();}
else{myControl.util.dump("WARNING: extension "+namespace+" did NOT have an init. This is very bad.");errors+="<li>init not set for extension "+namespace;}
if(myControl.ext[namespace].vars&&myControl.ext[namespace].vars.templates){errors+=myControl.model.loadTemplates(namespace);}
else{}
if(initPassed==false){$('#globalMessaging').append("<div class='ui-state-error ui-corner-all'>Uh Oh! Something went wrong with our app. We apologize for any inconvenience. (err: "+namespace+" extension did not pass init)<\/div>");}
else if(errors){myControl.util.dump(" -> extension contained errors. callback not executed yet.");myControl.util.dump(" -> "+errors);$('#globalMessaging').append("<div class='ui-state-error ui-corner-all'>Extension "+namespace+" contains the following error(s):<ul>"+errors+"<\/ul><\/div>");if(myControl.ext[namespace].callbacks.init.onError){myControl.ext[namespace].callbacks.init.onError("<div>Extension "+namespace+" contains the following error(s):<ul>"+errors+"<\/ul><\/div>");}}
else if(callback){myControl.util.dump(" -> callback defined for "+namespace);if(myControl.ext[namespace].vars.dependencies){myControl.model.handleDependenciesFor(namespace,callback);}
else{if(typeof callback=='function'){eval(callback)}
else if(typeof callback=='string'){myControl.ext[namespace].callbacks[callback].onSuccess()}
else{myControl.util.dump("!Unknown type ["+typeof callback+"] for extension callback ");}}}
else{}}},error:function(a,b,c){$('#globalMessaging').append("<div class='ui-state-error ui-corner-all'>Uh oh! It appears something went wrong with our app. If error persists, please contact the site administrator.<br \/>(error: ext "+extensionObjItem.namespace+" had error type "+b+")<\/div>");myControl.util.dump(" -> EXTCONTROL ("+namespace+")Got to error. error type = "+b+" c = ");myControl.util.dump(c);}});},addExtensions:function(extensionObj){myControl.util.dump('BEGIN model.addExtensions');if(!extensionObj){myControl.util.dump(' -> extensionObj not passed');return false;}
else if(typeof extensionObj!='object'){myControl.util.dump(' -> extensionObj not a valid format');return false;}
else{var L=extensionObj.length;for(var i=0;i<L;i+=1){if(!extensionObj[i].namespace||!extensionObj[i].filename){if(extensionObj.callback&&typeof extensionObj.callback=='string'){extensionObj[i].callback.onError("Extension did not load because namespace ["+extensionObj[i].namespace+"] and/or filename ["+extensionObj[i].filename+"]  not set")}
myControl.util.dump(" -> extension did not load because namespace ("+extensionObj[i].namespace+") or filename ("+extensionObj[i].filename+") was left blank.");continue;}
else{myControl.model.fetchExtension(extensionObj[i],i);}}}
},handleDependenciesFor:function(extension,callback){var L=myControl.ext[extension].vars.dependencies.length;var inc=0;for(var i=0;i<L;i+=1){if(typeof myControl.ext[myControl.ext[extension].vars.dependencies[i]]==='object'){inc+=1}}
if(inc==L){myControl.ext[extension].callbacks[callback].onSuccess();}
else{myControl.ext[extension].vars.dependAttempts+=1;myControl.util.dump(" -> dependencies missing for extension "+extension+". try again. attempt: "+myControl.ext[extension].vars.dependAttempts);if(myControl.ext[extension].vars.dependAttempts>25){$('#globalMessaging').append("Uh Oh. An error occured with our app. You can try refreshing the page. If error persists, please contact the site administrator").toggle(true);}
else{setTimeout("myControl.model.handleDependenciesFor('"+extension+"','"+callback+"');",500)}}}}
return r;}