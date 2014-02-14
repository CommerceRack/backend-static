
//This is the action used on the product page thumbnails when the image is clicked.
function zoom (url) {
	z = window.open('','zoom_popUp','status=0,directories=0,toolbar=0,menubar=0,resizable=1,scrollbars=1,location=0');
	z.document.write('<html>\n<head>\n<title>Picture Zoom</title>\n</head>\n<body>\n<div align="center">\n<img src="' + url + '"><br>\n<form><input type="button" value="Close Window" onClick="self.close(true)"></form>\n</div>\n</body>\n</html>\n');
	z.document.close();
	z.focus(true);
	}
	

//  The tab scripts below came from dynamic drive.  They're used on the product page for the 5 tabs (description, images, reviews, accessories and details).  Images must always be the second tab because the tabs are referenced numerically in the order they appear (tab1  = images) and that tab is referenced from another button that conditionally appears.

//** Tab Content script-  Dynamic Drive DHTML code library (http://www.dynamicdrive.com)
//** Last updated: Nov 8th, 06

var enabletabpersistence=0 //enable tab persistence via session only cookies, so selected tab is remembered?

////NO NEED TO EDIT BELOW////////////////////////
var tabcontentIDs=new Object()

function expandcontent(linkobj){
var ulid=linkobj.parentNode.parentNode.id //id of UL element
var ullist=document.getElementById(ulid).getElementsByTagName("li") //get list of LIs corresponding to the tab contents
for (var i=0; i<ullist.length; i++){
ullist[i].className=""  //deselect all tabs
if (typeof tabcontentIDs[ulid][i]!="undefined") //if tab content within this array index exists (exception: More tabs than there are tab contents)
document.getElementById(tabcontentIDs[ulid][i]).style.display="none" //hide all tab contents
}
linkobj.parentNode.className="selected"  //highlight currently clicked on tab
document.getElementById(linkobj.getAttribute("rel")).style.display="block" //expand corresponding tab content
saveselectedtabcontentid(ulid, linkobj.getAttribute("rel"))
}

function expandtab(tabcontentid, tabnumber){ //interface for selecting a tab (plus expand corresponding content)
var thetab=document.getElementById(tabcontentid).getElementsByTagName("a")[tabnumber]
if (thetab.getAttribute("rel"))
expandcontent(thetab)
}

function savetabcontentids(ulid, relattribute){// save ids of tab content divs
if (typeof tabcontentIDs[ulid]=="undefined") //if this array doesn't exist yet
tabcontentIDs[ulid]=new Array()
tabcontentIDs[ulid][tabcontentIDs[ulid].length]=relattribute
}

function saveselectedtabcontentid(ulid, selectedtabid){ //set id of clicked on tab as selected tab id & enter into cookie
if (enabletabpersistence==1) //if persistence feature turned on
setCookie(ulid, selectedtabid)
}

function getullistlinkbyId(ulid, tabcontentid){ //returns a tab link based on the ID of the associated tab content
var ullist=document.getElementById(ulid).getElementsByTagName("li")
for (var i=0; i<ullist.length; i++){
if (ullist[i].getElementsByTagName("a")[0].getAttribute("rel")==tabcontentid){
return ullist[i].getElementsByTagName("a")[0]
break
}
}
}

function initializetabcontent(){
for (var i=0; i<arguments.length; i++){ //loop through passed UL ids
if (enabletabpersistence==0 && getCookie(arguments[i])!="") //clean up cookie if persist=off
setCookie(arguments[i], "")
var clickedontab=getCookie(arguments[i]) //retrieve ID of last clicked on tab from cookie, if any
var ulobj=document.getElementById(arguments[i])
var ulist=ulobj.getElementsByTagName("li") //array containing the LI elements within UL
for (var x=0; x<ulist.length; x++){ //loop through each LI element
var ulistlink=ulist[x].getElementsByTagName("a")[0]
if (ulistlink.getAttribute("rel")){
savetabcontentids(arguments[i], ulistlink.getAttribute("rel")) //save id of each tab content as loop runs
ulistlink.onclick=function(){
expandcontent(this)
return false
}
if (ulist[x].className=="selected" && clickedontab=="") //if a tab is set to be selected by default
expandcontent(ulistlink) //auto load currenly selected tab content
}
} //end inner for loop
if (clickedontab!=""){ //if a tab has been previously clicked on per the cookie value
var culistlink=getullistlinkbyId(arguments[i], clickedontab)
if (typeof culistlink!="undefined") //if match found between tabcontent id and rel attribute value
expandcontent(culistlink) //auto load currenly selected tab content
else //else if no match found between tabcontent id and rel attribute value (cookie mis-association)
expandcontent(ulist[0].getElementsByTagName("a")[0]) //just auto load first tab instead
}
} //end outer for loop
}


function getCookie(Name){ 
var re=new RegExp(Name+"=[^;]+", "i"); //construct RE to search for target name/value pair
if (document.cookie.match(re)) //if cookie found
return document.cookie.match(re)[0].split("=")[1] //return its value
return ""
}

function setCookie(name, value){
document.cookie = name+"="+value //cookie value is domain wide (path=/)
}





// I don't think this is used anymore.  I believe I got rid of all popups. ?
function openWindow(url) {
	adviceWin = window.open(url,'advice','status=no,width=560,height=400,menubar=no,scrollbars=yes');
	adviceWin.focus(true);
	}

//These are the scripts for the dynamic image rollover piece.  It is used in the 'accessories' tab.

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
		} else {
			xcoord += e.pageX;
		}
		if (docheight - e.pageY < (currentimageheight + 110)){
			ycoord += e.pageY - Math.max(0,(110 + currentimageheight + e.pageY - docheight - truebody().scrollTop));
		} else {
			ycoord += e.pageY;
		}

	} else if (typeof window.event != "undefined"){
		if (docwidth - event.clientX < 200){
			xcoord = event.clientX + truebody().scrollLeft - xcoord - 190; // Move to the left side of the cursor
		} else {
			xcoord += truebody().scrollLeft+event.clientX
		}
		if (docheight - event.clientY < (currentimageheight + 110)){
			ycoord += event.clientY + truebody().scrollTop - Math.max(0,(110 + currentimageheight + event.clientY - docheight));
		} else {
			ycoord += truebody().scrollTop + event.clientY;
		}
	}

	var docwidth=document.all? truebody().scrollLeft+truebody().clientWidth : pageXOffset+window.innerWidth-15
	var docheight=document.all? Math.max(truebody().scrollHeight, truebody().clientHeight) : Math.max(document.body.offsetHeight, window.innerHeight)

	gettrailobj().left=xcoord+"px"
	gettrailobj().top=ycoord+"px"

}


//This is used in the images tab for the rollover.  Pass in the url of the new image.  PRetty basic.
function DoSwap(imgURL){
	document.bigimage.src = imgURL;
}