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
An extension for working within the Zoovy UI.


finder -
'path' refers to either a category safe id (.safe.name) or a list safe id ($mylistid)
'safePath' is used for a jquery friendly id. ex: .safe.name gets converted to _safe_name and $mylistid to mylistid).
*/


var admin = function() {
	var r = {
		
	vars : {
		"dependAttempts" : 0,  //used to count how many times loading the dependencies has been attempted.
		"dependencies" : ['store_prodlist','store_navcats','store_product','store_search'] //a list of other extensions (just the namespace) that are required for this one to load
		},



					////////////////////////////////////   CALLS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\		



	calls : {
		navcats : {
//myControl.ext.admin.calls.navcats.categoryDetailNoLocal.init(path,{},'immutable');
			categoryDetailNoLocal : {
				init : function(path,tagObj,Q)	{
					tagObj = typeof tagObj !== 'object' ? {} : tagObj;
					tagObj.datapointer = 'categoryDetail|'+path;
					this.dispatch(path,tagObj,Q);
					return 1;
					},
				dispatch : function(path,tagObj,Q)	{
					myControl.model.addDispatchToQ({"_cmd":"categoryDetail","safe":path,"detail":"fast","_tag" : tagObj},Q);	
					}
				}//categoryDetail
			
			}, //navcats
		mediaLib : {

			folderList : {
				init : function()	{
					this.dispatch();
					},
				dispatch : function()	{
					myControl.model.addDispatchToQ({"_cmd":"adminImageFolderList","_tag" : {"datapointer":"adminImageFolderList"}});	
					}
				} //folderList
			
			}, //mediaLib
			
		finder : {
			
			productInsert : {
				init : function(pid,position,path,tagObj)	{
						this.dispatch(pid,position,path,tagObj);
					},
				dispatch : function(pid,position,path,tagObj)	{
					var obj = {};
					obj['_tag'] = typeof tagObj == 'object' ? tagObj : {};
					obj['_cmd'] = "adminNavcatProductInsert";
					obj.product = pid;
					obj.path = path;
					obj.position = position;
					obj['_tag'].datapointer = "adminNavcatProductInsert|"+path+"|"+pid;
					myControl.model.addDispatchToQ(obj,'immutable');	
					}
				},
			
			productDelete : {
				init : function(pid,path,tagObj)	{
						this.dispatch(pid,path,tagObj);
					},
				dispatch : function(pid,path,tagObj)	{
					var obj = {};
					obj['_tag'] = typeof tagObj == 'object' ? tagObj : {};
					obj['_cmd'] = "adminNavcatProductDelete";
					obj.product = pid;
					obj.path = path;
					obj['_tag'].datapointer = "adminNavcatProductDelete|"+path+"|"+pid;
					myControl.model.addDispatchToQ(obj,'immutable');	
					}
				} //productDelete
			
			}

		}, //calls




					////////////////////////////////////   CALLBACKS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\





	callbacks : {
//callbacks.init need to return either a true or a false, depending on whether or not the file will execute properly based on store account configuration. Use this for any config or dependencies that need to occur.
//the callback is auto-executed as part of the extensions loading process.
		init : {
			onSuccess : function()	{
//				myControl.util.dump('BEGIN myControl.ext.admin.init.onSuccess ');
				var r = true; //return false if extension can't load. (no permissions, wrong type of session, etc)
				for(var index in myControl.ext.admin.htmlTemplates){
					myControl.templates[index] = $(myControl.ext.admin.htmlTemplates[index]())
					}		
				
				return r;
				},
			onError : function(d)	{
//init error handling handled by controller.				
				}
			}, //init
//callback executed after the navcat data is retrieved. the util.addfinder does most of the work.
		addFinderToDom : {
			onSuccess : function(tagObj)	{
				myControl.util.dump("BEGIN admin.callback.addFinderToDom.success");
				myControl.ext.admin.util.addFinder(tagObj.targetID,myControl.data[tagObj.datapointer].id);
//				myControl.util.dump(tagObj);
				},
			onError : function(d)	{
				myControl.util.dump("BEGIN admin.callback.addFinderToDom.onError");
				$('#'+d['_rtag'].targetID).removeClass('loadingBG').empty().append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			},
		
		finderChangesSaved : {
			onSuccess : function(tagObj)	{


myControl.util.dump("BEGIN admin.callbacks.finderChangesSaved");
var uCount = 0; //# of updates
var eCount = 0; //# of errros.
var eReport = ''; // a list of all the errors.

var safePath = myControl.util.makeSafeHTMLId(tagObj.datapointer.split('|')[1]);
var $tmp;

$('#targetCat_'+safePath+', #targetCatRemoved_'+safePath).find("li[data-status]").each(function(){
	$tmp = $(this);
//	myControl.util.dump(" -> PID: "+$tmp.attr('data-pid')+" status: "+$tmp.attr('data-status'));
	if($tmp.attr('data-status') == 'complete')	{
		uCount += 1;
		$tmp.removeAttr('data-status'); //get rid of this so additional saves from same session are not impacted.
		}
	else if($tmp.attr('data-status') == 'error')	{
		eCount += 1;
		eReport += "<li>"+$tmp.attr('data-pid')+": "+myControl.data[$tmp.attr('data-pointer')].errmsg+" ("+myControl.data[$tmp.attr('data-pointer')].errid+"<\/li>";
		}
	});


if(uCount > 0)	{
	$('#messaging_'+safePath).prepend(myControl.util.formatMessage({'message':'Items Updated: '+uCount,'htmlid':'message_'+safePath,'uiIcon':'check','timeoutFunction':"$('#message_"+safePath+"').slideUp(1000);"}))
	}

if(eCount > 0)	{
	$('#messaging_'+safePath).prepend(myControl.util.formatMessage(eCount+' errors occured!<ul>'+eReport+'<\/ul>'));
	}

myControl.ext.admin.util.changeFinderButtonsState(safePath,'enable'); //make buttons clickable



				},
			onError : function(d)	{
				$('#'+targetID).removeClass('loadingBG').append(myControl.util.getResponseErrors(d)).toggle(true);
				myControl.ext.admin.util.changeFinderButtonsState(safePath,'enable');
				}
			},
		
//callback is used for the product finder search results.
		showProdlist : {
			onSuccess : function(tagObj)	{
//				myControl.util.dump("BEGIN admin.callbacks.showProdlist");
				if($.isEmptyObject(myControl.data[tagObj.datapointer]['@products']))	{
					$('#'+tagObj.parentID).empty().removeClass('loadingBG').append('Your search returned zero results');
					}
				else	{
				var numRequests = myControl.ext.store_prodlist.util.buildProductList({
"templateID":"smallprod4list",
"parentID":tagObj.parentID,
"items_per_page":100,
"csv":myControl.data[tagObj.datapointer]['@products']
					});
//				myControl.util.dump(" -> numRequests = "+numRequests);
					if(numRequests)
						myControl.model.dispatchThis();
					}
				},
			onError : function(d)	{
				myControl.util.dump('BEGIN admin.callbacks.showProdlist.onError');
				myControl.util.dump(d);
				var safePath = myControl.util.makeSafeHTMLId(d.tagObj.parentID);
				$('#catalog_'+safePath).append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			},

		finderProductUpdate : {
			onSuccess : function(tagObj)	{
//				myControl.util.dump("BEGIN admin.callbacks.finderProductUpdate.onSuccess");
//				myControl.util.dump(myControl.data[tagObj.datapointer]);
				var tmp = tagObj.datapointer.split('|'); // tmp1 is path and tmp2 is pid
				var targetID = tmp[0] == 'adminNavcatProductInsert' ? "targetCat" : "targetCatRemoved";
				targetID += "_"+myControl.util.makeSafeHTMLId(tmp[1])+"_"+tmp[2];
//				myControl.util.dump(" -> targetID: "+targetID);
				$('#'+targetID).attr('data-status','complete');
				},
			onError : function(d)	{
//				myControl.util.dump("BEGIN admin.callbacks.finderProductUpdate.onError");
				var tmp = myControl.data[tagObj.datapointer].split('|'); // tmp0 is call, tmp1 is path and tmp2 is pid
//on an insert, the li will be in targetCat_... but on a remove, the li will be in targetCatRemoved_...
				var targetID = tmp[0] == 'adminNavcatProductInsert' ? "targetCat" : "targetCatRemoved";
				
				targetID += "_"+myControl.util.makeSafeHTMLId(tmp[1])+"_"+tmp[2];
				$('#'+targetID).attr({'data-status':'error','data-pointer':tagObj.datapointer});
//				myControl.util.dump(d);
				}
			},

		filterFinderSearchResults : {
			onSuccess : function(tagObj)	{
//				myControl.util.dump("BEGIN admin.callbacks.filterFinderSearchResults");
				var safePath = myControl.util.makeSafeHTMLId(tagObj.path);
				var $tmp;
//				myControl.util.dump(" -> safePath: "+safePath);
				//go through the results and if they are already in this category, disable drag n drop.
				$results = $('#catalog_'+safePath);
				//.find( "li" ).addClass( "ui-corner-all" ) )
				$results.find('li').each(function(){
					$tmp = $(this);
					if($('#targetCat_'+safePath+'_'+$tmp.attr('data-pid')).length > 0)	{
				//		myControl.util.dump(" -> MATCH! disable dragging.");
						$tmp.addClass('ui-state-disabled');
						}
					})
				},
			onError : function(d)	{
				var safePath = myControl.util.makeSafeHTMLId(d.tagObj.path);
				$('#catalog_'+safePath).append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			} //filterFinderSearchResults



		}, //callbacks

		validate : {}, //validate
		renderFormats : {},





////////////////////////////////////   ACTION    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



		action : {
/*
to generate an instance of the finder, run: 
myControl.ext.admin.action.addFinderTo() passing in targetID (the element you want the finder appended to) and path (a cat safe id or list id)

*/
			addFinderTo : function(targetID,path)	{
				if(!targetID || !path)	{
					alert('uh oh! something went wrong'); //## how do we want to handle app errors.
					}
				else	{
					
					if(myControl.ext.store_navcats.calls.categoryDetail.init(path,{"callback":"addFinderToDom","extension":"admin","targetID":targetID}))
						myControl.model.dispatchThis();
					}
				},

			showFinderInModal : function(path)	{
				var $finderModal = $('#prodFinder')
//a finder has already been opened. empty it.
				if($finderModal.length > 0)	{
					$finderModal.empty();
					}
				else	{
					$finderModal = $('<div \/>').attr({'id':'prodFinder','title':'Product Finder'}).appendTo('body');
					}
				$finderModal.dialog({modal:true,width:850,height:550});
				this.addFinderTo('prodFinder',path);
				}
			
			}, //action




////////////////////////////////////   UTIL    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


		util : {
			
			
			saveFinderChanges : function(path)	{
//				myControl.util.dump("BEGIN admin.util.saveFinderChanges");
//				myControl.util.dump(" -> path: "+path);
				var safePath = myControl.util.makeSafeHTMLId(path);
				var myArray = new Array();
				var $tmp;
				
//concat both lists (updates and removed) and loop through looking for what's changed or been removed.				
				$('#targetCat_'+safePath+', #targetCatRemoved_'+safePath).find("li").each(function(index){
					$tmp = $(this);
//						myControl.util.dump(" -> pid: "+$tmp.attr('data-pid'));
					if($tmp.attr('data-status') == 'changed')	{
						$tmp.attr('data-status','queued')
						myControl.ext.admin.calls.finder.productInsert.init($tmp.attr('data-pid'),index,path,{"callback":"finderProductUpdate","extension":"admin"});
						}
					else if($tmp.attr('data-status') == 'remove')	{
						myControl.ext.admin.calls.finder.productDelete.init($tmp.attr('data-pid'),path,{"callback":"finderProductUpdate","extension":"admin"});
						$tmp.attr('data-status','queued')
						}
					else	{
//datastatus set but not to a valid value. maybe queued?
						}
					});
				myControl.ext.admin.calls.navcats.categoryDetailNoLocal.init(path,{"callback":"finderChangesSaved","extension":"admin"},'immutable');
				//dispatch occurs on save button, not here.
				}, //saveFinderChanges




			
//onclick, pass in a jquery object of the list item
			removePidFromFinder : function($listItem){
//myControl.util.dump("BEGIN admin.util.removePidFromFinder");
var path = $listItem.closest('[data-path]').attr('data-path');
//myControl.util.dump(" -> safePath: "+path);
var newLiID = 'targetCatRemoved_'+myControl.util.makeSafeHTMLId(path)+'_'+$listItem.attr('data-pid');
//myControl.util.dump(" -> newLiID: "+newLiID);

if($('#'+newLiID).length > 0)	{
	//item is already in removed list.  set data-status to remove to ensure item is removed from list on save.
	$('#'+newLiID).attr('data-status','remove');
	}
else	{
	var $copy = $listItem.clone();
	$copy.attr({'id':newLiID,'data-status':'remove'}).appendTo('#targetCatRemoved_'+myControl.util.makeSafeHTMLId(path));
	}

//kill original.
$listItem.empty().remove();

				}, //removePidFromFinder



/*
executed in a callback for a categoryDetail
generates an instance of the product finder.
targetID is the id of the element you want the finder added to. so 'bob' would add an instance of the finder to id='bob'
path is the list/category src.  should start with either a . or a $ to denote category or list, respectively
*/

			addFinder : function(targetID,path){

//myControl.util.dump("BEGIN admin.util.addFinder");
//jquery likes id's with no special characters.
var safePath = myControl.util.makeSafeHTMLId(path);
//myControl.util.dump(" -> safePath: "+safePath);

$target = $('#'+targetID).empty(); //empty to make sure we don't get two instances of finder if clicked again.
//create and translate the finder template. will populate any data-binds that are set that refrence the category namespace
$target.append(myControl.renderFunctions.createTemplateInstance('productFinder',"productFinder_"+myControl.util.makeSafeHTMLId(path)));
myControl.renderFunctions.translateTemplate(myControl.data['categoryDetail|'+path],"productFinder_"+safePath);

var numRequests = myControl.ext.store_prodlist.util.buildProductList({
	"templateID":"smallprod4list",
	"parentID":"targetCat_"+safePath,
	"csv":myControl.data['categoryDetail|'+path]['@products']
	});
if(numRequests)
	myControl.model.dispatchThis();


// connect the results and targetlist together by class for 'sortable'.
//sortable/selectable example found here:  http://jsbin.com/aweyo5
$( "#targetCat_"+safePath+" , #catalog_"+safePath ).sortable({
	connectWith:".connectedSortable",
	items: "li:not(.ui-state-disabled)",
	handle: ".handle",
/*
the 'update' is run when an item is dragged into or reordered in the targetList.
it does NOT get executed when items are moved over via selectable and move buttons.
*/
	stop: function(event, ui) {
//		myControl.util.dump("sortable update getting fired.");
		var path = ui.item.closest('[data-path]').attr('data-path');
//path is only defined if item is dropped in the target list. ### - see if this is a target list and skip the path lookup if not.
		if(path)	{
			safePath = myControl.util.makeSafeHTMLId(path);
			ui.item.attr({'data-status':'changed','id':'targetCat_'+safePath+'_'+ui.item.attr('data-pid')});
			}
		myControl.util.dump(" -> path: "+path);
		} 
	});

//make results panel list items selectable. 
//only 'li' is selectable otherwise clicking a child node will move just the child over.
// .ui-state-disabled is added to items in the results list that are already in the category list.
$("#catalog_"+safePath).selectable({ filter: 'li',filter: "li:not(.ui-state-disabled)" }); 
//make category product list only draggable within itself. (can't drag items out).
$("#targetCat_"+safePath).sortable( "option", "containment", 'parent' ); //.bind( "sortupdate", function(event, ui) {myControl.util.dump($(this).attr('id'))});
	

//set a data-finderAction on an element with a value of save, moveToTop or moveToBottom.
//save will save the changes. moveToTop will move selected product from the results over to the top of column the category list.
//moveToBottom will do the same as moveToTop except put the product at the bottom of the category.
$('#productFinder_'+safePath+' [data-finderAction]').each(function(){
	myControl.ext.admin.util.bindFinderButtons($(this),safePath);
	});

//bind the action on the search form.
$('#finderSearchForm_'+safePath).submit(function(){
	myControl.ext.store_search.calls.searchResult.init($(this).serializeJSON(),{
		"callback":"showProdlist",
		"extension":"admin",
		"parentID":"catalog_"+safePath});
	myControl.calls.ping.init({"callback":"filterFinderSearchResults","extension":"admin","path":path});
	myControl.model.dispatchThis();
	return false})

				
				}, //addFinder

			
			changeFinderButtonsState : function(safePath,state)	{
				$dom = $('#productFinder_'+safePath+' [data-finderaction]')
				if(state == 'enable')	{
					$dom.removeAttr('disabled').removeClass('ui-state-disabled')
					}
				else if(state == 'disable')	{
					$dom.attr('disabled','disabled').addClass('ui-state-disabled');
					}
				else	{
					//catch. unknown state.
					}
				},


//run as part of addFinder. will bind click events to buttons with data-finderAction on them
			bindFinderButtons : function($button,safePath){
// ### Move search button into this too. 

//	myControl.util.dump(" -> finderAction found on element "+$button.attr('id'));
if($button.attr('data-finderAction') == 'save')	{

	$button.click(function(event){
		event.preventDefault();
		myControl.ext.admin.util.saveFinderChanges($button.attr('data-path'));
		myControl.model.dispatchThis('immutable');
		myControl.ext.admin.util.changeFinderButtonsState(safePath,'disable');
		return false;
		});
	}
//these two else if's are very similar. the important part is that when the items are moved over, the id is modified to match the targetCat 
//id's. That way when another search is done, the disable class is added correctly.
else if($button.attr('data-finderAction') == 'moveToTop' || $button.attr('data-finderAction') == 'moveToBottom'){
	$button.click(function(event){
		event.preventDefault();
		$('#catalog_'+safePath+' .ui-selected').each(function(){
			var $copy = $(this).clone();
			if($button.attr('data-finderAction') == 'moveToTop')
				$copy.prependTo('#targetCat_'+safePath)
			else
				$copy.appendTo('#targetCat_'+safePath)
			$copy.attr('data-status','changed'); //data-status is used to compile the list of changed items for the update request.
			$copy.removeClass('ui-selected').attr('id','targetCat_'+safePath+'_'+$copy.attr('data-pid'));
			$(this).remove();
			
			})
		return false;
		})
	}
else	{
	//catch.  really shouldn't get here.
	}


				} //bindFinderButtons



			},	//util



	htmlTemplates : {
		smallprod4list : function() {
			return "<li class='clearfix loadingBG'><div class='removeProd' onClick='myControl.ext.admin.util.removePidFromFinder($(this).closest(\"[data-pid]\"));'><span class='ui-icon ui-icon-closethick'></span></div><div class='handle'><span class='ui-icon ui-icon-grip-dotted-vertical'></span></div><img class='prodThumb' data-bind='var: product(zoovy:prod_image1); format:imageURL;' /><div data-bind='var:product(zoovy:prod_name); format:text;' class='prodName'></div><div class='pid' data-bind='var:product(pid); format:text;'></div></li>"
			},
		
		productFinder : function(){
// an id of productFinder_path will be added to this parent.
var r = "<div class='loadingBG'><h4 data-bind='var:category(pretty);format:text;'></h4>"
r += "<section class='ui-corner-bottom ui-widget'><table class='finderTable'><tr><td><form data-bind='var:category(id);format:assignAttribute; attribute:id;pretext:finderSearchForm_;' action='#' name='finderSearchFrm' >"
r += "<fieldset>"
r += "<input type='text' class='ui-corner-left finderSearch' value='' name='KEYWORDS' size='20' />"
r += "<input class='ui-state-default ui-corner-right ui-state-active' type='submit' value='search' />"
r += "<input type='hidden' value='' name='CATALOG' />"
r += "</fieldset>"
r += "</form></td><td><h4>Current Product in Category:</h4></td></tr><tr><td>"

r += "<div class='finderProdlistContainer ui-widget-content'><ul data-bind='var:category(id);format:assignAttribute; attribute:id;pretext:catalog_;' class='connectedSortable finderProdlist finderResults'></ul></div>"
r += "</td><td>";

r += "<div class='finderProdlistContainer ui-widget-content'  data-bind='var:category(id);format:assignAttribute; attribute:data-path;'><ul data-bind='var:category(id);format:assignAttribute; attribute:id;pretext:targetCat_;' class='connectedSortable finderProdlist targetList'></ul><ul data-bind='var:category(id);format:assignAttribute; attribute:id;pretext:targetCatRemoved_;' class='displayNone'></ul></div>"

r += "</td></tr><tr><td class='alignRight'>"
r += "<button class='ui-button ui-state-default ui-corner-all ui-button-text-icon-secondary' data-finderAction='moveToTop'><span class='ui-button-text'>move selected to top</span><span class='ui-icon ui-icon-arrow-1-ne ui-button-icon-secondary'></span></button>"

r += "<button class='ui-button ui-state-default ui-corner-all ui-button-text-icon-secondary' data-finderAction='moveToBottom'><span class='ui-button-text'>move selected to bottom</span><span class='ui-icon ui-icon-arrow-1-se ui-button-icon-secondary'></span></button>"
r += "</td><td class='alignRight'><div class='floatLeft finderMessaging' data-bind='var:category(id);format:assignAttribute; attribute:id;pretext:messaging_;'></div>"
r += "<button data-bind='var:category(id);format:assignAttribute; attribute:data-path;' class='ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only ui-state-highlight ' data-finderAction='save'><span class='ui-button-text'>Save</span></button>"
r += "</td></tr></table></section></div>"
if(myControl.util.getParameterByName('debug'))	{
	r += "<button onClick='window.localStorage.clear(); return false;'>Nuke LocalStorage</button>";
	}
			return r;
			}, //productFinder
		
		mpControlSpec : function(){
			return "<div id='mpControlSpec'><div class=' ui-widget ui-state-default mpControls'><span class='ui-state-active ui-corner-all floatRight paging' data-role='next' title='next page'><span class='ui-icon ui-icon-circle-triangle-e'></span></span><div class='floatRight ddUlMenu'><ul><li><a href='#'><span data-bind='var:prodlistmeta(page_in_focus); format:text;'></span><span data-bind='var:prodlistmeta(total_page_count); format:text; pretext: of ;'></span></a><ul data-bind='var:prodlistmeta(total_page_count); format:mpPagesAsListItems; extension:store_prodlist;' class='ui-widget-content ui-corner-bottom'></ul></li></ul></div><span class='ui-state-active ui-corner-all floatRight paging' data-role='previous' title='previous page'><span class='ui-icon ui-icon-circle-triangle-w'></span></span><span data-bind='var:prodlistmeta(page_start_point); format:text;'></span><span data-bind='var:prodlistmeta(page_end_point); format:text; pretext: - ;'></span><span data-bind='var:prodlistmeta(total_product_count); format:text; pretext: of ;'></span></div></div>"	
			} //mpControlSpec
		
		} //htmltemplates





		} //r object.
	return r;
	}