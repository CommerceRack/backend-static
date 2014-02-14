//was part of control. 
//used to store info about prodlist/results settings. which 'id' the currently preferred listing style should be saved here.
//should probably have the listing style itself dictate the itemsperpage. though that should update this field.
		control.prodlistAttribs = {
			itemsPerPage : 25, //update this var any time items per page changes. allows persistance and this var is referenced a lot in control.
			sortOrder : 'zoovy:prod_name',
			style : '' //most likely we'll set this to a div id. loading from the var will allow us to easily support multple list styles.
			},



					////////////////////////////////////   CALLS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\		


		getProfile : {
			init : function(profileid,callback)	{
				if(myControl.model.fetchData('getProfile|'+profileid) == false){this.dispatch(profileid,callback)}
				//have the data, execute callback if one is defined.
				else if(callback){
					myControl.callbacks[callback].onSuccess('getProfile|'+profileid)
					}
				else	{
//request was made without a callback?  weird. what for?
					myControl.util.dump('getProfile call executed. data was local already, but no callback was defined.')
					}
				},
			dispatch : function(profileid,callback)	{
				myControl.model.addDispatchToQ({"_cmd":"getProfile",'_v':myControl.version,"profile":profileid,"_tag" : {"callback":callback,"datapointer":"getProfile|"+profileid}});	
				}
			},//getProfile		
		
		getQuickProd : {
			init : function(pid,callback)	{
//				myControl.util.dump("BEGIN getQuickProd ("+pid+")")
				if(myControl.model.fetchData('getProduct|'+pid) == false)	{
//					myControl.util.dump("fetchData returned false. data was not local already.")
					this.dispatch(pid,callback)
					}
				//have the data, execute callback if one is defined.
				else if(myControl.util.isSet(callback)){
					myControl.callbacks[callback].onSuccess('getProduct|'+pid)
					}
				else	{
//request was made without a callback?  weird. what for?
					myControl.util.dump('getQuickProd call executed. data was local already, but no callback was defined.')
					}
				},
			dispatch : function(pid,callback)	{
				myControl.model.addDispatchToQ({"_cmd":"getProduct",'_v':myControl.version,"pid":pid,"_tag" : {"callback":callback,"datapointer":"getProduct|"+pid}});	
				}
			},//getQuickProd


//in most cases, a quickProd is done to just get the basic data. If more detailed data is needed (inventory, varations, etc), do a detailed prod.

		getQuickProd : {
			init : function(pid,callback)	{
//				control.utilityFunctions.dataDumper("BEGIN getQuickProd ("+pid+")")
				if(control.model.fetchData('getProduct|'+pid) == false)	{
//					control.utilityFunctions.dataDumper("fetchData returned false.")
					
					this.dispatch(pid,callback)
					}
				//have the data, execute callback if one is defined.
				else if(control.utilityFunctions.isSet(callback)){
					control.callbacks[callback].onSuccess('getProduct|'+pid)
					}
				else	{
//request was made without a callback?  weird. what for?
					control.utilityFunctions.dataDumper('getQuickProd call executed. data was local already, but no callback was defined.')
					}
				},
			dispatch : function(pid,callback)	{
				control.model.addDispatchToQ({"_cmd":"getProduct","pid":pid,"_tag" : {"callback":callback,"datapointer":"getProduct|"+pid}});	
				}
			},//getQuickProd
//in a product detail, there are four pieces of information to be obtained: attributes, reviews, variations and inventory.
//before local data can be reliably used, it must be determined if all four are already local.

		getDetailedProd : {
			init : function(pid,callback)	{
				control.utilityFunctions.dataDumper("BEGIN getDetailedProd ("+pid+")")
				if(control.model.fetchData('getProduct|'+pid) == false || control.model.fetchData('getReviews|'+pid) == false)	{
					control.utilityFunctions.dataDumper(" -> either getProduct or getReviews was not in local")
					this.dispatch(pid,callback);
					}
//check to make sure inventory and variations data has been retrieved.
				else if($.isEmptyObject(control.data["getProduct|"+pid]['@inventory']) || control.utilityFunctions.isSet(control.data["getProduct|"+pid]['@variations']))	{
					control.utilityFunctions.dataDumper(" -> @inventory or @variations not in local")
					this.dispatch(pid,callback);
					}
				else if(callback){
					control.callbacks[callback].onSuccess('getProduct|'+pid)
					}
				else	{
//request was made without a callback?  weird. what for?
					control.utilityFunctions.dataDumper('getDetailedProd call executed. data was local already, but no callback was defined.')
					}
				},
			dispatch : function(pid,callback)	{
				control.model.addDispatchToQ({"_cmd":"getReviews","pid":pid,"_tag" : {"datapointer":"getReviews|"+pid}});
				control.model.addDispatchToQ({"_cmd":"getProduct","pid":pid,"withVariations":"1","withInventory":"1","_tag" : {"callback":callback,"datapointer":"getProduct|"+pid}});	
				}
			},//getDetailedProd

		getReviews : {
			init : function(pid,callback)	{
				if(control.model.fetchData('getProduct|'+pid) == false)	{this.dispatch(pid,callback)}
				//have the data, execute callback if one is defined.
				else if(control.utilityFunctions.isSet(callback)){
					control.callbacks[callback].onSuccess('getProduct|'+pid)
					}
				else	{
//request was made without a callback. for reviews, this is likely to happen often as the getProduct likely has the callback on it.
//					control.utilityFunctions.dataDumper('getReviews call executed. data was local already, but no callback was defined.')
					}
				},
			dispatch : function(pid,callback)	{
				control.model.addDispatchToQ({"_cmd":"getReviews","pid":pid,"_tag" : {"callback":callback,"datapointer":"getReviews|"+pid}});	
				}
			},//getReviews
			
		addReview : {
			init : function(frmObject,callback)	{
				r = true;
				$('#postRequestMessage').empty(); //clear any past messaging.
				$('#reviewAlerts').empty(); //clear any past errors.
				$('#reviewForm').toggle(true); //make sure form is visible. is turned off when a successful review is left.
				var $name = $('#writeReviewCustomerName').removeClass('ui-state-error');
				var $message = $('#writeReviewMessage').removeClass('ui-state-error');
				var $rating = $('#writeReviewRating').removeClass('ui-state-error');
				
				if($name.val() == '')	{
					$name.addClass('ui-state-error');
					r = false;
					}
				if($message.val() == '')	{
					$message.addClass('ui-state-error');
					r = false;
					}	
				if($rating.val() == '')	{
					$rating.addClass('ui-state-error');
					r = false;
					}				
				if(r == true)	{
					this.dispatch(frmObject,callback);
					}
				},
			dispatch : function(a,callback)	{
				a['_cmd'] = "addReview";
				a['_tag'] = {}; //necessary or the next line causes error.
				a['_tag']['callback'] = callback;
				control.model.addDispatchToQ(a);	
				}
			},//getReviews			
			
		addToCart : {
			init : function(serFrmData,callback)	{
				this.dispatch(serFrmData,callback);
				},
			dispatch : function(serFrmData,callback)	{
				serFrmData["_cmd"] = "addSerializedDataToCart"; 
				serFrmData["_tag"] = {"callback":callback};	
				control.model.addDispatchToQ(serFrmData,'priorityDispatchQ');
				control.calls.getCartContents.init('updateMiniCart','priorityDispatchQ');
				}
			},//addToCart


			
//obtain valid shipping methods. gets executed after a zip has been added, for instance.
		getShippingRates : {
			init : function(callback)	{
				this.dispatch(callback);
				},
			dispatch : function(callback)	{
				control.model.addDispatchToQ({"_cmd":"getShippingRates","_tag": {"datapointer":"getShippingRates","callback":callback}},'priorityDispatchQ');
				}
			}, //getShippingRates

		getPaymentMethods : {
			init : function(callback)	{
				this.dispatch(callback);
				},
			dispatch : function(callback)	{
				control.model.addDispatchToQ({"_cmd":"getPaymentMethods","_tag": {"datapointer":"getPaymentMethods","callback":callback}},'priorityDispatchQ');
				}
			}, //getPaymentMethods	

//gets the cart contents, but also shipping and payment option details.
		getDetailedCartContents : {
			init : function(callback)	{
//				if($.isEmptyObject(control.data.showCart) || $.isEmptyObject(control.data.getPaymentMethods) || $.isEmptyObject(control.data.getShippingRates) || $.isEmptyObject(control.data.getCheckoutDestinations) )	
				this.dispatch(callback); // for now, always update cart and checkout objects.
				},
			dispatch : function(callback)	{
				control.calls.getPaymentMethodsForCheckout.init();
				control.calls.getShippingRates.init();
				control.calls.getCheckoutDestinations.init();
				control.calls.getCartContents.init(callback);
				}			
			},//getDetailedCartContents

		getResults : {
			init : function(serFrmData,callback)	{
				control.renderFunctions.loadNewContent();
				//control.utilityFunctions.dataDumper('BEGIN control.calls.getResults. fetchData for '+serFrmData.KEYWORDS+' = '+control.model.fetchData('getResults|'+serFrmData.KEYWORDS))
				if(control.model.fetchData('getResults|'+serFrmData.KEYWORDS) == false)	{this.dispatch(serFrmData,callback)}
				else if(control.utilityFunctions.isSet(callback)){
					control.callbacks[callback].onSuccess('getResults|'+serFrmData.KEYWORDS)
					}
				},
			dispatch : function(serFrmData,callback)	{
				serFrmData['_cmd'] = "searchResult"
				serFrmData['_tag'] = {"callback":callback,"datapointer":"getResults|"+serFrmData.KEYWORDS}
				control.model.addDispatchToQ(serFrmData);	
				control.model.dispatchThis(); //!!! this need to be moved
				}
			},//getResults
			
		getMultiPageData : {
			init : function(datapointer,callback)	{
//				control.utilityFunctions.dataDumper('BEGIN control.getMultiPageData');
//have to do an AND here otherwise the second statement causes an error. it can only be checked if the first conditional is true.
				if($.isEmptyObject(control.data[datapointer]))	{
					control.utilityFunctions.dataDumper('control.data.datapointer is empty');
					this.dispatch(datapointer,callback);
					}
				else	{
//					control.utilityFunctions.dataDumper(' -> control.data.datapointer is NOT empty');
					if(control.data[datapointer]['haveMPData'] ==1){}
					else{this.dispatch(datapointer,callback);}
					}
				},
			dispatch : function(datapointer,callback)	{
				control.prodlistFunctions.genMultiPageDispatches(datapointer);
				control.model.addDispatchToQ({"_cmd":"ping","_tag" : {"callback":callback,"datapointer":datapointer}}); //dispatched in handleproductlist
				}
			},//getMultipageData

		updateCartContents : {
			init : function(obj,callback)	{
				this.dispatch(obj,callback);
				},
			dispatch : function(obj,callback)	{
				obj['_cmd'] = "updateCart";
				obj['_tag'] = {"callback":callback}
				control.model.addDispatchToQ(obj,'priorityDispatchQ');
				}
			},//getCartContents



					////////////////////////////////////   CALLBACKS    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
					
					


		getReviews : {
			onSuccess : function(datapointer)	{
				control.utilityFunctions.dataDumper('got to getReviews success');
				},
			onError : function(d)	{
				control.utilityFunctions.dataDumper('got to getReviews error!');
				}
			},//getReviews	
		addReview : {
			onSuccess : function(datapointer)	{
				$('#reviewForm').toggle(false);
				$('#postRequestMessage').append("Thanks! Your review has been submitted for approval.");
				},
			onError : function(d)	{
				$('#reviewAlerts').empty().append("Uh Oh. It seems an error occured. Please try submitting again or if the error persists, contact the site administrator.");
				}
			},//addReviews
			
		addToCart : {
			onSuccess : function(datapointer)	{
				control.utilityFunctions.dataDumper('got to addToCart success');
				},
			onError : function(d)	{
				alert('oops. something bad happened');
				control.utilityFunctions.dataDumper('got to addToCart error!');
				}
			},//addToCart
		updateMiniCart : {
			onSuccess : function(datapointer)	{
				control.utilityFunctions.dataDumper('got to updateMiniCart success');
//				zView.updateMinicart(control.data.showCart.cart['cart.add_item_count']);
				},
			onError : function(d)	{
				control.utilityFunctions.dataDumper('got to updateMiniCart error!');
				}
			},//updateMiniCart

		getProdForList : {
			onSuccess : function(datapointer)	{
				control.renderFunctions.translateTemplate(control.data[datapointer],'unorderedList_'+datapointer.split('|')[1]);
				},
			onError : function(d)	{
				control.utilityFunctions.dataDumper('got to getQuickProd error!');
				}
			},//getProdForList
			
		getResults : {
			onSuccess : function(datapointer)	{
//				control.utilityFunctions.dataDumper('got to getResults success. datapointer = '+datapointer);
				if($.isEmptyObject(control.data[datapointer]['@products']) || control.data[datapointer]['@products'].length == 0)
					control.prodlistFunctions.handleZeroResultSet(datapointer);
				else	{
					control.prodlistFunctions.handleProductList(datapointer);
					}
				},
			onError : function(d)	{
				control.utilityFunctions.dataDumper('got to getResults error!');
				$('#zContent').append("Uh Oh. It seems something went wrong. Please try again or try back in a few minutes.");
				}
			},//getResults

		inlineProdDetail : {
			onSuccess : function(datapointer)	{
				$('#prodViewer').empty().remove(); //nuke existing product viewer.
				$('#zContent').append(control.renderFunctions.createTemplateInstance('prodViewerSpec','prodViewer'));
				control.renderFunctions.translateTemplate(control.data[datapointer],'prodViewer');
				control.renderFunctions.showProdViewer(datapointer);
				},
			onError : function(d)	{
				control.utilityFunctions.dataDumper('inlineProductDetail Error');
				}
			},
		getMultiPageData : {
			onSuccess : function(datapointer)	{
				control.utilityFunctions.dataDumper('in getMultiPageData success');
				control.data[datapointer]['haveMPData'] = 1;
				control.prodlistFunctions.updatePageLinks(datapointer);
				},
			onError : function(d)	{
				control.utilityFunctions.dataDumper('got to callback.getMultiPageData error!');
				}
			},//getMultiPageData
			
			
			
			



/*          These were in renderFunctions, but shouldn't be.          */


		showProdViewer : function(datapointer)	{
//		myController.utilityFunctions.dataDumper('Product Viewer executed. GA event should probably occur here.');
			$('#prodViewer').attr("title",control.data[datapointer]['%attribs']['zoovy:prod_name']).dialog({
//			height: $(window).height() - 100,
				width: '94%',
				modal: true,
				buttons: {"Continue Shopping" : function() {$( this ).dialog( "close" );}}
				});
//		$('#prodViewer').siblings('div.ui-dialog-titlebar').hide(); //to remove the title bar, hide this.
			}, //showProdViewer




// !!!! the following three functions are only a few times.  There's probably a better way to handle this.


//run any time a new content set is loaded that is not checkout or multipage content. (ex jumping from page 3 to 4 in a prodlist doesn't execute this).
		loadNewContent : function()	{
			$('#zContent').empty();
			$('#zCheckoutContainer').addClass('displayNone');
			this.resetOrderedList();
			},
//run this any time the checkout button is pushed.
		loadCheckout : function()	{
			$('#zContent').empty();
			$('#unorderedList').empty();
			$("#zCheckoutContainer").removeClass("displayNone");
//the loading class is added to the individual panels in checkout elsewhere.
			},
//used in multipage format to blank out existing product.
		resetOrderedList : function()	{
			$('#unorderedList').empty();
			},






////////////////////////////////////   						prodlistFunctions						    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	
	prodlistFunctions : {

		jumpToPage : function(datapointer,pageIndex)	{
	// GA event here?
			control.utilityFunctions.dataDumper('jumping to page '+datapointer+'|'+pageIndex);
			control.prodlistFunctions.handleProductList(datapointer,pageIndex);
	//if the page dropdown is open, close it.
			if($("#multipageLinksContainer").css('display') == 'block')
				$("#multipageLinksContainer").toggle();
			control.prodlistFunctions.handleMultipageUpdate();
			}, //jumpToPage

		buildProdlistMultipageLinks : function(datapointer)	{
			var P = control.prodlistAttribs;
			var o = "<div id='prodlistHeader'>";
			o += "Displaying items <span id='multipageStartIndex'>"+P.startIndex+"<\/span> - <span id='multipageEndIndex'>"+P.endIndex+"<\/span> of "+P.numResults+" for '"+control.data[datapointer]['_v'].KEYWORDS+"'";
	//button for NEXT. cuz they're floated right, they're rendered in reverse order.
			o += "<button class='zform_button nextPage' disabled='disabled' onClick='control.prodlistFunctions.jumpToPage(\""+datapointer+"\",control.prodlistAttribs.currentPageIndex + 1);'>&#187;<\/button>";
			o += "<button class='zform_button jumpToPage' onClick='$(\"#multipageLinksContainer\").toggle();'>Pages<\/button>";
			o += "<button class='zform_button previousPage' disabled='disabled'  onClick='control.prodlistFunctions.jumpToPage(\""+datapointer+"\",control.prodlistAttribs.currentPageIndex - 1);'>&#171;<\/button>";
			o += "<div id='multipageLinksContainer'>";
			var i;
			for(i = 1, L = (P.numPages * 1); i <= L; i += 1)	{
				o += "<a href='#"+datapointer+"|page"+i+"' onClick='control.prodlistFunctions.jumpToPage(\""+datapointer+"\","+(i-1)+");' class='multipageLink_"+i+"'>";
				o += "page: "+(i);
				o += "<\/a>";
				}
			
			o += '<\/div><\/div>';
			$('#zContent').append(o);
			control.prodlistFunctions.handleMultipageUpdate();
			}, //handleMultipageUpdate

		updatePageLinks : function(datapointer)	{
			control.utilityFunctions.dataDumper('BEGIN view.updatePageLinks');
			var P = control.prodlistAttribs;
			var tmpSku;
			var lastItemOnPageIndex;
			var o = '';
			var L,i;
			for(i = 0, L = (P.numPages * 1) -1; i <= L; i += 1)	{
				o += "page: "+(i+1);
				tmpSku = control.data[datapointer]['@products'][i*P.itemsPerPage];
				if(!$.isEmptyObject(control.data['getProduct|'+tmpSku]))	{
					o += " ("+control.utilityFunctions.formatMoney(control.data['getProduct|'+tmpSku]['%attribs']['zoovy:base_price'],'$');
					o += " - ";
	//since i = 0, I * p.itemsPerPage = 0, so we compensate.
					if(i == 0){lastItemOnPageIndex = P.itemsPerPage -1}
					else	{lastItemOnPageIndex = (i*P.itemsPerPage) - 1}
					if(lastItemOnPageIndex > P.numResults)
						lastItemOnPageIndex = P.numResults - 1;
	//				control.utilityFunctions.dataDumper('lastItemOnPageIndex = '+lastItemOnPageIndex);
					tmpSku = control.data[datapointer]['@products'][lastItemOnPageIndex];
	//				control.utilityFunctions.dataDumper('tmpsku for lastIndexOnPage = '+tmpSku);
					if(!$.isEmptyObject(control.data['getProduct|'+tmpSku]))
						o += control.utilityFunctions.formatMoney(control.data['getProduct|'+tmpSku]['%attribs']['zoovy:base_price'],'$');
					o += ")";
					}
				$('.multipageLink_'+(i + 1)).empty().text(o);
				o = '';
				}
			}, //updatePageLinks




//when building in some of the multipage features, 'try' looking for the data and if it isn't there, try again in a bit.
		buildProdlistHeader : function(datapointer) {
	//		control.utilityFunctions.dataDumper('BEGIN view.buildProdlistHeader');
			$('#zContent').append('<div class="prodlistHeader">'+control.data[datapointer]['@products'].length+' items found for \"'+control.data[datapointer]['_v'].KEYWORDS+'\"<\/div>');
			}, //buildProdlistHeader
	
		genMultiPageDispatches: function(datapointer)	{
			
	//		control.utilityFunctions.dataDumper('BEGIN control.prodlistFunctions.genMultiPageDispatches datapointer = '+datapointer);
			var numResults = control.prodlistAttribs.numResults; //number of product in result set
			var itemsPerPage = control.prodlistAttribs.itemsPerPage;
			var i;
	/*
	if there are less than a few pages of product, just get everything.  
	if > 100, Instead of getting every product, get	the first and last item of every page.
	that'll let us get enough to build some cool multipage functionality.
	*/
			if((numResults < (itemsPerPage * 2)) && (itemsPerPage < 51))	{
				for(i = itemsPerPage; i < numResults; i += 1)	{  //the first X items have already been retrieved by this point.
					control.calls.getReviews.init(control.data[datapointer]['@products'][i]);
					control.calls.getQuickProd.init(control.data[datapointer]['@products'][i])
					}
				}
			else	{
				var lastItemOnPageIndex;
				for(i = itemsPerPage; i < numResults; i += itemsPerPage)	{  //the first X items have already been retrieved by this point.
	//				control.utilityFunctions.dataDumper(' -> several pages: i = '+i);
	//get the first item for each page.
					control.calls.getReviews.init(control.data[datapointer]['@products'][i]);
					control.calls.getQuickProd.init(control.data[datapointer]['@products'][i]);
	//Get the last item for each page except the last page, taking in to account that on the last page may have less than a full page (57 items)
					lastItemOnPageIndex = i+itemsPerPage - 1;
					if(lastItemOnPageIndex > numResults)	{
						lastItemOnPageIndex = numResults - 1;
						}
	//				control.utilityFunctions.dataDumper('last item on page index = '+lastItemOnPageIndex);
					control.calls.getReviews.init(control.data[datapointer]['@products'][lastItemOnPageIndex]);
					control.calls.getQuickProd.init(control.data[datapointer]['@products'][lastItemOnPageIndex]);
	//				control.utilityFunctions.dataDumper('getting items '+i+' and '+(i+itemsPerPage - 1));
					}
				
				}
			},




		handleMultipageUpdate : function()	{
			control.utilityFunctions.dataDumper('BEGIN view:handleMultipageUpdate');
			var P = control.prodlistAttribs;
			var state = false;
			if(P.currentPageIndex == 0)	{state = 'disabled';}
			$('.previousPage').attr('disabled',state);
	
			state = false;
			if(P.currentPageIndex == (P.numPages - 1))	{state = 'disabled';}
			$('.nextPage').attr('disabled',state);
			
			$('#multipageStartIndex').empty().text(P.startIndex);
			$('#multipageEndIndex').empty().text(P.endIndex);
			$('.jumpToPage').empty().text(P.currentPageIndex + 1);
			},


		handleZeroResultSet : function(datapointer)	{
			$('#zContent').append("that search returned no results. please try again.");
			}, //handleZeroResults
	
	/*
	This function is run after a search result set is returned.
	It is also executed manually from the multipage links if the prodlist is in a multipage format.
	
	determine result set size and behave accordingly:
	 -> display items (either just the first page or all, depeding on how many or if view all is selected)
	 -> if multiple pages are present, run multipage code (doesn't get run till after first page of items is requested).
	This is so that we can get some product in front of the user ASAP.
	*/
		handleProductList : function(datapointer,currentPageIndex)	{
//			control.utilityFunctions.dataDumper('in prodlistFunctions.handleProductList');
			control.renderFunctions.resetOrderedList(); //blank out the list of product.
//expedite getting the first X product from the result set in front of the user.
//			control.utilityFunctions.dataDumper(' -> currentPageIndex = '+currentPageIndex);
			var P = control.prodlistAttribs;
			var sku,i; //sku in focus (used in loop below)
			var $listDest = $('#unorderedList');
			
//			control.utilityFunctions.dataDumper(' -> $listDest = ');
//			control.utilityFunctions.dataDumper($listDest);
			
			P.currentPageIndex = (currentPageIndex * 1) || 0; //default to page 1/only page. page 1 currentPageIndex = 0. page 2 currentPageIndex = 1.
			P.numResults = control.data[datapointer]['@products'].length; //number of product in result set
			P.numPages = Math.ceil(P.numResults/P.itemsPerPage); //total number of pages (math.ceil will round up from 2.1 to 3)
			P.numItemsDisplayed = P.numResults <= P.itemsPerPage ? P.numResults : P.itemsPerPage;  //number of items to retrieve. could be same as itemsPerPage or fewer.
			P.startIndex = P.currentPageIndex * P.itemsPerPage;  //the index at which to start (0,10,20 etc)
	
	//on the last page of a multipage format, don't loop more than necessary (ex: 57 items returned, last page only has 7 items)
			if((P.numPages - 1) == P.currentPageIndex)	{
	//			control.utilityFunctions.dataDumper('got into last page code for multipage');
				P.numItemsDisplayed = P.numResults - (P.currentPageIndex * P.itemsPerPage); // ex: 57 - (5 * 10) = 7
				}
	
			P.endIndex = P.startIndex + P.numItemsDisplayed; //the index at which to stop (10, 27, etc)
	
			for(i = P.startIndex; i < P.endIndex; i += 1)	{
				sku = control.data[datapointer]['@products'][i];
//				control.utilityFunctions.dataDumper(' -> createTemplateInstance for '+sku);
	//create placeholder li for sku. this needs to be first, otherwise data loaded from 'this' or 'local' will get loaded prior to items called with ajax
	//which results in the incorrect sort order.
				$listDest.append(control.renderFunctions.createTemplateInstance('myResultsSpec',{'id':'unorderedList_'+sku,'pid':sku}));
	
	//FIFO in the DQ, so reviews get added first so we know they're present when prod. manipulation occurs.
				control.calls.getReviews.init(sku);
				control.calls.getQuickProd.init(sku,'getProdForList');
				}
			control.prodlistAttribs = P; //set the prodlist attribs in the control. this allows lots of view functions to get them without redoing all the math. 
	
			if(P.numPages > 1)	{
				if($('#prodlistHeader').length > 0){
//function to make updates to header.
					control.prodlistFunctions.updatePageLinks(datapointer); //right now, these are computed with each page change. once filtering and sorting are in place, we 'may' need this here or to move it. !!!
					}
				else	{
					control.prodlistFunctions.buildProdlistMultipageLinks(datapointer)
					}
				}
			else
				control.prodlistFunctions.buildProdlistHeader(datapointer); //simple header for low # of results.
	
			control.calls.getMultiPageData.init(datapointer);
			control.model.dispatchThis();
			} //handleProductList
		}, //prodlistFunctions






///   Was it's own node.  Not even sure if it is/was used. probably was replaced with a call.
	handleAddToCart : function(sku,formid)	{
//		control.utilityFunctions.dataDumper('BEGIN control.handleAddToCart. sku = '+sku+' and formid = '+formid);
		if(validate_pogs(formid,control.data['getProduct|'+sku]['@variations'],control.data['getProduct|'+sku]['@inventory'],sku))	{
			control.calls.addToCart.init({'data':$('#'+formid).serialize()},'addToCart');
			control.model.dispatchThis('priorityDispatchQ');
			}
		}











some callbacks


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















	
	

//   displayFunctions
	displayFunctions : {
		showReviewPanel : function(PID)	{
			control.util.dump('BEGIN displayFunctions.showReviewPanel. PID = '+PID);
			
			$('#postRequestMessage').empty(); //clear any past messaging.
			$('#reviewAlerts').empty(); //clear any past errors.
			$('#reviewForm').toggle(true); //make sure form is visible. is turned off when a successful review is left.
			$( "#writeReviewFrmContainer" ).dialog({
				height: 500,
				width: 500,
				modal: true
				});
			$('#writeReviewPid').val(PID);
			}
		},










some renderFormats:

/* MOVE THESE TO the appropriate EXTENSION 
		reviewAverageRank : function($tag,data)	{
//				myControl.util.dump('BEGIN myControl.renderFormats.reviewAverageRank.');
			var sku = data.value;
			if($.isEmptyObject(myControl.data['getReviews|'+sku]))	{
//					myControl.util.dump(" -> data.['getReviews|'"+sku+"] is empty object.");					
				}
			else	{
				var o = '';
//					myControl.util.dump(' -> SKU = '+sku);
				var numReviews = myControl.model.countProperties(myControl.data['getReviews|'+sku]['@reviews']);
				var reviewAverage = 0;
//					myControl.util.dump(' -> numReviews = '+numReviews);
				
				if(numReviews > 0)	{
					for(var i = 0; i < numReviews; i += 1)	{
						reviewAverage += myControl.data['getReviews|'+sku]['@reviews'][i].RATING * 1;
						}
					reviewAverage = Math.round(reviewAverage/numReviews);
					o = 'avg '+reviewAverage+' from '+numReviews+' reviews';
					}
				else	{
	//item not yet reviewed.				
					}
				$tag.html(o);
				}
			},
			
// in this case, we aren't modifying an attribute of $tag, we're appending to it.
		addToCartFrm : function($tag,data)	{
			var sku = data.value;  
			var containerId = data.safeTarget+'_'+sku+'_containter'; //used to set id on $tag
			$tag.attr("id",containerId);
			var $myForm = $('<form>').attr({"id":"prodViewerAddToCartFrm","name":"prodViewerAddToCartFrm","action":""}).bind('submit',function(){return false;}).append("<input type='hidden' name='product_id' id='prodViewerProductId_"+sku+"' value='"+sku+"' /><input type='hidden' name='add' value='yes' /><div id='JSONpogErrors' class='zwarn' /><div id='JSONPogDisplay' /><button class='zform_button addToCartButton addToCartButton_"+sku+"' onClick='myControl.handleAddToCart(\""+sku+"\",\"prodViewerAddToCartFrm\");'} return false;'>Add To Cart</button>")
			$myForm.appendTo($('#'+containerId))

			
			if(!$.isEmptyObject(myControl.data['getProduct|'+sku]['@variations']) && myControl.model.countProperties(myControl.data['getProduct|'+sku]['@variations']) > 0)	{

				pogs = new handlePogs(myControl.data['getProduct|'+sku]['@variations'],{
"formId":"prodViewerAddToCartFrm",
"invCheck":true,
"sku":sku,
"imgBaseUrl":"//static.zoovy.com/img/"+myControl.vars.username+"/"});
				var pog;
//				pogs.xinit();  //this only is needed if the class is being extended (custom sog style)
				var ids = pogs.listOptionIDs();
				for ( var i=0, len=ids.length; i<len; ++i) {
					pog = pogs.getOptionByID(ids[i]);
					pogs.renderOption(pog)
					}
				}

			}, //addToCartFrm
*/