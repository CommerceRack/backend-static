/*
Change Log:

2010-10-18 - 	added 2 new functions for support of ajax add to cart for a SPEC (prodlist or prodsearch). prodlistAddToCart and resetForm



*/


//			!!!!!!!!!   var magic_url MUST be set within theme. !!!!!!!!!!!!


function updateCart() {

	$('contentMinicart').innerHTML = "<div align='center' class='zajax_loading'>Loading... Please Wait<\/div>";
	new Effect.Highlight($('contentMinicart'));
	
	// this gets called by handleResponse (which is in zoovy.js)
   var postBody = 'm=RenderElement&format=WRAPPER&docid='+DOCID+'&element=IMAGECART&targetDiv=contentMinicart';
	new Ajax.Request(magic_url+'/ajax/RenderElement', { postBody: postBody, asynchronous: 1,
		onComplete: function(request){handleResponse(request.responseText);} }
		) ;
	}

//
// this function is overloaded, and is run whenever an "add_to_cart" button is clicked
//		it finds the form with a product id that matches on it.
//
function addToCart(id,pid) {
//	 alert("adding To Cart (product: " + pid + "). \nsession id = "+session_id);

   var postBody = 'm=AddToCart&cart='+session_id+'&pid='+pid;
	for (i = document.forms.length-1; i>=0; --i) {
		if (document.forms[i].elements['product_id']) {
			if (document.forms[i].elements['product_id'].value == pid) {
				postBody = postBody + '&' + Form.serialize(document.forms[i]);
// alert(postBody);			   
					new Ajax.Request(magic_url+'/ajax/AddToCart', { postBody: postBody, asynchronous: 1,
			      onComplete: function(request){handleResponse(request.responseText);} }
			      ) ;
				}
			}
		}
	// alert('finished with addToCart');	
	}
	
	



//   ########   the following functions are used for adding items to the cart via ajax within a SPEC-based element (PRODLIST, PRODSEARCH, etc)



/*

This function is executed 'onSubmit' on the form that contains the prodlist. pass 'this' as formObject.
call like so, which will default gracefully if the function is not defined.

<form name='catAddToCartFrm' id='catAddToCartFrm' onSubmit="if(typeof(prodlistAddToCart) == 'function'){prodlistAddToCart(this); return false;} else {return true}" method='post' action='%CART_URL%'>

*/


function prodlistAddToCart(formObject) {
//jumps to top of page. effectively href='#top'
	window.location.hash="top";

//set class .zajax_loading in theme (='background: url(%GRAPHICS_URL%/loading/circles_green-54x55.gif) no-repeat; padding-top:60px;')
	$('contentMinicart').innerHTML = "<div align='center' class='zajax_loading'>Loading... Please Wait<\/div>";
//	alert("adding To Cart. form id = "+formObject.id);

	var postBody = 'm=AddToCart&cart='+session_id;
	postBody = postBody + '&' + Form.serialize($(formObject.id));
	new Ajax.Request(magic_url+'/ajax/AddToCart', {
	postBody: postBody, asynchronous: 1, onComplete: function(request){
			handleResponse(request.responseText);
			resetForm(formObject);
			}
		});
	}
	

/*
after the items are added to the cart, this function gets run.
it resets all the textboxes on the page to a quantity of 0 so that if add to cart is pushed again,
the items do not get added again. makes it easier for people who push add to cart for each item instead 
of adjusting quantities all at once and pushing the button once (otherwise they'd have to reset values themselves)
*/

function resetForm(formObject)	{
//	alert('got here');
	for(i=0; i < formObject.elements.length; i++)	{
	if(formObject.elements[i].type == 'text')
		formObject.elements[i].value = 0;
		}
	}

