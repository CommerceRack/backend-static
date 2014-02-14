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




/*

Our goal is to have a very limited number of 'models' out there.
More controllers may exist than models.
More Extensions will exist than controllers.
view files will be distributed en-masse.

The model is used only for sending and receiving data requests.
It then saves that data into the control obj.
all code for display is in the 'view', which may be a TOXML file.
The view and the model should never speak to each other directly.

There are two types of data being dealt with.:
1. ajax request (referred to as request from here forward) for store data, such as product info, product lists, merchant info, etc.
2. extensions loaded as part of control object instantiation or on the fly as needed.

Some high level error handling occurs as part of the model, mostly for ISE's.
The rest is in the controller or extension. The model will execute callbacks.CALLBACKID.onError(d)
 -> d is the data object returned by the server. one of the few cases the raw response is returned.


execute the zoovyModel function from within the controller. ex:  myControl.model = zoovyModel();
 -> this will return an object into the myControl.model namespace. ex: myControl.model.dispatchThis()
*/

function zoovyModel() {
		
	var r = {
	
		version : "201203",
	// --------------------------- GENERAL USE FUNCTIONS --------------------------- \\
	
	//pass in a json object and the last item id is returned.
	//used in some of the fetchUUID function.
	// note that this is potentially a heavy function (depending on object size) and should be used sparingly.
		getLastIndex : function(obj) {
			var prop, r;
			for (prop in obj) {
				r = prop;
				}
			myControl.util.dump('END model.getLastIndex r = '+r);
			return r;
			}, //getLastIndex
	
	
	//pass in a json object and how many tier1 nodes are returned. handy.
		countProperties : function(obj) {
		//	myControl.util.dump('BEGIN: countProperties');
		//	myControl.util.dump(obj);
			var prop;
			var propCount = 0;
			for (prop in obj) {
				propCount++;
				}
		//	myControl.util.dump('END: countProperties. count = '+propCount);
			return propCount;
			},//countProperties
	
	
	// --------------------------- DISPATCH QUEUE FUNCTIONS --------------------------- \\
	
	/*
	
	addDispatchToQ
	
	The function returns false if the dispatch was not added to q or the uuid if it was.  
	uuid is returned so that it can be passed into other dispatches if needed.
	
	dispatch is a json object.
	exactly what gets passed in depends on the type of request being made.
	each dispatch will automatically get assigned the following, if not passed in:
	 -> uuid: Universal unique identifier. each request needs a unique id. best practice is to NOT pass one and to let this function generate one.
	 -> attempts: increments the number of attempts made on dispatch. will get set to zero if not set. 
	 -> status: dispatches are not deleted from the queue. instead, a status is set (such as completed). 
	
	Depending on the command, multiple params may be required. However to keep this function light, only _cmd is validated.
	
	In most cases, the following _rtag items should be set:
	_rtag.callback -> a reference to an item in the control object that gets executed on successful request (response may include errors)
	_rtag.datapointer -> this is where in myControl.data the information returned will be saved to. 
	ex: datapointer:getProduct|SKU would put product data into myControl.data['getProduct|SKU']
	
	if no datapointer is passed, no data is returned in an accessable location for manipulation.
	 -> the only time the actual response is passed back to the control is if an error was present.
	
	*/
	
	
		addDispatchToQ : function(dispatch,QID) {
	//		myControl.util.dump('BEGIN: addDispatchToQ');
			var r; // return value.
			if(dispatch['_cmd'] == 'undefined')	{
				r = false;
	//			zSTdErr(' -> _cmd not set. return false');
				}
			else	{
				QID = QID === undefined ? 'dispatchQ' : QID; //default to the general Q, but allow for PDQ to be passed in.
				var uuid = myControl.model.fetchUUID() //uuid is obtained, not passed in.
	
	//			myControl.util.dump(' -> QID = '+QID);
	//			myControl.util.dump(' -> UUID = '+uuid);
	//			myControl.util.dump(" -> cmd = "+dispatch["_cmd"]);			
				dispatch["_uuid"] = uuid;
				dispatch["status"] = 'queued';
				dispatch["_v"] = 'zmvc:'+myControl.model.version+'.'+myControl.vars.release+';'+myControl.vars.passInDispatchV;
				dispatch["attempts"] = dispatch["attempts"] === undefined ? 0 : dispatch["attempts"];
				myControl[QID][uuid] = dispatch;
				r = uuid;
				}
	
	//		myControl.util.dump('//END: addDispatchToQ. uuid = '+uuid);
			return r;
			},// addDispatchToQ
	
	
	//if an error happens during request or is present in response, change items from requested back to queued and adjust attempts.
	//this is to make sure nothing gets left undispatched on critical errors.
		changeDispatchStatusInQ: function(QID,UUID,STATUS)	{
			var r = true;
			if(!QID || !UUID)
				r = false;
			else	{
				STATUS = STATUS === undefined ? 'UNSET' : STATUS; //a default, mostly to help track down that this function was run without a status set.
				myControl[QID][UUID].status = STATUS;
				}
			return r;
			},
	
	//used during dispatchThis to make sure only queued items are dispatched.
	//returns items for the Q and sets status to 'requesting'.
	//returns items in reverse order, so the dispatches occur as FIFO.
	//in the actual DQ, the item id is the uuid. Here that gets dropped and the object id's start at zero (more friendly format for B).
		filterQ : function(QID)	{
	//		myControl.util.dump("BEGIN: filterQ");
			var L = myControl.model.countProperties(myControl[QID]);
			
	//		myControl.util.dump(" -> QID = "+QID);
	//		myControl.util.dump(" -> length of Q = "+L);
			
			var c = 0; //used to count how many dispatches are going into q. allows a 'break' if too many are present. not currently added.
			var myQ = new Array();
	//go through this backwards so that as items are removed, the changing .length is not impacting any items index that hasn't already been iterated through. 
			for(var index in myControl[QID]) {
				if(myControl[QID][index].status == 'queued')	{
					myControl[QID][index]['status'] = "requesting";
					myQ.push(myControl[QID][index]);
					myControl[QID][index].attempts += 1; //always change attempts. 
					c += 1;
					}
				}
	//		myControl.util.dump("//END: filterQ. myQ length = "+myControl.model.countProperties(myQ)+" c = "+c);		
			return myQ;
			}, //filterQ
	
	//if a request is in progress and a second request is made, execute this function which will change the status's of the uuid in question.
	//don't need a QID because only the general dispatchQ gets muted.
		handleDualRequests : function()	{
			var inc = 0;
	//		myControl.util.dump('BEGIN model.handleDualRequests');		
			for(var index in myControl.dispatchQ) {
				if(myControl.dispatchQ[index].status == 'requesting')	{
					myControl.model.changeDispatchStatusInQ('dispatchQ',index,"overriden"); //the task was dominated by another request
					inc += 1;
					}
				}
	//		myControl.util.dump('END model.handleDualRequests. '+inc+' requests set to overriden');
			},
	
	
	/*
	
	sends dispatches with status of 'queued' in a single json request.
	only high-level errors are handled here, such as an ISE returned from server, no connection, etc.
	a successful request executes handleresponse (handleresponse executes the controller.response.success action)
	note - a successful request just means that contact with the server was made. it does not mean the request itself didn't return errors.
	
	QID = Queue ID.  Defaults to the general dispatchQ but allows for the PDQ to be used.
	*/
	
		dispatchThis : function(QID)	{
	//		myControl.util.dump('BEGIN model.dispatchThis');
	
			QID = QID === undefined ? 'dispatchQ' : QID; //default to the general Q, but allow for priorityQ to be passed in.
	//		myControl.util.dump(' -> Focus Q = '+QID);
			
	
	//in most cases, if a dispatch is requested, cancel the one in progress in favor of the new.
	//if a dispatch is needed that should NOT be overwritten (immutable) then add it to the priority dispatch queue.
			if (!$.isEmptyObject(myControl.ajax.request)) { // checks for an existing ajax request
	//			myControl.util.dump(' -> an ajax request is already in progress. ');
				if(myControl.ajax.dispatchQInUse == 'priorityDispatchQ')	{
					myControl.util.dump(' -> PRIORITY request in progress. override denied. ');
					myControl.ajax.overrideAttempts += 1;
//try hard to dispatch this. if 10 attempts are made (over 5 seconds) without the current request completing, there is likely a bigger problem.
					if(myControl.ajax.overrideAttempts < 11)	{
						setTimeout("myControl.model.dispatchThis('"+QID+"')",500); //try again soon. if the first attempt is still in progress, this code block will get re-executed till it succeeds.
						}
					else if(myControl.ajax.overrideAttempts < 22)	{
// slow down a bit. try every second for a bit and see if the last response has completed.
						setTimeout("myControl.model.dispatchThis('"+QID+"')",1000); //try again soon. if the first attempt is still in progress, this code block will get re-executed till it succeeds.
						}
					else	{
						myControl.util.dump(' -> stopped trying to override because many attempts were already made.');
						}
					return; //get out now
					myControl.util.dump(' -> UH OH! should not have gotten here. dT-PDQ');
					}
				else	{
					myControl.ajax.request.abort(); // aborts request. should only send 1 request at a time.
					myControl.model.handleDualRequests(); //update status on the DQ items that just got aborted
					myControl.util.dump(' -> override success. ');
					}
				}
	
	
	//Should only reach this point IF no PRIORITY dispatch running.
	
	
	/*
	set control var so that if another request is made while this one is executing, we know whether or not this one is priority.
	the var also gets used in the handleresponse functions to know which q to look in for callbacks.
	*/
			myControl.ajax.dispatchQInUse = QID;
	//		myControl.util.dump(' -> dispatchQInUse = '+myControl.ajax.dispatchQInUse);
			
			var Q = myControl.model.filterQ(QID); //filters out all non-queued dispatches, limits q to 50 dispatches. the 'slice' is to make sure a copy of the q is created and the original remains unmodified.			
			
			var L = myControl.model.countProperties(Q);
	//		myControl.util.dump(' -> total size of dispatchQ = '+myControl.model.countProperties(myControl.dispatchQ))
	//		myControl.util.dump(' -> # items dipatched (Q) = '+L);
			
			if(L > 0)	{
	//			myControl.util.dump(' -> Q = ');
	//			myControl.util.dump(Q);
				myControl.ajax.request = $.ajax({
					type: "POST",
					url: myControl.vars.jqurl,
					context : myControl,
					contentType : "text/json",
					dataType:"json",
					data: JSON.stringify({"_uuid":myControl.model.fetchUUID(),"_zjsid": myControl.sessionId,"_cmd":"pipeline","@cmds":Q}),
					error: function(j, textStatus, errorThrown)	{
	//error handling for individual requests is handled below.
						myControl.util.dump(' -> REQUEST FAILURE! Request returned high-level errors.');
	//					myControl.util.dump(' -> j = ');
	//					myControl.util.dump(j);
						myControl.util.dump(' -> textStatus = '+textStatus);
						myControl.util.dump(' -> errorThrown = '+errorThrown);
						myControl.model.handleReQ(Q,QID);
						myControl.ajax.request = {}; //reset 'holder' for request.
						setTimeout("myControl.model.dispatchThis('"+QID+"')",1000); //try again. a dispatch is only attempted three times before it errors out.
	//					myControl.util.dump(textStatus);
	//					myControl.util.dump(errorThrown);
	//					myControl.util.dump(j);
						},
					success: function(d)	{
	//					myControl.util.dump(' -> Successful request (in dispatch).');
	/*
	yes, this actually happened.  If the ajaxRequest 'holder' is reset after handleresponse
	then the next ajax request is sent PRIOR to the reset and it cancels out the previous request.
	big deal on daisy-chained requests.
	*/
						myControl.ajax.request = {}; //reset holder for request BEFORE handleresponse is executed.
						myControl.model.handleResponse(d);
						}
					});
	//outside of error response above so that Q would be within scope.			
	//			myControl.ajax.request.error(function(j, textStatus, errorThrown){
	//				myControl.util.dump('ajax error');
	//					myControl.model.handleErrors(Q,'criticalError');
	//				});
				}
			else	{
				myControl.util.dump(' -> dispatched Q is empty');
				//an empty queue.
				}
			
	
	//		myControl.util.dump('//END dispatchThis');
		}, //dispatchThis
	
	/*
	run when a high-level error occurs during the request (ise, pagenotfound, etc).
	 -> sets dispatch status back to queued.
	 -> if attempts is already at 3, executed callback.onError code (if set).
	 
	the Q passed in is sometimes the 'already filtered' Q, not the entire dispatch Q. Makes for a smaller loop and only impacts these dispatches.
	also, when dispatchThis is run again, any newly added dispatches WILL get dispatched (if in the same Q).
	However, when a high level error is returned (non-ISE) on a multi-request, no q info is returned, so the entire q is used. ajax.dispatchQInUse is used in this case.
	*/
		handleReQ : function(Q,QID)	{
			myControl.util.dump('BEGIN handleReQ.');
			myControl.util.dump(' -> QID = '+QID);
			myControl.util.dump(' -> Q.length = '+Q.length);
			var uuid,callbackObj;
	//execute callback error for each dispatch, if set.
			for(var index in Q) {
				uuid = Q[index]['_uuid'];
	//			myControl.util.dump('    -> uuid = '+uuid);
	//			myControl.util.dump('    -> attempts = '+myControl[QID][uuid].attempts);
	//			myControl.util.dump('    -> callback = '+Q[index]['_tag']['callback']);
	//			myControl.util.dump('    -> extension = '+Q[index]['_tag']['extension']);
				
	//once.  twice.  pheee times a mady....  stop trying after three attempts buckwheat!    
				if(myControl[QID][uuid].attempts >= 3)	{
					myControl.util.dump(' -> uuid '+uuid+' has had three attempts. changing status to: cancelledDueToErrors');
					myControl.model.changeDispatchStatusInQ(QID,uuid,'cancelledDueToErrors');
					//make sure a callback is defined.
					if(Q[index]['_tag'] && Q[index]['_tag']['callback'])	{
						myControl.util.dump(' -> callback ='+Q[index]['_tag']['callback']);
//executes the callback.onError and takes into account extension. saves entire callback object into callbackObj so that it can be easily validated and executed whether in an extension or root.
						callbackObj = Q[index]['_tag']['extension'] ? myControl.extensions[Q[index]['_tag']['extension']].callbacks[Q[index]['_tag']['callback']] : myControl.callbacks[Q[index]['_tag']['callback']];

						if(callbackObj && typeof callbackObj.onError == 'function'){
							callbackObj.onError('It seems something went wrong. Please continue, try again, or contact the site administrator if error persists. Sorry for any inconvenience.')
							}
						}
					else	{
						myControl.util.dump(' -> no callback defined');
						}
					}
				else	{
					myControl.model.changeDispatchStatusInQ(QID,uuid,'queued');
					}
				
	//			myControl.util.dump('    -> attempts = '+myControl[QID][uuid].status);
				}
			myControl.util.dump('END handleReQ.');
			},
	
	
	
	
	// --------------------------- HANDLERESPONSE FUNCTIONS --------------------------- \\
	
	
	
	
	/*
	
	handleResponse and you...
	some high level errors, like no zjsid or invalid json or whatever get handled in handeResponse
	lower level (_cmd specific) get handled inside their independent response functions, as they're specific to the _cmd
	
	if no high level errors are present, execute a response function specific to the request (ex: request of addToCart executed handleResponse_addToCart).
	this allows for request specific errors to get handled on an individual basis, based on request type (addToCart errors are different than getProduct errors).
	the defaultResponse also gets executed in most cases, if no errors are encountered. 
	the defaultResponse contains all the 'success' code, since it is uniform across commands.
	*/
	
		handleResponse : function(responseData)	{
	//		myControl.util.dump('BEGIN model.handleResponse');
	//if the request was not-pipelined or the 'parent' pipeline request contains errors, this would get executed.
	//the handlereq function manages the error handling as well.
			if(responseData['_rcmd'] == 'err')	{
				myControl.util.dump(' -> High Level Error in response!');
				myControl.model.handleReQ(myControl.dispatchQ,myControl.ajax.dispatchQInUse)
				}
	
	//pipeline request
			else if(responseData['_rcmd'] == 'pipeline')	{
				
	//			myControl.util.dump(' -> pipelined request. size = '+responseData['@rcmds'].length);
				
				for (var i = 0, j = responseData['@rcmds'].length; i < j; i += 1) {
				responseData['@rcmds'][i].ts = myControl.util.unixNow()  //set a timestamp on local data
					if(typeof this['handleResponse_'+responseData['@rcmds'][i]['_rcmd']] == 'function')	{
						this['handleResponse_'+responseData['@rcmds'][i]['_rcmd']](responseData['@rcmds'][i])	//executes a function called handleResponse_X where X = _cmd, if it exists.
						} 
					else	{
	//					myControl.util.dump(' -> going straight to defaultAction');
						this.handleResponse_defaultAction(responseData['@rcmds'][i],null);
						}
					}
				}
	
	//a solo successful request
			else {
				if(typeof this['handleResponse_'+responseData['_rcmd']] == 'function')	{
					this['handleResponse_'+responseData['_rcmd']](responseData)	//executes a function called handleResponse_X where X = _cmd, if it exists.
					} 
				else	{
					this.handleResponse_defaultAction(responseData,null);
					}
				myControl.util.dump(' -> non-pipelined response. not supported at this time.');
				}
			
	//		myControl.util.dump('//END handleResponse');	
			}, //handleResponse
	
	//gets called for each response in a pipelined request (or for the solo response in a non-pipelined request) in most cases. request-specific responses may opt to not run this, but most do.
		handleResponse_defaultAction : function(responseData)	{
	//		myControl.util.dump('BEGIN handleResponse_defaultAction');
			var callbackObj = {}; //the callback object from the controller. saved into var to reduce lookups.
			var callback = false; //the callback name.
			var uuid = responseData['_uuid']; //referenced enough to justify saving to a var.
			var datapointer = null; //a callback can be set with no datapointer.
			var status = null; //status of request. will get set to 'error' or 'completed' later. set to null by defualt to track cases when not set to error or completed.
			var hasErrors = myControl.model.responseHasErrors(responseData);


			if(!$.isEmptyObject(responseData['_rtag']) && myControl.util.isSet(responseData['_rtag']['callback']))	{
	//callback has been defined in the call/response.
				callback = responseData['_rtag']['callback'];
	//			myControl.util.dump(' -> callback: '+callback);
				
				if(responseData['_rtag']['extension'] && !$.isEmptyObject(myControl.extensions[responseData['_rtag']['extension']].callbacks[callback]))	{
	//callback is for checkout and exists
					callbackObj = myControl.extensions[responseData['_rtag']['extension']].callbacks[callback];
	//				myControl.util.dump(' -> callback node exists in myControl.extensions['+responseData['_rtag']['extension']+'].callbacks');
					}
				else if(!$.isEmptyObject(myControl.callbacks[callback]))	{
					callbackObj = myControl.callbacks[callback];
	//				myControl.util.dump(' -> callback node exists in myControl.callbacks');
					}
				else	{
					callback = false;
	//				myControl.util.dump(' -> callback defined but does not exist.');
					}
				}
	
	
//if no datapointer is set, the response data is not saved to local storage or into the myControl. (add to cart, ping, etc)
//effectively, a request occured but no data manipulation is required and/or available.
			if(!$.isEmptyObject(responseData['_rtag']) && myControl.util.isSet(responseData['_rtag']['datapointer']) && hasErrors == false)	{
				datapointer = responseData['_rtag']['datapointer'];
	//on a ping, it is possible a datapointer may be set but we DO NOT want to write the pings response over that data, so we ignore pings.
				if(responseData['_rcmd'] != 'ping')	{
					myControl.data[datapointer] = responseData;
					myControl.storageFunctions.writeLocal(datapointer,responseData); //save to local storage, if feature is available.
					}
				}
			else	{
	//			myControl.util.dump(' -> no datapointer set for uuid '+uuid);
				}
			
			if(hasErrors)	{
				if(callback == false)	{
					myControl.util.dump('WARNING response for uuid '+uuid+' had errors. no callback was defined.')
					}
				else if(!$.isEmptyObject(callbackObj) && typeof callbackObj.onError != 'undefined'){
					myControl.util.dump('WARNING response for uuid '+uuid+' had errors. callback defined and executed.')
					callbackObj.onError(responseData,responseData['_rtag']); //execute a myControl. must be a myControl. view and model don't talk.
					}
				else{
					myControl.util.dump('ERROR response for uuid '+uuid+'. callback defined but does not exist or is not valid type. callback = '+callback+' datapointer = '+datapointer)
					}
				status = 'error';
	//			myControl.util.dump(' --> no callback set in original dispatch. dq set to completed for uuid ('+uuid+')');
				}
			else if(callback == false)	{
				status = 'completed';
	//			myControl.util.dump(' --> no callback set in original dispatch. dq set to completed for uuid ('+uuid+')');
				}
			else	{
	//			myControl.util.dump(' -> got to success portion of handle resonse. callback = '+callback);
				status = 'completed';
				if(!$.isEmptyObject(callbackObj) && typeof callbackObj.onSuccess != undefined){
//initially, only datapointer was passed back.
//then, more data was getting passed on rtag and it made more sense to pass the entire object back
					callbackObj.onSuccess(responseData['_rtag']); //executes the onSuccess for the callback
					}
				else{
					myControl.util.dump(' -> successful response for uuid '+uuid+'. callback defined ('+callback+') but does not exist or is not valid type.')
					}
				}
	
	//		myControl.util.dump(' -> q in use = '+myControl.ajax.dispatchQInUse);
	//		myControl.util.dump(' -> cmd = '+responseData['_rcmd']);
	//		myControl.util.dump(' -> uuid = '+uuid);
	//		myControl.util.dump(' -> status = '+status);
	//		myControl.util.dump(' -> callback = '+callback);
	//		myControl.util.dump(' -> typeof myControl.DIQ = '+ typeof myControl[myControl.ajax.dispatchQInUse]);
	//		myControl.util.dump(' -> length myControl.DIQ = '+ myControl.model.countProperties(myControl[myControl.ajax.dispatchQInUse]));
	//		myControl.util.dump(' -> typeof myControl.DIQ.uuid = '+ typeof myControl[myControl.ajax.dispatchQInUse][uuid]);
			
	//!!! REMOVE THIS.  here to test a IE issue		
	/*		
			for(var index in myControl[myControl.ajax.dispatchQInUse]) {
				myControl.util.dump(' -> myControl.ajax.dispatchQInUse index = '+index);
				}
	*/			
			
			myControl[myControl.ajax.dispatchQInUse][(uuid * 1)]['status'] = status;
			
	//		myControl.util.dump('//END handleResponse_defaultAction. uuid = '+uuid+' callback = '+callback+' datapointer = '+datapointer);
			return status;
		},
	
	
	//this function gets executed upon a successful request for a create order.
	//saves a copy of the old cart object to order|ORDERID in both local and memory for later reference (invoice, upsells, etc).
		handleResponse_createOrder : function(responseData)	{
	//currently, there are no errors at this level. If a connection or some other critical error occured, this point would not have been reached.
			myControl.util.dump("BEGIN model.handleResponse_createOrder");
			var datapointer = "order|"+responseData.orderid;
			myControl.storageFunctions.writeLocal(datapointer,myControl.data.showCart);  //save order locally to make it available for upselling et all.
			myControl.data[datapointer] = myControl.data.showCart; //saved to object as well for easy access.
	//nuke cc fields, if present.		
			myControl.data[datapointer].cart['payment.cc'] = null;
			myControl.data[datapointer].cart['payment.cv'] = null;
			myControl.model.handleResponse_defaultAction(responseData); //datapointer ommited because data already saved.
			return responseData.orderid;
			}, //handleResponse_newSession
	
	
	//this function gets executed upon a successful request for a new session id.
		handleResponse_newSession : function(responseData)	{
	//		myControl.util.dump(" --> newSession Response executed. ("+responseData['_uuid']+")");
	//currently, there are no errors at this level. If a connection or some other critical error occured, this point would not have been reached.
			var datapointer = myControl['username']+"-cartid"
			myControl.storageFunctions.writeLocal(datapointer,responseData['_zjsid']);  //save session id locally to maintain session id throughout user experience.
			myControl.sessionId = responseData['_zjsid']; //saved to object as well for easy access.
			myControl.model.handleResponse_defaultAction(responseData); //datapointer ommited because data already saved.
			return responseData['_zjsid'];
			}, //handleResponse_newSession
	
//this function gets executed upon a successful request for a new admin session
//the controller is updated. currently, no local storage occurs for security reasons. maybe later we store it, if there's a 'isvalidadminsession' cmd to use at init.
		handleResponse_newAdminSession : function(responseData)	{
			myControl.util.dump(" --> newAdminSession Response executed. ("+responseData['_uuid']+")");
			myControl.vars['_admin'] = responseData['_admin']; //saved to object as well for easy access.
			myControl.model.handleResponse_defaultAction(responseData); //datapointer ommited because data already saved.
			return responseData['_zjsid'];
			}, //handleResponse_newSession
	
		responseHasErrors : function(responseData)	{
	//		myControl.util.dump('BEGIN model.responseHasErrors');
//at the time of this version, some requests don't have especially good warning/error in the response.
//as response error handling is improved, this function may no longer be necessary.
			var r = false; //defaults to no errors found.
			switch(responseData['_rcmd'])	{
				case 'getProduct':
					if(!responseData['%attribs']['db:id']) {r = true; } //db:id will not be set if invalid sku was passed.
					break;
				case 'categoryDetail':
					if(responseData.errid > 0 || responseData['exists'] == 0)	{r = true} //a response errid of zero 'may' mean no errors.
					break;
				case 'getProfile':
					if(responseData['errid'] > 0) {r = true}
					break;
				case 'searchResult':
					//currently, there are no errors. I have a hunch this will change.
					break;
	
				case 'addSerializedDataToCart': //no break is present here so that case addSerializedDataToCart and case addToCart execute the same code.
				case 'addToCart':
					if(responseData['_msgs'] > 0)	{r = true};
					break;
	
				case 'createOrder':
	//				myControl.util.dump(' -> case = createOrder');
					if(!myControl.util.isSet(responseData['orderid']))	{
	//					myControl.util.dump(' -> request has errors. orderid not set. orderid = '+responseData['orderid']);
						r = true;
						}  
					break;
				default:
					if(responseData['_msgs'] > 0 && responseData['_msg_1_id'] > 0)	{r = true} //chances are, this is an error. may need tuning later.
	//				myControl.util.dump('default case for error handling');
					break;
				}
	//		myControl.util.dump('//END responseHasErrors. has errors = '+r);
			return r;
			},
	
	
	// --------------------------- FETCH FUNCTIONS --------------------------- \\
	
	
	
	/*
	each request must have a uuid (Unique Universal IDentifyer).
	the uuid is also the item id in the dispatchQ. makes finding dispatches in Q faster/easier.
	
	first check to see if the uuid is set in the myControl. currently, this is considered a 'trusted' source and no validation is done.
	then check local storage/cookie. if it IS set and the +1 integer is not set in the DQ, use it.
	if local isn't set or is determined to be inaccurate (local + 1 is already set in DQ)
	 -> default to 999 if DQ is empty, which will start uuid's at 1000.
	 -> or if items are in the Q get the last entry and treat it as a number (this should only happen once in a session, in theory).
	
	*/
	
		fetchUUID : function()	{
	//		myControl.util.dump('BEGIN fetchUUID');
			var uuid = false; //return value
			var L;
			
			if(myControl.vars.uuid)	{
	//			myControl.util.dump(' -> isSet in myControl. use it.');
				uuid = myControl.vars.uuid; //have to, at some point, assume app integrity. if the uuid is set in the control, trust it.
				}
			else if(L = myControl.storageFunctions.readLocal("uuid"))	{
				L = Math.ceil(L * 1); //round it up (were occassionally get fractions for some odd reason) and treat as number.
	//			myControl.util.dump(' -> isSet in local ('+L+' and typof = '+typeof L+')');
				if($.isEmptyObject(myControl.dispatchQ[L+1]) && $.isEmptyObject(myControl.priorityDispatchQ[L+1])){
					uuid = L;
	//				myControl.util.dump(' -> local + 1 is empty. set uuid to local');
					}
				}
	//generate a new uuid if it isn't already set or it isn't an integer.
			if(uuid == false || isNaN(uuid))	{
	//			myControl.util.dump(' -> uuid not set in local OR local + 1 is already set in dispatchQ');
				if(myControl.dispatchQ.length == 0 && myControl.priorityDispatchQ.length == 0)	{
	//				myControl.util.dump(' -> setting default uuid');
					uuid = 999;
					}
				else	{
	//				myControl.util.dump(' -> size of DQ = '+myControl.dispatchQ.length);
	//				myControl.util.dump(' -> size of PDQ = '+myControl.priorityDispatchQ.length);
	//				uuid = math.max(model.getLastIndex(myControl.dispatchQ),model.getLastIndex(myControl.priorityDispatchQ))  // 'math' not univerally supported.
	//get last request in both q's and determine the larger uuid for use.
					var lastPDQUUID = myControl.model.getLastIndex(myControl.priorityDispatchQ)
					var lastDQUUID = myControl.model.getLastIndex(myControl.dispatchQ)
					uuid = lastDQUUID >lastPDQUUID ? lastDQUUID : lastPDQUUID;
					}
				}
	
			uuid += 1;
			myControl.vars.uuid = uuid;
			myControl.storageFunctions.writeLocal('uuid',uuid); //save it locally.
	//		myControl.util.dump('//END fetchUUID. uuid = '+uuid);
			return uuid;
			}, //fetchUUID
	
//currently, only two q's are present.  if more q's are added, this will need to be expanded.
//!! untested. unused, but may come in handy later.
	whichQAmIFrom : function(uuid)	{
		var r;
		r = dispatchQ[uuid] === 'undefined' ? 'priorityDispatchQ' : 'dispatchQ';
		return r;
		}, //whichQAmIFrom
	
	//gets session id. The session id is used a ton.  It is saved to myControl.sessionId as well as a cookie and, if supported, localStorage.
	//Check to see if it's already set. If not, request a new session via ajax.
		fetchSessionId : function(callback)	{
	//		myControl.util.dump('BEGIN: fetchSession ID');
			var s = false;
			if(myControl.sessionId)	{
	//			myControl.util.dump(' -> sessionId is set in control');
				s = myControl.sessionId
				}
	//sets s as part of else if so getLocal doesn't need to be run twice.
			else if(s = myControl.storageFunctions.readLocal(myControl['username']+"-cartid"))	{
	//			myControl.util.dump(' -> sessionId is set in local');
				}
			else	{
//catch all. no session id in control or local. do nothing. returns false.
				}
	//		myControl.util.dump("//END: fetchSessionId. s = "+s);
			
			return s;
			}, //fetchSessionId
	
	/*
	will check to see if the datapointer is already in the myControl.data.
	if not, will check to see if data is in local storage and if so, save it to myControl.data IF the data isn't too old.
	will return false if datapointer isn't in myControl.data or local (or if it's too old).
	*/
	
	
		fetchData : function(datapointer)	{
	//		myControl.util.dump("BEGIN fetchData.");
			var local;
			var r = false;
	//checks to see if the request is already in 'this'.
			if(!$.isEmptyObject(myControl.data[datapointer]))	{
	//			myControl.util.dump(' -> control has data');
				r = true;
				}
	//then check local storage and, if present, update the control object
			else if (local = myControl.storageFunctions.readLocal(datapointer))	{
	//			myControl.util.dump(' -> local does have data:');
	//			myControl.util.dump(local);
				if(local.ts)	{
					if(myControl.util.unixNow() - local.ts > 60*60*24)	{
		//				myControl.util.dump(' --> but it is too old :'+(myControl.util.unixNow() - myControl.data[datapointer].ts) / (60*60)+" minutes");
						r = false; // data is more than 24 hours old.
						}
					else	{
						myControl.data[datapointer] = local;
						r = true;
						}
					}
				else	{
	//hhhmmm... data is in local, but no ts is set. better get new data.
					r = false;
					}
				}
	//		myControl.util.dump("//END fetchData. "+datapointer+" was/is in control = "+r);
			return r;
			}, //fetchData
	
	
	
	/* functions for extending the controller (adding extensions) */
	
	//for checkout, we only allow one extension to be added and it's added to a 'reserved' namespace: convertSessionToOrder
	//NOTE - I don't think I'm using this anymore. check and remove.
		addCheckoutExtension : function(extId,callback)	{
			myControl.util.dump('BEGIN model.addCheckoutExtension');
			myControl.model.addExtension({0:{"namespace":"convertSessionToOrder","extension":extId,"callback":callback}});
			},
	
/*
extensions are like plugins. They are self-contained objects that may include calls, callbacks, utitity functions and/or variables.
the extension object passed in looks like so:

[
{"namespace":"convertSessionToOrder","extension":"checkout_fast.js","callback":"init"},
{"namespace":"name","extension":"filename","callback":"optional"}
]

namespace - the extension is saved to myControl.extensions.namespace and would be 'called' using that name. (myControl.extensions.namespace.calls.somecall.init()
extension - the filename. full path.
callback - a function to be executed once the extension is done loading.

the 'convertSessionToOrder' namespace is reserved for checkout. only 1 checkout extension can be loaded at a time.
use a unique naming convention for any custom extensions, such as username_someusefulhint (ex: cubworld_jerseybuilder)

The ajax request itself (fetchExtension) was originally in the addExtension function in the loop.  This caused issues.
only one extension was getting loaded, but it got loaded for each iteration in the loop. even with async turned off.

*/
		
		fetchExtension : function(extensionObjItem)	{
//			myControl.util.dump('BEGIN model.fetchExtention');
//			myControl.util.dump(' -> namespace: '+extensionObjItem.namespace);
			var errors = '';
			var url = extensionObjItem.filename;
			
//			myControl.util.dump(' -> url = '+url);
			
			var ajaxLoadExt = $.ajax({
				url: url,
				dataType: 'script',
				success: function(data) {
	//The 'success' can be executed prior to the script finishing loading so the heavy lifting happens in 'complete'.
//					myControl.util.dump(" -> EXTCONTROL Got to success");
					},
				complete: function(data)	{
//					myControl.util.dump(" -> EXTCONTROL got to complete");
//					myControl.util.dump(" -> status = "+data.statusText);
//hhhhmmm... was originally just checking success. now it checks success and OK (2011-01-11). probably need to improve this at some point.
					if(data.statusText == 'success' || data.statusText == 'OK')	{
//						myControl.util.dump(" -> adding extension to controller");
						var namespace = extensionObjItem.namespace; //for easy reference.
						var callback = extensionObjItem.callback; //for easy reference.
						var templateID; //used for a quick reference to which id in the loop is in focus.
						var $templateSpec; //used to store the template/spec itself for the template.
//the .js file for the extension contains a function matching the namespace used.
//the following line executes that function and saves the object returned to the control.
//this is essentially what makes the extension available for use.
//data is saved to the control prior to template/view verification because we need access to the object.
//yes, technically we could have saved it to a var, accessed the templates param, validated and NOT saved, but this is lighter.
//it means that a developer could use an extension that didn't load properly, but that is their perogative, since we told them its broke.
						myControl.extensions[namespace] = eval(namespace+'()');
//						myControl.util.dump(" -> templates.length = "+myControl.extensions[namespace].vars.templates.length);
						if(!myControl.extensions[namespace].vars.templates)	{
							myControl.util.dump("WARNING: extension "+namespace+" did not define any templates. This 'may' valid, as some extensions may have no templates.");
							}
						else	{
							var L = myControl.extensions[namespace].vars.templates.length
							for(var i = 0; i < L; i += 1)	{
								templateID = myControl.extensions[namespace].vars.templates[i];
								$templateSpec = $('#'+templateID);
		//						myControl.util.dump($templateSpec);
								if($templateSpec.length < 1)	{
									errors += "<li>Template '"+templateID+"' is not defined in the view<\/li>";
									}
								else	{
									myControl.templates[templateID] = $templateSpec.clone();
									}
								$('#'+templateID).remove(); //ensure no duplicate id's within spec and cloned template.
								$templateSpec.empty(); //ensure previous spec isn't used on next iteration.
								}
							}
						
	//do not execute the callback if there are errors.
						if(!errors && callback)	{
//							myControl.util.dump(" -> executing callback: "+callback);
							myControl.extensions[namespace].callbacks[callback].onSuccess();
							}
	//reports errors by updating the global arrors element.
						if(errors)	{
//							myControl.util.dump(" -> extension contained errors. callback ("+callback+") not executed yet.");
							myControl.util.dump(" -> "+errors);
//view templates must contain the globalMessaging div. The testing harness needs it.
							$('#globalMessaging').toggle(true).append("<div class='ui-state-error ui-corner-all'>Extension "+namespace+" contains the following error(s):<ul>"+errors+"<\/ul><\/div>");

//the line above handles the errors. however, in some cases a template may want additional error handling so the errors are passed in to the onError callback.
							if(callback)	{
//								myControl.util.dump(" -> executing callback.onError.");
								myControl.extensions[namespace].callbacks[callback].onError("<div>Extension "+namespace+" contains the following error(s):<ul>"+errors+"<\/ul><\/div>");
								}
							}
						}
					},
				error: function(a,b) {
					myControl.util.dump(" -> EXTCONTROL Got to error. error type = "+b)
					}
				});
			},
			
			
//see big comment block above fetch for more info.
		addExtensions : function(extensionObj)	{
//			myControl.util.dump('BEGIN model.addExtension');
			if(!extensionObj)	{
				myControl.util.dump(' -> extensionObj not passed');
				return false;
				}
			else if(typeof extensionObj != 'object')	{
				myControl.util.dump(' -> extensionObj not a valid format');
				return false;
				}
			else	{
//				myControl.util.dump(' -> valid extension object containing '+myControl.model.countProperties(extensionObj)+' extensions');
				for(var index in extensionObj) {
	//namespace and filename are required for any extension.
					if(!extensionObj[index].namespace || !extensionObj[index].filename)	{
						if(extensionObj.callback)	{
							extensionObj[index].callback.onError()
							}
						myControl.util.dump(" -> extension did not load because namespace ("+extensionObj[index].namespace+") or filename ("+extensionObj[index].filename+") was left blank.");
						continue; //go to next index in loop.
						}
					else	{
//						myControl.util.dump(" -> loading ext into namespace: "+extensionObj[index].namespace);
						myControl.model.fetchExtension(extensionObj[index]);
						}
					} // end loop.
				}
//			myControl.util.dump('END model.addExtension');
			}
		}


	return r;
	}