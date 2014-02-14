//!!!!! Theme JS



//##### Zoovy Ajax Code

// this gets called by handleResponse (which is in zoovy.js)
function updateCart() {
	$('PUTCARTHERE').innerHTML = 'Updating - please wait!';
//This is the update for the hidden cart element.
	var postBody = 'm=RenderElement&format=WRAPPER&docid='+DOCID+'&element=IMAGECART&targetDiv=PUTCARTHERE';
	new Ajax.Request('/ajax/RenderElement', { postBody: postBody, asynchronous: 1,
		onComplete: function(request){handleResponse(request.responseText);} });

//this is the update for the visible cart element.
	var postBody = 'm=RenderElement&format=WRAPPER&docid='+DOCID+'&element=VISIBLE_CART_ELEMENT&targetDiv=VISIBLE_CART';
	new Ajax.Request('/ajax/RenderElement', { postBody: postBody, asynchronous: 1,
		onComplete: function(request){handleResponse(request.responseText);} });

	}

// this function is overloaded, and is run whenever an "add_to_cart" button is clicked
//		it finds the form with a product id that matches on it.

function addToCart(id,pid) {
	
	
	
//if the cart div is hidden, display it.  Otherwise do nothing (it's already visible)

	
	showPanel('panelCart')	

	
	var postBody = 'm=AddToCart&cart='+session_id+'&pid='+pid;
	for (i = document.forms.length-1; i>=0; --i) {
		if (document.forms[i].elements['product_id']) {
			if (document.forms[i].elements['product_id'].value == pid) {
				postBody = postBody + '&' + Form.serialize(document.forms[i]);
				new Ajax.Request('/ajax/AddToCart', { postBody: postBody, asynchronous: 1,
				onComplete: function(request){handleResponse(request.responseText);} });
				}
			}
		}
	}
	

//##### Form code - pretty basic js

//used in the newsletter subscription form and elsewhere.
function clearText(thefield)	{
	if (thefield.defaultValue == thefield.value)
		thefield.value = "";
	}

function replaceText(thefield)	{
	if (thefield.value == "")
		thefield.value = thefield.defaultValue;
	}
	
	


//##### Panel and Modal code. Used pretty heavily on the product page, but may get used elsewhere too
//turn on modal. panelID is not actually used to create the modal itself, but it is handy to know inside this script which div is being activated

function modalificate(panelID)	{
//An outer div is created to contain the transparent div.  The outer div is needed so the ajax 'appear' effect doesn't bring the transparency up to 100%. 
	var modalDiv = document.createElement("div");
	with(modalDiv) {
		setAttribute("id", "zmodal");
		style.display="none"; // IE sucks and doesn't support style for setAttribute. 
		}
	document.getElementById("wrapper").appendChild(modalDiv);

//An inner div is created with a class that has opacity on it.  The ajax effect is run on the outer div but the class with absolute positioning makes this div span the entire height/width.
	var modalDivTrans = document.createElement("div");
	with(modalDivTrans) {
		setAttribute("id", "zmodal");
		setAttribute("class", "modal");
		}
	document.getElementById("zmodal").appendChild(modalDivTrans);	

	new Effect.Appear("zmodal");

	}

//turns off the modal.
function demodalificate() {
	new Effect.Fade("zmodal");
	
//after a few seconds, once the fade has occured, remove the child node
	d = document.getElementById('zmodal');
	setTimeout('d.parentNode.removeChild(d)',1800);
	}

function closePanel(panelID)	{
//if the panel is visible, close it. ajax sets the display attribute to blank when it runs an effect.
	if($(panelID).style.display == "") {
		
		new Effect.Fade(panelID);
		demodalificate();
		}
	}
	
function showPanel(panelID)	{
// if the panel is closed, open it.
	if($(panelID).style.display == "none") {
		modalificate(panelID);
		new Effect.Appear(panelID);
		}
	}










//!!!!!  Product Layout Scripts


// ##### Magic Tool Box 
MagicThumb.options = {
//	backgroundFadingColor: '#cccccc', 
//	backgroundFadingDuration: 0.4, 
	backgroundFadingOpacity : 0.7,
	keepThumbnail: true
	}






/*
##### Reviews Code

Hacked apart the script found here:
	http://www.geekpedia.com/tutorial199_Dynamic-5-Star-Rating-Script.html
*/

//executed on mouseover of image. Turns on focus image and all images 'lower' ranked than focus. (so rolling over 3 turns on images 1 and 2)
function fillstars(x)	{
	y=x*1+1

	switch(x)	{
		
		case "1": document.getElementById('zRatingIcon_'+x).src= star2.src;
		break;

		case "2":for (i=1;i<y;i++)	{
			document.getElementById('zRatingIcon_'+i).src= star2.src;
			}
		break;

		case "3":for (i=1;i<y;i++)	{
			document.getElementById('zRatingIcon_'+i).src= star2.src;
			}
		break;
		
		case "4":for (i=1;i<y;i++)	{
			document.getElementById('zRatingIcon_'+i).src= star2.src;
			}
		break;
		
		case "5":for (i=1;i<y;i++)	{
			document.getElementById('zRatingIcon_'+i).src= star2.src;
			}
		break;
		
		}
	
	}

//resets images to off/empty.  If zRating has already been set, it will only revert to the empty review images for review images above the current zRating.
// the review images will not go back to empty if the shopper tries to reduce the ranking unless they actually 'click' a lower ranking.  Then the review images reset
function emptystars(x)	{
	if (!zRating)	{
		for (i=1;i<6;i++)	
			document.getElementById('zRatingIcon_'+i).src = star1.src;
		}
	else	{
		for (i=1;i<6;i++)	{
			document.getElementById('zRatingIcon_'+i).src = (i <= zRating) ?  star2.src :  star1.src;
			}
		}
	}

//executed when rating image is clicked.
function setStar(x)	{
	y=x*1+1
	switch(x)	{
		case "1": zRating="1" 
		flash(zRating);
		break;
		case "2": zRating="2" 
		flash(zRating);
		break;
		case "3": zRating="3" 
		flash(zRating);
		break;
		case "4":zRating="4" 
		flash(zRating);
		break;
		case "5":zRating="5" 
		flash(zRating);
		break;
		}
//	alert(zRating);
	document.getElementById('RATING').value = zRating;
	//	document.getElementById('vote').innerHTML="Thank you for your vote!"
	}

function flash()	{
	y=zRating*1+1
	switch(v)	{
		case 0:
		for (i=1;i<y;i++)	{
			document.getElementById('zRatingIcon_'+i).src= star1.src;
			}
		v=1
		setTimeout(flash,200)
		break;
		case 1:	
		for (i=1;i<y;i++)		{
			document.getElementById('zRatingIcon_'+i).src= star2.src;
			}
		v=2
		setTimeout(flash,200)
		break;
		case 2:
		for (i=1;i<y;i++)		{
			document.getElementById('zRatingIcon_'+i).src= star1.src;
			}
		v=3
		setTimeout(flash,200)
		break;
		case 3:
		for (i=1;i<y;i++)		{
			document.getElementById('zRatingIcon_'+i).src= star2.src;
			}
		v=4
		setTimeout(flash,200)
		break;
		case 4:
		for (i=1;i<y;i++)		{
			document.getElementById('zRatingIcon_'+i).src= star1.src;
			}
		v=5
		setTimeout(flash,200)
		break;
		case 5:
		for (i=1;i<y;i++)		{
			document.getElementById('zRatingIcon_'+i).src= star2.src;
			}
		v=6
		setTimeout(flash,200)
		break;
		}
	}
	
	
	
	