// NOTE  -  this is an old file.  
//show-stopping defects should be corrected here, as it is still referenced.
//New functions should get added to zoovy/addtocart...


function updateCart() {

	$('contentMinicart').innerHTML = 'Updating - please wait!';
	new Effect.Highlight($('contentMinicart'));
	
	// this gets called by handleResponse (which is in zoovy.js)
   var postBody = 'm=RenderElement&format=WRAPPER&docid='+DOCID+'&element=IMAGECART&targetDiv=contentMinicart';
	new Ajax.Request('/ajax/RenderElement', { postBody: postBody, asynchronous: 1,
		onComplete: function(request){handleResponse(request.responseText);} }
		) ;
	}

//
// this function is overloaded, and is run whenever an "add_to_cart" button is clicked
//		it finds the form with a product id that matches on it.
//
function addToCart(id,pid) {
	// alert("adding To Cart (product: " + pid + ")");

   var postBody = 'm=AddToCart&cart='+session_id+'&pid='+pid;
	for (i = document.forms.length-1; i>=0; --i) {
		if (document.forms[i].elements['product_id']) {
			if (document.forms[i].elements['product_id'].value == pid) {
				postBody = postBody + '&' + Form.serialize(document.forms[i]);
			   new Ajax.Request('/ajax/AddToCart', { postBody: postBody, asynchronous: 1,
			      onComplete: function(request){handleResponse(request.responseText);} }
			      ) ;
				}
			}
		}
	// alert('finished with addToCart');	
	}
	
	
	
/*  This uses the old variable names.  if there are no isues after 8/1/07, delete this


function updateCart() {

	$('PUTCARTHERE').innerHTML = 'Updating - please wait!';
	new Effect.Highlight($('PUTCARTHERE'));
	
	// this gets called by handleResponse (which is in zoovy.js)
   var postBody = 'm=RenderElement&format=WRAPPER&docid='+DOCID+'&element=IMAGECART&targetDiv=PUTCARTHERE';
	new Ajax.Request('/ajax/RenderElement', { postBody: postBody, asynchronous: 1,
		onComplete: function(request){handleResponse(request.responseText);} }
		) ;
	}
	
	
	
	
//
// this function is overloaded, and is run whenever an "add_to_cart" button is clicked
//		it finds the form with a product id that matches on it.
//
function addToCart(id,pid) {
	// alert("adding To Cart (product: " + pid + ")");

   var postBody = 'm=AddToCart&cart='+session_id+'&pid='+pid;
	for (i = document.forms.length-1; i>=0; --i) {
		if (document.forms[i].elements['product_id']) {
			if (document.forms[i].elements['product_id'].value == pid) {
				postBody = postBody + '&' + Form.serialize(document.forms[i]);
			   new Ajax.Request('/ajax/AddToCart', { postBody: postBody, asynchronous: 1,
			      onComplete: function(request){handleResponse(request.responseText);} }
			      ) ;
				}
			}
		}
	// alert('finished with addToCart');	
	}


*/
