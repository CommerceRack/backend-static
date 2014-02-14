/*
myKeywords is set in the theme as well as the number of keywords to be displayed.
If a word is searched, prepend it to the keyword variable separated by a pipe - | and save it back to the cart.
redisplay list of keywords with the newest word at the top, do NOT retrieve again from cart.
display the search results in appropriate div.
*/



/* ##### this is the master function to display the updated list of keywords and the search results.
1. look to see if myKeywords has a value.
  	if so: append myKeywords to the new word as update var.
 		if no: set new word to update var.
2. update CART with the list of keywords.
3. Update display of keywords with latest edition.
4. Load the search results into the magically appearing div. 
*/

function updateKeywordList(newWord) {
//if myKeywords isn't blank, postpend them onto value, separated by a pipe.
	if(myKeywords != '')
		var update = newWord+'|'+myKeywords;
	else
		var update = newWord;

//Set the postbody var.
	var postBody = 'm=set&data='+update+'&src=CART::SEARCH_KEYWORDLIST&cart='+session_id;
//Update the cart with the pipe separated list of keywords.
//onComplete, load the results of the new Word and update the list of keywords that are displayed.
	new Ajax.Request('/ajax/set', { postBody: postBody, asynchronous: 1, onComplete: function(request){
		displayKeywords();
	}});
	return update;
	}

/*	##### This functions will update the recent searches div. It reloads a SCRIPT element.*/
function displayKeywords() {
	var postBody = 'm=RenderElement&format=WRAPPER&docid='+DOCID+'&element=RECENTSEARCHES&targetDiv=keywordsContent';
	new Ajax.Request('/ajax/RenderElement', { postBody: postBody, asynchronous: 1,
		onComplete: function(request){handleResponse(request.responseText);} }
		) ;
	}

/*  ##### THis function will load the search results into a div. */

function loadResults(keywords){
// set text in div to let user know a search is being conducted.
	$("contentResults").innerHTML = 'Searching, please wait...';
//if the results panel is already open, no need to open it again, just higlight it to let the user know something has changed.
	if($("panelResults").style.display=="none") 
		Effect.SlideDown("panelResults");
	else
		new Effect.Highlight($("panelResults"));
		
	var postBody = 'm=RenderElement&AJAX=1&format=WRAPPER&docid='+DOCID+'&element=WRAPRESULTS&targetDiv=contentResults&CATALOG='+mySearchCatalog+'&mode='+mySearchMode+'&keywords='+keywords;
	new Ajax.Request('/ajax/RenderElement', { postBody: postBody, asynchronous: 1,
		onComplete: function(request){handleResponse(request.responseText);} }
		) ;
//	alert(postBody);
	}


/* !!!! begin functions for image rollover/enlarge effect !!!! */

if (document.getElementById || document.all){
	document.write('<div id="trailimageid">');
	document.write('</div>');
	}

function gettrailobj(){
	if (document.getElementById)
		return document.getElementById("trailimageid").style
	else if (document.all)
		return document.all.trailimagid.style
	}

function gettrailobjnostyle(){
	if (document.getElementById)
		return document.getElementById("trailimageid")
	else if (document.all)
		return document.all.trailimagid
	}


function truebody(){
	return (!window.opera && document.compatMode && document.compatMode!="BackCompat")? document.documentElement : document.body
}

function showtrail(imagename,title,description,ratingaverage,ratingnumber,showthumb,height){

	if (height > 0){
		currentimageheight = height;
	}

	document.onmousemove=followmouse;

	cameraHTML = '';

	newHTML = '<div style="padding: 5px; background-color: #FFF;" class="zborder">';

	if (showthumb > 0){
		newHTML = newHTML + '<div align="center"><img src="' + imagename + '" border="0"></div>';
	}

	newHTML = newHTML + '</div>';

	gettrailobjnostyle().innerHTML = newHTML;

	gettrailobj().visibility="visible";

}


function hidetrail(){
	gettrailobj().visibility="hidden"
	document.onmousemove=""
	gettrailobj().left="-500px"

}

function followmouse(e){
	var xcoord=offsetfrommouse[0]
	var ycoord=offsetfrommouse[1]
	var docwidth=document.all? truebody().scrollLeft+truebody().clientWidth : pageXOffset+window.innerWidth-15
	var docheight=document.all? Math.min(truebody().scrollHeight, truebody().clientHeight) : Math.min(document.body.offsetHeight, window.innerHeight)

	if (typeof e != "undefined"){
		if (docwidth - e.pageX < 195){
			xcoord = e.pageX - xcoord - 200; // Move to the left side of the cursor
			}
		else {
			xcoord += e.pageX;
			}
		if (docheight - e.pageY < (currentimageheight + 110)){
			ycoord += e.pageY - Math.max(0,(110 + currentimageheight + e.pageY - docheight - truebody().scrollTop));
			}
		else {
			ycoord += e.pageY;
			}

		}
	else if (typeof window.event != "undefined")	{
		if (docwidth - event.clientX < 200){
			xcoord = event.clientX + truebody().scrollLeft - xcoord - 190; // Move to the left side of the cursor
			}
		else {
			xcoord += truebody().scrollLeft+event.clientX
			}
		if (docheight - event.clientY < (currentimageheight + 110)){
			ycoord += event.clientY + truebody().scrollTop - Math.max(0,(110 + currentimageheight + event.clientY - docheight));
			}
		else {
			ycoord += truebody().scrollTop + event.clientY;
			}
		}

	var docwidth=document.all? truebody().scrollLeft+truebody().clientWidth : pageXOffset+window.innerWidth-15
	var docheight=document.all? Math.max(truebody().scrollHeight, truebody().clientHeight) : Math.max(document.body.offsetHeight, window.innerHeight)

	gettrailobj().left=xcoord+"px"
	gettrailobj().top=ycoord+"px"

	}