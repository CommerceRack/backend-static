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


var simple_sample = function() {
	var r = {
		
	vars : {
//a list of the templates used by this extension.
//if this is a custom extension and you are loading system extensions (prodlist, etc), then load ALL templates you'll need here.
		"templates" : ['productTemplate','categoryTemplate','mpControlSpec','categoryThumbTemplate','imageViewerTemplate','prodViewerTemplate','cartViewer','cartViewerProductTemplate','prodReviewSummaryTemplate','prodReviewsTemplate','reviewFrmTemplate','subscribeFormTemplate','pageTemplate'],
		"dependencies" : ['store_prodlist','store_navcats','store_product'], //a list of other extensions (just the namespace) that are required for this one to work.
		"dependAttempts" : 0 //used to count how many times loading the dependencies has been attempted.
		},




					////////////////////////////////////   CALLS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\		



	calls : {

		someDescriptiveName : {
//the init is used to do any pre-processing. for instance, check if data is already in memory or local and if so, just execute the callback.
			init : function(tagObj)	{
/*
do a fetch here to see if data is already local.
myControl.model.fetchData(datapointer) will return true of false depending on whether or not the data is or is not in memory, respectively. 
if the data is in memory, it's likely from this user session (recent).
If the data is in localStorage, the fetch will check a timestamp to make sure the data isn't too old (24 hours).
calls should return a zero if the data is available. If a request is needed return an integer (the number of requests that'll be made).
   this isn't strictly necessary, a 1 or a 0 or even nothing could be returned. However, returning at least a 1 or a 0 allows for a check
   instead of just executing dispatchThis.  dispatchThis will loop through entire Q very early in it's process, so don't run if not needed.
*/
				if(myControl.model.fetchData(tagObj.datapointer)){
//go straight to executing the callback because the data is already available.
//if extension is defined in the tagobj, then a callback within that extension will be executed.
//the extension passed should be for where the callback function is located, not the extension that ran the call.
					if(tagObj.callback)	{
						tagObj.extension ? myControl.ext[tagObj.extension].callbacks[tagObj.callback].onSuccess(tagObj) : myControl.callbacks[tagObj.callback].onSuccess(tagObj);
						}
					else	{
//this is a handy reporting tool. it'll throw to the console whatever is present, including objects. objects not supported in IE console.
						myControl.util.dump(" -> data for request was local but no callback defined.");
						}
					}
				else	{
//execute the dispatch. (go get the data from the api).
					this.dispatch(tagObj);
					}
				},
//this is used to formulate the dispatch and add it to the q.
//put your command do dispatch OUTSIDE this. That way you can q up multiple requests and send them all at once.
//if the dq is empty and you dispatch it, that's fine.
			dispatch : function(tagObj)	{
				obj = {};
				obj['_cmd'] = "categoryTree";
				obj['_tag'].extension = 'simple_sample';
				myControl.model.addDispatchToQ(obj);
				}
			}
		}, //calls




					////////////////////////////////////   CALLBACKS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\





	callbacks : {
//callbacks.init need to return either a true or a false, depending on whether or not the file will execute properly based on store account configuration. Use this for any config dependencies that need to occur.
//the init callback is auto-executed as part of the extensions loading process.
//dependencies for other extensions should be listed in vars.dependencies as ['store_prodlist','store_navcats'] and so forth.
		init : {
			onSuccess : function()	{
//				myControl.util.dump('BEGIN myControl.ext.simple_sample.init.onSuccess ');
				var r = true; //return false if extension won't load for some reason (account config, dependencies, etc).
				return r;
				},
			onError : function()	{
//errors will get reported for this callback as part of the extensions loading.  This is here for extra error handling purposes.
//you may or may not need it.
				myControl.util.dump('BEGIN myControl.ext.simple_sample.callbacks.init.onError');
				}
			},



//in addition to the 'init', you can also specify another callback to execute once the extension is done loading.
//this will only load if the extension successfully loads (init returns a true).

		startMyProgram : {
			onSuccess : function()	{
//				myControl.util.dump('BEGIN myControl.ext.simple_sample.callbacks.startMyProgram.onSuccess');
//go get the root level categories, then show them using showCategories callback.
				if(myControl.ext.store_navcats.calls.categoryTree.init({"callback":"showRootCategories","extension":"simple_sample"}))	{
					myControl.model.dispatchThis();
					}
				
				myControl.ext.store_search.util.bindKeywordAutoComplete('headerSearchFrm');
				
				
				},
			onError : function(d)	{
				$('#globalMessaging').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			},

		showRootCategories : {
			onSuccess : function()	{
//				myControl.util.dump('BEGIN myControl.ext.simple_sample.callbacks.showCategories.onSuccess');
				if(myControl.ext.store_navcats.util.getChildDataOf('.',{'parentID':'leftCol','callback':'addCatToDom','templateID':'categoryTemplate','extension':'store_navcats'},'categoryDetail'))	{
//					myControl.util.dump(' -> executing dispatch here.');
					myControl.model.dispatchThis();
					}
				},
			onError : function(d)	{
//throw some messaging at the user.  since the categories should have appeared in the left col, that's where we'll add the messaging.
				$('#leftCol').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			}, //showRootCategories
			
		showPageContent : {
			onSuccess : function(tagObj)	{
				var catSafeID = tagObj.datapointer.split('|')[1];
				if(typeof myControl.data['categoryDetail|'+catSafeID]['@subcategoryDetail'] == 'object')	{
					myControl.ext.store_navcats.util.getChildDataOf(catSafeID,{'parentID':'subcats','callback':'addCatToDom','templateID':'categoryThumbTemplate','extension':'store_navcats'},'categoryDetailMax');
					}
				else	{
//no subcategories are present. do something else or perhaps to nothing at all.
					}
				myControl.ext.store_prodlist.util.buildProductList({"templateID":"productTemplate","parentID":"productListContainer","items_per_page":10,"csv":myControl.data[tagObj.datapointer]['@products']});
				myControl.model.dispatchThis();
/*	
$("#productListContainer li").hover(
	function () {
		$(this).append($("<span class='plIconList'>I C O N S</span>"));
	}, 
	function () {
//$(this).find("span:last").remove();
//remove all instances of plIconList. will include instances open in any additional lists that are present.
		$(this).find(".plIconList").remove();
	}
);
*/				
				},
			onError : function()	{
				$('#mainCol').removeClass('loadingBG').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			},
		showResults :  {
			onSuccess : function(tagObj)	{
				myControl.util.dump('BEGIN myControl.ext.simple_sample.callbacks.showResults.onSuccess');
//need a ul for the product list to live in.
				$('#mainCol').empty().append("<ul id='productListContainer' class='prodlist' \/>");

/*

to show a list of product, execute this function:
myControl.ext.store_prodlist.util.buildProductList(P,CSV)
see the extension file for a list of what P supports.
*/

//will handle building a template for each pid and tranlating it once the data is available.
//returns # of requests needed. so if 0 is returned, no need to dispatch.
				if(myControl.ext.store_prodlist.util.buildProductList({"templateID":"productTemplate","parentID":"productListContainer","items_per_page":5,"csv":myControl.data[tagObj.datapointer]['@products']})){
					myControl.model.dispatchThis();
					}
				},
			onError : function(d)	{
				myControl.util.dump('BEGIN myControl.ext.simple_sample.callbacks.showResults.onError');
				$('#mainCol').removeClass('loadingBG').append(myControl.util.getResponseErrors(d)).toggle(true);
				}
			}
		}, //callbacks







////////////////////////////////////   RENDERFORMATS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\





		renderFormats : {
			
			
			
			},


////////////////////////////////////   UTIL    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


		util : {
			iconList : function()	{
				var r; //what is returned.
				//R = reviews (read and write). I = Images. T = Tell a Friend.
				r = "<button>R<\/button><button>I<\/button>";
				return r;
				},
			showPage : function(catSafeID)	{
				$('#mainCol').empty().append(myControl.renderFunctions.createTemplateInstance('pageTemplate','page-'+catSafeID));
				var $target = $('#prodlist').append("<ul id='productListContainer' class='prodlist' \/>");
				if(myControl.ext.store_navcats.calls.categoryDetailMax.init(catSafeID,{"callback":"showPageContent","extension":"simple_sample"}))	{
					myControl.model.dispatchThis();
					}
				}
			
			}


		
		} //r object.
	return r;
	}