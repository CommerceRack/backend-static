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
An extension for acquiring and displaying 'lists' of categories.
The functions here are designed to work with 'reasonable' size lists of categories.
*/



var admin_orders = function() {
	var r = {

////////////////////////////////////   CALLS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\		
	vars : {
		"pools" : ['PENDING','REVIEW','HOLD','APPROVED','PROCESS','COMPLETED','CANCELLED'],
		"dependAttempts" : 0,  //used to count how many times loading the dependencies has been attempted.
		"dependencies" : ['admin'] //a list of other extensions (just the namespace) that are required for this one to load
		},
	calls : {
//never get from local or memory.
//formerly getOrders
		adminOrderList : {
			init : function(cmdObj,tagObj,Q)	{
				this.dispatch(cmdObj,tagObj,Q)
				return 1;
				},
			dispatch : function(cmdObj,tagObj,Q)	{
				tagObj = typeof tagObj !== 'object' ? {} : tagObj;
				tagObj.datapointer = "adminOrderList";
				cmdObj['_tag'] = tagObj;
				cmdObj["_cmd"] = "adminOrderList"
				myControl.model.addDispatchToQ(cmdObj,Q);
				}
			}, //orderList

//never look locally for data. Always make sure to load latest from server to ensure it's up to date.
//order info is critial
		adminOrderDetail : {
			init : function(orderID,tagObj,Q)	{
				this.dispatch(orderID,tagObj,Q)
				return 1;
				},
			dispatch : function(orderID,tagObj,Q)	{
				var cmdObj = {};
				cmdObj.orderid = orderID;
				tagObj = typeof tagObj !== 'object' ? {} : tagObj;
				tagObj.datapointer = "adminOrderDetail|"+orderID;
				cmdObj['_tag'] = tagObj;
				cmdObj["_cmd"] = "adminOrderDetail"
				myControl.model.addDispatchToQ(cmdObj,Q);
				}
			}, //adminOrderDetail

//updating an order is a critical function and should ALWAYS be immutable.
		adminOrderUpdate : {
			init : function(orderID,updates,tagObj)	{
				this.dispatch(orderID,updates,tagObj)
				return 1;
				},
			dispatch : function(orderID,updates,tagObj)	{
				myControl.util.dump("BEGIN admin_orders.calls.adminOrderUpdate.dispatch");
				myControl.util.dump(" -> orderID = "+orderID);
				cmdObj = {};
				cmdObj['_cmd'] = 'adminOrderUpdate';
				cmdObj.orderid = orderID;
				cmdObj['@updates'] = updates;
				tagObj = typeof tagObj !== 'object' ? {} : tagObj;
				cmdObj['_tag'] = tagObj;
				myControl.model.addDispatchToQ(cmdObj,'immutable');
				}
			} //orderList


		}, //calls









////////////////////////////////////   CALLBACKS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



	callbacks : {
		init : {
			onSuccess : function()	{
//				myControl.util.dump('BEGIN myControl.ext.store_navcats.init.onSuccess ');
				var r = true; //return false if extension won't load for some reason (account config, dependencies, etc).
//				if(!myControl.util.thisIsAnAdminSession())	{
//					$('#globalMessaging').toggle(true).append(myControl.util.formatMessage({'message':'<strong>Uh Oh!<\/strong> This session is not an admin session and the app is trying to load an admin module (admin_orders.js).','uiClass':'error','uiIcon':'alert'}));
//					r = false;
//					}
				return r;
				},
			onError : function()	{
//errors will get reported for this callback as part of the extensions loading.  This is here for extra error handling purposes.
//you may or may not need it.
				myControl.util.dump('BEGIN admin_orders.callbacks.init.onError');
				}
			},
			
		initOrderManager : {
			onSuccess : function(tagObj)	{
			var defaultPool = 'RECENT';
myControl.util.dump("BEGIN admin_orders.callback.initOrderManager.onSuccess");
myControl.ext.admin_orders.action.showOrderList({'POOL':defaultPool});
//$('#orderList').append(myControl.renderFunctions.createTemplateInstance('orderListTemplate'));
$( "#orderFilters ul" ).selectable({
	selected: function (event, ui) {
		if ($(ui.selected).hasClass('selectedfilter')) {
			$(ui.selected).removeClass('selectedfilter').removeClass('ui-selected');
			// do unselected stuff
		} else {            
			$(ui.selected).addClass('selectedfilter').addClass('ui-selected');
			// do selected stuff
		}
	}
}).live("click", function(event) {
	$(this).siblings().removeClass("ui-selected").removeClass('selectedfilter');
	});
$("#orderListFilterPool [data-filterValue="+defaultPool+"]").addClass('selectedfilter').addClass('ui-selected'); //will add selected class to appropriate default filter.
myControl.ext.admin_orders.util.bindOrderListButtons();
				},
			onError : function(d)	{
				$('body').append(myControl.util.getResponseErrors(d));
				}
			
			},
			
//executed per order lineitem on a bulk update.
		orderPoolChanged : {
			onSuccess : function(tagObj)	{
//				myControl.util.dump(" -> targetID: "+targetID);
				$('#'+tagObj.targetID).empty().remove();
				},
			onError : function(d)	{
//				myControl.util.dump("BEGIN admin.callbacks.finderProductUpdate.onError");
				$('#'+tagObj.targetID).attr({'data-status':'error'}).find('td:nth-child('+myControl.ext.admin_orders.util.getFlexgridColIdByName('status')+')').html("<span class='ui-icon ui-icon-alert'></span>");
				$('#orderListMessaging').append(myControl.util.getResponseErrors(d));
				}		
			},

//executed per order lineitem on a flagOrderAsPaid update.
		orderFlagAsPaid : {
			onSuccess : function(tagObj)	{
				myControl.util.dump(" -> targetID: "+tagObj.targetID);
				$('#'+tagObj.targetID).find('td:nth-child('+myControl.ext.admin_orders.util.getFlexgridColIdByName('ORDER_PAYMENT_STATUS')+')').text('Paid');
				},
			onError : function(d)	{
//				myControl.util.dump("BEGIN admin.callbacks.finderProductUpdate.onError");
				$('#'+tagObj.targetID).attr({'data-status':'error'}).find('td:nth-child('+myControl.ext.admin_orders.util.getFlexgridColIdByName('actions')+')').html("<span class='ui-icon ui-icon-alert'></span>");
				$('#orderListMessaging').append(myControl.util.getResponseErrors(d));
				}		
			}, //orderFlagAsPaid
			
//on a bulk update, a ping in executed which triggers this callback. used to either load the appropriate pool or do nothing because an error occured.			
		handleBulkUpdate : {
			onSuccess : function(tagObj)	{
				var numErrors = 0; //the number of errors that occured.
				var numQd = 0; //the number of items still queued.
//go through all rows that have a status, not just selected.  It's possible a merchant could check or uncheck items during the sync.
//completed items have already been removed by this point.
				$('#orderListTable tr[data-status]').each(function(){
					var $row = $(this);
					if($row.attr('data-status') == 'error')	{
						numErrors += 1;
						}
					else if($row.attr('data-status') == 'queued')	{
						//odd. nothing should be queued. maybe an impatient merchants started clicking during request.
						numQd += 1;
						}
					});
				if(numErrors + numQd > 0)	{
					//errors have been reported, if that's the case. Or the merchant has selected more items already and they'll need to move them.
//					$('#orderListTable').flexReload(); //update table. makes sure rotating bg colors are right. !!! doesn't work.
					}
				else	{
//okay. everything went fine... now what???
					}
				},
			onError : function(d)	{
//				myControl.util.dump("BEGIN admin.callbacks.finderProductUpdate.onError");
				$('#orderListMessaging').append(myControl.util.getResponseErrors(d));
				}		
			}, //handleBulkUpdate

		listOrders : {
			onSuccess : function(tagObj)	{
				myControl.util.dump('BEGIN admin_orders.callbacks.listOrders.onSuccess');
				var $target = $('#orderListTable');
				var orderid,cid;
				var L = myControl.data[tagObj.datapointer]['@orders'].length;
				if(L)	{
					for(var i = 0; i < L; i += 1)	{
						orderid = myControl.data[tagObj.datapointer]['@orders'][i].ORDERID; //used for fetching order record.
						cid = myControl.data[tagObj.datapointer]['@orders'][i].CUSTOMER; //used for sending adminCustomerGet call.
						$target.append(myControl.renderFunctions.transmogrify({"id":"order_"+orderid,"orderid":orderid,"cid":cid},tagObj.templateID,myControl.data[tagObj.datapointer]['@orders'][i]))
						}
/*
					$target.removeClass('loadingBG').flexigrid({
						colModel : [
							{display: '', name : 'status', width : 16, sortable : false, align: 'center'}, //used to dump an icon into if things go poorly during updates
							{display: 'Order ID', name : 'ORDERID', width : 90, sortable : false, align: 'left'},
							{display: 'Name', name : 'ORDER_BILL_NAME', width : 140, sortable : false, align: 'left'},
							{display: 'Total', name : 'ORDER_TOTAL', width : 65, sortable : false, align: 'right'},
							{display: 'Pay Method', name : 'ORDER_PAYMENT_METHOD', width : 65, sortable : false, align: 'right'},
							{display: 'Created', name : 'CREATED_GMT', width : 100, sortable : false, align: 'right'},
							{display: 'Dest.', name : 'ORDER_BILL_ZONE', width : 80, sortable : false, align: 'right'},
							{display: 'Pay Status', name : 'ORDER_PAYMENT_STATUS', width : 60, sortable : false, align: 'right'},
							{display: 'Status', name : 'POOL', width : 70, sortable : false, align: 'right'},
							{display: '', name : 'actions', width : 45, sortable : false, align: 'right'}
							],
						height: 500
						});
*/					
					$target.find('.viewOrder').each(function(){
						$(this).click(function(){
							var orderID = $(this).attr('data-orderid');
							var CID = $(this).closest('tr').attr('data-cid');
							myControl.ext.admin_orders.action.orderDetailsInModal(orderID,CID);
							
							myControl.model.dispatchThis();
							})
						});
					}
				else	{
					$('#orderListTableContainer').append('There are no orders that match the current filter criteria.');
					}
				$('#orderListTableContainer').removeClass('loadingBG');


				},
			onError : function(d)	{
				myControl.util.dump('BEGIN myControl.ext.store_crm.callbacks.init.onError');
				$('#'+d['_rtag'].targetID).prepend(myControl.util.getResponseErrors(d)).toggle(true);
				}
			} //listOrders
		}, //callbacks




////////////////////////////////////   ACTION    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



	action : {
		saveChangesToOrder : function()	{
myControl.util.dump("BEGIN admin_orders.action.saveChangesToOrder");
$ordersModal.find('.edited').each(function(){
	myControl.util.dump(" -> "+$(this).attr('data-bind'));
	});
			},
			
			
			
		orderDetailsInModal : function(orderID,CID)	{

var safeID = myControl.util.makeSafeHTMLId(orderID);
//when a modal may be opened more than once, set autoOpen to false then execute a dialog('open'). Otherwise it won't open after the first time.
//							$("<div id='"++"' />").attr().html("<iframe class='viewOrderIframe' src='/biz/orders3/view.cgi?ID="+orderID+"' \/>") 

$ordersModal = $('#viewOrderDialog_'+safeID); //global so it can be easily closed.

//create div if it doesn't already exist. it would exist if opened before during this session.
if($ordersModal.length == 0)	{
	$ordersModal = $("<div />").attr({'id':'viewOrderDialog_'+safeID,'title':'Edit Order '+orderID}).appendTo('body');
	}
//be sure to empty the div or if it has already been loaded, duplicate content will show up.
$ordersModal.empty().dialog({modal:true,width:'90%',height:600,'autoOpen':false})
$ordersModal.dialog('open');

$ordersModal.append(myControl.renderFunctions.createTemplateInstance('orderDetailsTemplate',{'id':'orderDetails_'+safeID,'data-orderid':orderID}));
myControl.ext.admin_orders.calls.adminOrderDetail.init(orderID,{'callback':'translateTemplate','parentID':'orderDetails_'+safeID});				
myControl.ext.admin.calls.customer.adminCustomerGet.init(CID);
			},
			
//myControl.ext.admin_orders.actions.applyFilters();			
		applyFilters : function()	{
			$('#orderListTableContainer').empty().addClass('loadingBG').append("<table id='orderListTable' />");
			
			var obj = {}
			
			$('#orderFilters ul').each(function(){
				var val = $(this).find('.ui-selected').attr('data-filterValue');
				if(val){
					obj[$(this).attr('data-filter')]=val
					}
				});
			if($.isEmptyObject(obj))	{
				$('#orderListMessaging').append(myControl.util.formatMessage('Please select at least one filter criteria'));
				}
			else	{
				myControl.util.dump(obj);
				myControl.ext.admin_orders.action.showOrderList(obj);
				}
			},

//myControl.ext.admin_orders.actions.showOrderList();		
//shows a list of orders by pool.			
			showOrderList : function(filterObj)	{
myControl.util.dump("BEGIN admin_orders.action.showOrderList");
if(typeof filterObj != 'object' || $.isEmptyObject(filterObj))	{
	myControl.util.dump("pooop");
	}
else	{
//create instance of the template. currently, there's no data to populate.
	filterObj.DETAIL = 5;
	filterObj.LIMIT = 20; //for now, cap at 200. ###
	myControl.ext.admin_orders.calls.adminOrderList.init(filterObj,{'callback':'listOrders','extension':'admin_orders','templateID':'adminOrderLineItem'});
	myControl.model.dispatchThis();
	}
			},
			
			
		bulkCMDOrders : function()	{
//				myControl.util.dump("BEGIN admin_orders.actions.bulkCMDOrders");
			var command = $('#CMD').val().substring(0,4); //will = POOL or MAIL or PMNT
			myControl.util.dump(" -> command: "+command);
			$('#orderListMessaging').empty(); //clear any existing messaging.
			if(!command)	{
				$('#orderListMessaging').append(myControl.util.formatMessage('Please select an action to perform'));
				}
			else	{
				switch(command)	{
					case 'POOL':
					myControl.ext.admin_orders.util.bulkChangeOrderPool();
					break;
					
					case 'PMNT':
					myControl.ext.admin_orders.util.bulkFlagOrdersAsPaid();
					break;
					
					case 'MAIL':
					myControl.ext.admin_orders.util.bulkSendEmail();
					break;
					
					default:
						$('#orderListMessaging').append(myControl.util.formatMessage("Unknown action selected ["+command+"]. Please try again. If error persists, please contact technical support."));
					}
				}
			},
		


		selectAllOrders : function()	{
			$('#orderListTable tr').each(function(){$(this).addClass('trSelected')});
			},
			
		deselectAllOrders : function()	{
			$('#orderListTable tr').each(function(){$(this).removeClass('trSelected')});
			},


/*

required params for P:
P.orderID = the orderID to edit. the order should already be in memory.
P.templateID = the lineitem template to be used. ex: orderStuffItemEditorTemplate
*/
			editOrderContents : function(P)	{
var $r = $(); //empty jquery object. line-items are appended to this and then it's all returned.
var orderObj = myControl.data['adminOrderDetail|'+P.orderID].order;
var L = orderObj.stuff.length;
var stid;
for(var i = 0; i < L; i += 1)	{
	stid = P.templateID,orderObj.stuff[i].stid
	$r.append(myControl.util.transmogrify({'id':stid,'data-stid':stid},P.templateID,orderObj.stuff[i]));
	}
return $r;
				}
		
		},

////////////////////////////////////   RENDERFORMATS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

	renderFormats : {
//a product list needs an ID for multipage to work right. will assign a random one if none is set.
//that parent ID is prepended to the sku and used in the list item id to decrease likelyhood of duplicate id's
		stuffList : function($tag,data)	{
			myControl.util.dump("BEGIN admin_orders.renderFormats.stuffList");
			var L = data.value.length;
			if(L > 0)	{
				var thisSTID; //used as a shortcut in the loop below to store the pid during each iteration.
				for(var i = 0; i < L; i += 1)	{
					thisSTID = data.value[i].stid;
					$tag.append(myControl.renderFunctions.transmogrify({'id':thisSTID,'pid':thisSTID},data.bindData.loadsTemplate,data.value[i]));
					}
				}
			return true;
			},//stuffList

		orderPoolSelect : function($tag,data)	{
			var $opt;
			var pools = myControl.ext.admin_orders.vars.pools;
			var L = pools.length;
			
			for(var i = 0; i < L; i += 1)	{
				$opt = $("<option />").val(pools[i]).text(pools[i].toLowerCase());
				if(data.bindData.cleanValue == pools[i])	{
					$opt.attr('selected','selected').css('font-style','italic');
					$tag.attr('data-defaultValue',data.bindData.cleanValue); //record what the default value is so that a comparison can be done later onChange (if needed).
					};
				$opt.appendTo($tag);
				}
			return true;
			},

		billzone : function($tag,data){
			$tag.text(data.value.substr(0,2)+". "+data.value.substr(2,2).toUpperCase()+", "+data.value.substr(4,5));
			return true;
			}, //billzone
			
		paystatus : function($tag,data){
//			myControl.util.dump("BEGIN admin_orders.renderFormats.paystatus");
			var ps = data.value.substr(0,1); //first characer of pay status.
			var pretty;
			switch(ps)	{
				case '0': pretty = 'Paid'; break;
				case '1': pretty = 'Pending'; break;
				case '2': pretty = 'Denied'; break;
				case '3': pretty = 'Cancelled'; break;
				case '4': pretty = 'Review'; break;
				case '5': pretty = 'Processing'; break;
				case '6': pretty = 'Voided'; break;
				case '9': pretty = 'Error'; break;
				default: pretty = 'unknown'; break;
				}
			$tag.text(pretty).attr('title',data.value);
			return true;
			} //billzone
		},
////////////////////////////////////   UTIL    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


		util : {



			bulkChangeOrderPool : function(){

var pool = $('#CMD').val().substr(5);
var numRequests = 0; //the number of requests that need to be made.
$('#orderListTable tr.trSelected').each(function() {
	$(this).attr('data-status','queued');  //data-status is used to record current status of row manipulation (queued, error, complete)
	numRequests += myControl.ext.admin_orders.calls.adminOrderUpdate.init($(this).attr('data-orderid'),['SETPOOL?pool='+pool],{"callback":"orderPoolChanged","extension":"admin_orders","targetID":$(this).attr('id')});
	});
if(numRequests)	{
//	myControl.calls.ping.init({'callback':'handleBulkUpdate','extension':'admin_orders','pool':pool},'immutable'); //for now, don't do anything.
	myControl.model.dispatchThis('immutable');
	}
else	{
	$('#orderListMessaging').append(myControl.util.formatMessage('Please select at least one row.'));
	}
				}, //bulkChangeOrderPool

			bulkFlagOrdersAsPaid : function()	{
var numRequests = 0;
var poolColID = myControl.ext.admin_orders.util.getFlexgridColIdByName('POOL');
var statusColID = myControl.ext.admin_orders.util.getFlexgridColIdByName('status');

$('#orderListTable tr.trSelected').each(function() {
	var $row = $(this);
//	myControl.util.dump(" -> poolColID: "+poolColID);
//	myControl.util.dump(" -> status: "+$row.find('td:nth-child('+poolColID+')').text().toLowerCase());
	if($row.find('td:nth-child('+poolColID+')').text().toLowerCase() != 'pending')	{
		$('#orderListMessaging').append(myControl.util.formatMessage('Order '+$row.attr('data-orderid')+' not set to paid because order is not pending'));
		$row.attr({'data-status':'error'}).removeClass('trSelected').find('td:nth-child('+statusColID+')').html("<span class='ui-icon ui-icon-notice' title='could not flag as paid because status is not pending'></span>");
		}
	else	{
		$(this).attr('data-status','queued');  //data-status is used to record current status of row manipulation (queued, error, complete)
		numRequests += myControl.ext.admin_orders.calls.adminOrderUpdate.init($(this).attr('data-orderid'),['FLAGORDERASPAID'],{"callback":"orderFlagAsPaid","extension":"admin_orders","targetID":$(this).attr('id')}); 
		}
	});
if(numRequests)	{
//	myControl.calls.ping.init({'callback':'handleBulkUpdate','extension':'admin_orders','pool':pool},'immutable');
	myControl.model.dispatchThis('immutable');
	}
else	{
	$('#orderListMessaging').append(myControl.util.formatMessage('Please select at least one row.'));
	}
				}, //bulkFlagOrdersAsPaid
//for now, we are linking to the legacy email page. This dynamically builds a form and submits it.
			bulkSendEmail : function()	{
				var $dialog = $("<div id='emailDialog' />").attr('title','Send Email').appendTo('body');
				$("<iframe src='/biz/orders3/email.cgi' class='bulkMailIframe'>").attr({'id':'bulkMailIframe','name':'bulkMailIframe'}).appendTo($dialog);
				$dialog.dialog({modal:true,width:'90%',height:600});

				
				var $form = $("<form />").attr({"action":"/biz/orders3/email.cgi","method":"post","id":"tmpForm","target":"bulkMailIframe"});
				$('#orderListTable tr.trSelected').each(function(){
					$('<input />').attr({"name":$(this).attr('data-orderid'),"value":"1","type":"hidden"}).appendTo($form);
					});
				$('<input />').attr({"name":"CMD","value":"REVIEW","type":"hidden"}).appendTo($form);
				$form.appendTo('body');
				$form.submit();
				},
//used in the order editor. executed whenever a change is made to update the number of changes in the 'save' button.
			updateOrderChangeCount : function()	{
				var numEdits = $('.edited').length;
				$('#changeCount').text(numEdits)
				return numEdits;
				},

			getFlexgridColIdByName : function(name)	{
//				myControl.util.dump("BEGIN admin_orders.util.getFlexgridColIdByName");
//				myControl.util.dump(" -> name = "+name);
				var colIndex = false; //what is returned. the column index.
//SANITY - flexigrid creates a separate table for the header columns.
				$('#orderList thead th').each(function(index){
					if($(this).attr('data-name') == name)	{ colIndex = index+1} 
					});
//				myControl.util.dump(" -> colIndex = "+colIndex);
				return colIndex; //should only get here if there was no match
				},

//selector = some Jquery selector (not the jquery object).  ex: #viewer or .address
//the selector should be the parent element. any elements within need an 'editable' class on them.
//this way, a specific section of the page can be made editable (instead of just changing all editable elements).
//using the .editable class inside allows for editing all elements on a page at one time. may be suicide tho.
			makeEditable : function(selector,P)	{
if(!P.inputType)	{P.inputType == 'text'}
//info on editable can be found here: https://github.com/tuupola/jquery_jeditable
//myControl.util.dump("BEGIN admin.action.makeEditable ["+selector+" .editable]");
$(selector + ' .editable').each(function(){
	var $text = $(this)
	if($text.attr('title'))	{
		$text.before("<label>"+$text.attr('title')+": </label>");
		$text.after("<br />");
		}
	var defaultValue = $text.text(); //saved to data.defaultValue and used to compare the post-editing value to the original so that if no change occurs, .edited class not added.
//	myControl.util.dump(" -> defaultValue: "+defaultValue);
	$text.addClass('editEnabled').data('defaultValue',defaultValue).editable(function(value,settings){
//onSubmit code:
		if(value == $(this).data('defaultValue'))	{
			myControl.util.dump("field edited. no change.")
			}
		else	{
			$(this).addClass('edited');
			myControl.ext.admin_orders.util.updateOrderChangeCount();
			}
		return value;
		}, {
		  indicator : 'loading...', //can be img tag
		  onblur : 'submit',
		  type : P.inputType,
		  style  : 'inherit'
		  }); //editable
	}); //each
				},

				
			bindOrderListButtons : function()	{
//				myControl.util.dump("BEGIN admin_orders.util.bindOrderListButtons");
				$('#orderList [data-orderAction]').each(function(){
					var action = $(this).attr('data-orderAction');
					$(this).click(function(){
						myControl.util.dump(" -> action: "+action);
						myControl.ext.admin_orders.action[action]()
						})
					});
				} //bindOrderListButtons
		
			} //util


		
		} //r object.
	return r;
	}