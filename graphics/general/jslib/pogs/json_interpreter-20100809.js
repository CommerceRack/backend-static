/* 


Change Log
2010-08-09
 - added support for MTB (MagicToolBox) in updateThumb function and ImageGrid option spec.

2009-11-30
 - added basic support for 'flags'   !!!!!!!!!!!!!! need to upgrade this from boolean to bitwise in handlePogPrice() function 
 - updated text inputs so maxlength wouldn't be set in form unless set on option (setting to blank caused browser to default to maxlength = 0)
 - updated validation script so type='attribs' would not be validated.  better handling of forms with blank value.
 - better handling of blank values for text inputs (IE was showing as 'undefined' - literally).

2009-11-18 - changed price display so it used a function.  That'll make it easier for later updates.  handlePogPrice();
2009-11-17 - added missing $ to price modifiers.
2009-10-14 - new json saves as 10-15. changed var pogErrors to JSONpogErrors in validate function.

2009-10-14 - IE wasn't supporting maxlength on text inputs. JS function added.
2009-10-14 - added change log. :)  

2009-10-04 - Updated to max placement of pogs more flexible. 2 divs now required:
JSONPogDisplay - will update this div with the pog content.
JSONpogErrors - will update this div with errors for pog validation

*/


//determine if MagicThumb is loaded.  If so, enable it.
if(typeof MagicThumb.expand == 'function')
	var MZP = 'MT';
else
	var MZP = '';


/*
A very simple validation script for making sure that 'non-optional' options have a value.
a div with the id 'pogErrors' must be present in the layout for this to work properly.
*/

function validate_pogs ( ){
	valid = true;
	$('JSONpogErrors').innerHTML = "";
//if the pog var is set, loop through it and validate.  
	if(MYADD2CART_pogs)	{

		for(i = 0; i < MYADD2CART_pogs.length; i++)	{
			pogid = MYADD2CART_pogs[i]['id']; //the id is used multiple times so a var is created to reduce number of lookups needed.


//for attribs (finders) set the value to something so the if statement for displaying the error doesn't barf
			if(MYADD2CART_pogs[i]['type'] == 'attribs')	{
				pogValue = "0";
				}
//The value of a radio button is obtained slightly differently than any other form input type.
			else if(MYADD2CART_pogs[i]['type'] == 'radio' || MYADD2CART_pogs[i]['type'] == 'imggrid')	{
				pogValue = $$('input:checked[type="radio"][name="pog_"+pogid]').pluck('value');  //prototype method for getting radio button value
//				alert(MYADD2CART_pogs[i]['optional']+" and pogvalue = "+pogValue);
				}
			else	{
//was orinally just setting pogvalue to the form value, but if .value is blank, a js error was geing generated sometimes.
				pogValue = (document.addToCartFrm['pog_'+pogid].value == "") ?  "" : document.addToCartFrm['pog_'+pogid].value;
//				alert(pogid+" = "+pogValue);
				}


//If the option IS required (not set to optional) AND the option value is blank, AND the option type is not attribs (finder) record an error
			if(MYADD2CART_pogs[i]['optional'] != 1 && pogValue == "" && MYADD2CART_pogs[i]['type'] != 'attribs')	{
				valid = false;
				$('JSONpogErrors').innerHTML +=	 "The choice for '"+MYADD2CART_pogs[i]['prompt']+"' is required. Please make a selection <!--  id: "+pogid+" --><br>";
				}

			}
		}
	return valid;

	}

//Used to limit the number of characters in an input or textarea.  IE doesn't support MAXLENGTH.
function textCounter(field, maxlimit) {
    if (field.value.length > maxlimit) // if too long...trim it!
        field.value = field.value.substring(0, maxlimit);
	}


//used to load a script IF that script hasn't already been loaded. Uses the id attribute of a script tag to determine if the script has already been loaded.
function loadScript(url,scriptTagId)	{
	if(!$(scriptTagId))	{
		var e = document.createElement("script");
		e.src = url;
		e.id = scriptTagId;
		e.type="text/javascript";
		document.getElementsByTagName("head")[0].appendChild(e);
//		alert("loaded "+url);
		}
	}


//there's a lot of logic with how price should be displayed.  This is a dumbed down version but here for future compatibility.
function handlePogPrice(P,flags)	{
//	console.log("here come P:");
//	console.log(P);
//no price is displayed if the price bitwise is set to 1  -   !!!!!!!!!!!!!!!!!!! UPGRADE THIS TO SUPPORT BITWISE	
	if(flags >= 1)	{
		price = "";
		}
//Puts the + sign, if present, in the correct spot
	else if(P.charAt(0) == '+')	{
		price = " +$"+P.substr(1);
		}
//Puts the - sign, if present, in the correct spot
	else if (P.charAt(0) == "-")
		price = " -$"+P.substr(1);
//If a $ is already present, do not add one.
	else if (P.charAt(0) == "$")
		price = " "+P;
	else
		price = " $"+P;
	
	return price;
	}


//  Function for creating radio button input
function createRadio(pogid,pogvalue)	{
/*
IE once again blows.  you can use a createElement for radio buttons, but it won't be selectable.  Why would we want it selectable anyway? 
*/
	try	{  
		radioInput = document.createElement('<input name="pog_'+pogid+'" type="radio"  />');  
		}
	catch(err){  
		radioInput = document.createElement('input');  
		radioInput.setAttribute('type','radio');  
		radioInput.setAttribute('name',"pog_"+pogid);
		}  
	radioInput.className =  "zform_radio"; 
	radioInput.setAttribute("value", pogvalue);
	radioInput.setAttribute("id","pog_id_"+pogid+"_value_"+pogvalue);

	return radioInput;
	}


//if the ghint is present, add a ? to the end of the option and then put a hidden div below the option for display when the ? is clicked.	
function gHintQmark(pogid,pogHint)	{

	var ghintQMarkSpan = document.createElement("span");
	with(ghintQMarkSpan)	{
		innerHTML = " <a href='#div_"+pogid+"' onclick='$(\"ghint_"+pogid+"\").toggle(); return false;' class='ghint_qmark'><strong>?<\/strong><\/a> ";
		}
	$("div_"+pogid).appendChild(ghintQMarkSpan);
		
	var ghintDiv = document.createElement("div");
	with(ghintDiv) {
		setAttribute("id",'ghint_'+pogid);
		className = "zhint";
		style.display="none"; // IE sucks and doesn't support style for setAttribute. 
		innerHTML = pogHint;
		}
	
	$("div_"+pogid).appendChild(ghintDiv);


	}
	


//image functions


//This function will generate an image url. no src or anything else, just the url.
function zoovyImageUrl(IMGID,W,H,B)	{  //if you have to ask JT what these parameters are, you have no business being here.

	return(image_base_url+"/W"+W+"-H"+H+"-B"+B+"/"+IMGID);   // need to add support for M and P?
	}
	

/*
used with image select lists to change out the image for the selected index. 
In the standard image select, it uses the id attribute of the select list to store the image filename.
In some cases, a different file name may be needed, so the IMAGENAME var can be passed to handle this (needed if biglist is customized for image support).
MTB (MagicToolBox) - set to MT to enable MagicThumb.  may support additional MTB features later...
*/ 
function updateThumb(POGID,W,H,IMAGENAME,B)	{
//if the bgcolor isn't set, set it to white.
	if(!B)
		B = 'ffffff';

//if IMAGENAME is set, use that for the image file name.  If not, retrieve image filename from the id of the option itself
	var imgID = '';
	if(IMAGENAME)
		imgID = IMAGENAME.toLowerCase();
	else	{
		var select_list_field = $('pog_'+POGID);
		imgID = select_list_field.options[select_list_field.selectedIndex].id;
		}
//	alert(imgID);
	if(MZP == 'MT')	{
		$('imgSelect_'+POGID+'_img' ).innerHTML = "<a href='"+zoovyImageUrl(imgID,'','',B)+"' class='MagicThumb' id='href_"+POGID+"_"+imgID+"'><img src='"+zoovyImageUrl(imgID,W,H,B)+"' height='"+H+"' width='"+W+"' alt='' border='0'></a>";
		MagicThumb.start("href_"+POGID+"_"+imgID);  //activate image as MagicThumb. id is the href id, not the thumbnail id.
		}
	else	{
		$('imgSelect_'+POGID+'_img' ).innerHTML = "<a href='#' onClick='zoom(&quot;"+zoovyImageUrl(imgID,'','',B)+";&quot;)'><img src='"+zoovyImageUrl(imgID,W,H,B)+"' height='"+H+"' width='"+W+"' alt='' border='0'></a>";
		}
	}



function zoom (url) {
	z = window.open('','zoom_popUp','status=0,directories=0,toolbar=0,menubar=0,resizable=1,scrollbars=1,location=0');
	z.document.write('<html>\n<head>\n<title>Picture Zoom</title>\n</head>\n<body>\n<div align="center">\n<img src="' + url + '"><br>\n<form><input type="button" value="Close Window" onClick="self.close(true)"></form>\n</div>\n</body>\n</html>\n');
	z.document.close();
	z.focus(true);
	}










// ######################   JSON class




// NOTES - make sure you don't have a comma after the last class function or it breaks IE.

var ZoovyPOGs = Class.create({


addHandler: function(key,value,f) {
// adds a new entry to the this.handlers e.g.:
	this.handlers[ key+"." + value ] = f;
	},



initialize: function(pogs) {
	this.pogs = pogs;
	this.handlers = {};
	this.addHandler("type","text","renderOptionTEXT");
	this.addHandler("type","radio","renderOptionRADIO");
	this.addHandler("type","select","renderOptionSELECT");
	this.addHandler("type","imgselect","renderOptionIMGSELECT");
	this.addHandler("type","number","renderOptionNUMBER");
	this.addHandler("type","cb","renderOptionCB");
	this.addHandler("type","attribs","renderOptionATTRIBS");
	this.addHandler("type","readonly","renderOptionREADONLY");
	this.addHandler("type","hidden","renderOptionHIDDEN");
	this.addHandler("type","assembly","renderOptionHIDDEN");
	this.addHandler("type","textarea","renderOptionTEXTAREA");
	this.addHandler("type","imggrid","renderOptionIMGGRID");
	this.addHandler("type","calendar","renderOptionCALENDAR");
	this.addHandler("type","biglist","renderOptionBIGLIST");
	this.addHandler("unknown","","renderOptionUNKNOWN");
	},



listOptionIDs: function() {
// return an array of option id's
	var r = Array();
	for ( var i=0, len=this.pogs.length; i<len; ++i )	{
		r.push(this.pogs[i].id);
		}
	return(r);
	},



getOptionByID: function(id) {
// returns the structure of a specific option group.
	var r = null;
	for ( var i=0, len=this.pogs.length; i<len; ++i )	{
		if (this.pogs[i].id == id) {
			r = this.pogs[i];
			}
		}
	return(r);
	},





renderOptionSELECT: function(pog) {
	var pogid = pog.id;
	
	var selectList = document.createElement("select");
	with(selectList) {
		setAttribute("id", "pog_"+pogid);
		setAttribute("name", "pog_"+pogid);
		className = "zform_select";  // IE friendly way to set class
		}

    var i = 0;
    var len = pog.options.length;

//if the option is 'optional' AND has more than one option, add blank prompt. If required, add a please choose prompt first.
	if(len > 0)	{
		selOption = document.createElement("option");
		selOption.innerHTML = (pog['optional'] == 1) ?  "" :  "Please choose (required)";
// sets the required option as disabled. must then set it as selected AFTER disabling it (otherwise it auto-selects the first option)
		with(selOption)	{
			setAttribute('value', "");
			setAttribute('disabled', true);
			setAttribute('selected', true);
			}
		
		selectList.appendChild(selOption);
		}
//adds options to the select list.
    while (i < len) {
		selOption = document.createElement("option");
		selOption.setAttribute("value", pog['options'][i]['v']);
		selOption.innerHTML = pog['options'][i]['prompt'];
		if(pog['options'][i]['p'])
			selOption.innerHTML +=   handlePogPrice(pog['options'][i]['p'],pog.flags); //' '+pog['options'][i]['p'][0]+'$'+pog['options'][i]['p'].substr(1);
		selectList.appendChild(selOption);
		i++;
       }
	
	$("div_"+pogid).appendChild(selectList);


//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		gHintQmark(pogid,pog['ghint']);

	},






renderOptionBIGLIST: function(pog) {

//loadscript adds an id to the script tag when it loads the js.  If that id exists, then the script is loaded and doesn't need to be loaded again.
//this isn't working in chrome, IE or safari.
//	if(!$('bigListScript'))
//		loadScript('%GRAPHICS_URL%/DynamicOptionList-20090819.js','bigListScript');


	var pogid = pog.id;
 // this select list isn't used for the pog value. it's here purely for usability. it contains the 'first' set of choices.
/*	var selectListSkip = document.createElement("select");
	with(selectListSkip) {
		setAttribute("id", "pog_"+pogid+"skip");
		setAttribute("name", "pog_"+pogid+"skip");
		className = 'zform_select';
//		setAttribute("class", "zform_select zform_biglist  zform_biglist0");
		}
*/
 // this is the select list that will contain the 'second' set of choices. It is the one that is actually used on POST.
	
	selectListSkip = "<select id='pog_"+pogid+"skip' name='pog_"+pogid+"skip' class='zform_select zform_biglist zform_biglist1' style='margin-right:5px;'></select>";
	
	var selectList = document.createElement("select");
	with(selectList) {
		setAttribute("id", "pog_"+pogid);
		setAttribute("name", "pog_"+pogid);
		className = "zform_select";
//		setAttribute("class", "zform_select zform_biglist zform_biglist2");
		}

/*
the two select lists get added to the dom prior to the options getting inserted into them because:
as we loop through the array, the options are added each time.  
An id is assigned to the options in the first/skip select list.  
The Id's are used to see if the option already exists so that the same option isn't created twice.
 note - moving the appendChilds to the bottom doesn't fix the IE issue.
*/

	parentDiv = $("div_"+pogid);
	with(parentDiv)	{
		innerHTML += selectListSkip;
		}

	$("div_"+pogid).appendChild(selectList);

	//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		gHintQmark(pogid,pog['ghint']);



// 'i' was blowing chunks, so inc is used to increment through the loop.
    var inc = 0;
    var len = pog.options.length;





//  !!!!!!!!!   this is part of the dual-level function. don't know it well. 
// originally (default) pog_biglist was pog_AQ (where AQ = SOG id) but since we in a class, no need to make the var pog specific... right???
var pog_biglist = new DynamicOptionList();
pog_biglist.addDependentFields("pog_"+pogid+"skip","pog_"+pogid);
//pog_biglist[pogid].selectFirstOption = false;


//adds options to the select list. the prompt is stored as "list1prompt|list2prompt". selValues 0 and 1 equate to list1prompt and list2prompt, respectively.
    while (inc < len) {
		selValues = pog['options'][inc]['prompt'].split('|');
/*
defaultList is used to build the displayed 'second' list when the options initially load.
That list is based upon all the items in the array where selValue0 (or first prompt) is equal to defaultList, which is set to the first selValue0 of the array.
A variable was created for this instead of doing an indexOf or another split because it seemed like it would be faster.
*/
		if(inc < 1)	{
			defaultList = selValues[0];
			}

//builds the 'first' list of options. id is used to see if focus option has already been created so that each first option (first|second) is only added once
		if(!$('biglist_'+pogid+selValues[0]))	{
			selOption = document.createElement("option");
			selOption.setAttribute("value", selValues[0]);
			selOption.setAttribute("id", 'biglist_'+pogid+selValues[0]);
			selOption.innerHTML = selValues[0];
			$('pog_'+pogid+'skip').appendChild(selOption);
			}

//put together the default list of choices for the 'second' list.
/*		if(defaultList == selValues[0])	{
			selOptions = document.createElement("option");
			selOptions.setAttribute("value", pog['options'][inc]['v']);
			selOptions.setAttribute("id", pog['options'][inc]['v']);
			selOptions.innerHTML = selValues[1];
			selectList.appendChild(selOptions);
			}
*/	
//this is something to for the DynamicOptionList. I think it's in chinese.
		pog_biglist.forValue(selValues[0]).addOptionsTextValue(selValues[1],pog['options'][inc]['v']);
		
		inc++;  // keep inc outside that if statement or you'll blow everything to shiat.
		}



//  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1  add ghint code here...

// this initializes the dynamic select menu
	initDynamicOptionLists();

	},






renderOptionIMGSELECT: function(pog) {
	var pogid = pog.id;
	
	var selectList = document.createElement("select");
	with(selectList) {
		setAttribute("id", "pog_"+pogid);
		setAttribute("name", "pog_"+pogid);
		className =  "zform_select";
		}
//	selectList.setAttribute("onchange","updateThumb('"+pogid+"','"+pog.width+"','"+pog.height+"');");

	selectList.onchange= function(){updateThumb(pogid,pog.width,pog.height,'',MZP);};
	
    var i = 0;
    var len = pog.options.length;

//if the option is 'optional' AND has more than one option, add blank prompt. If required, add a please choose prompt first.
	if(len > 0)	{
		selOption = document.createElement("option");
		selOption.innerHTML = (pog['optional'] == 1) ?  "" :  "Please choose (required)";
// sets the required option as disabled. must then set it as selected AFTER disabling it (otherwise it auto-selects the first option)
		with(selOption)	{
			setAttribute('value', "");
			setAttribute('disabled', true);
			setAttribute('selected', true);
			}
		
		selectList.appendChild(selOption);
		}
//adds options to the select list.
    while (i < len) {
		selOption = document.createElement("option");
		selOption.setAttribute("value", pog['options'][i]['v']);
		selOption.innerHTML = pog['options'][i]['prompt'];
		selOption.setAttribute("id", pog['options'][i]['img']);	
		if(pog['options'][i]['p'])
			selOption.innerHTML += handlePogPrice(pog['options'][i]['p'],pog.flags);
		selectList.appendChild(selOption);
		i++;
       }
	
	$("div_"+pogid).appendChild(selectList);


//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		gHintQmark(pogid,pog['ghint']);


	imageDiv = document.createElement('div');
	with(imageDiv)	{
		id = "imgSelect_"+pogid+"_img";
		className = 'imageselect_image';
		innerHTML += "<img src='"+zoovyImageUrl('blank.gif',pog.width,pog.height,'FFFFFF')+"' alt='' border='0' height='"+pog.height+"' width='"+pog.width+"' name='selectImg_"+pogid+"' id='selectImg_"+pogid+"'>";
		}
	$("div_"+pogid).appendChild(imageDiv);	

	},

	
renderOptionRADIO: function(pog)	{
	var pogid = pog.id;
	
//display ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		gHintQmark(pogid,pog['ghint']);
	
	var radioInput; //used to create the radio button element.
	var radioLabel; //used to create the radio button label.
    var i = 0;
    var len = pog['options'].length;
	while (i < len) {
		$("div_"+pogid).innerHTML += "<div class='zform_radio_input'>";
	//creates the radio input and assigns attributes	  

	
	$("div_"+pogid).appendChild(createRadio(pogid,pog['options'][i]['v'])); //add radio button to dom.	
	
	
	
	
		radioLabel = document.createElement('label');
		with(radioLabel)	{
			className =  "zhint";
			setAttribute("for", "pog_id_"+pogid+"_value_"+pog['options'][i]['v']);
			setAttribute("title", (pog['options'][i]['html']) ? pog['options'][i]['html'] : pog['options'][i]['prompt']);
			}
		radioLabel.appendChild(document.createTextNode(pog['options'][i]['prompt']));  // puts the prompt between the label tags.

// puts the price, if set, after the prompt.
//the price gets passed as +5.00 or -5.00 but needs to be displayed at +$5.00 or -$5.00, hence then [0] and substr crap below.
		if(pog['options'][i]['p'])
			radioLabel.appendChild(document.createTextNode(handlePogPrice(pog['options'][i]['p'],pog.flags)));  
			
		
		$("div_"+pogid).appendChild(radioLabel); //add label to dom.	
		$("div_"+pogid).innerHTML += "<\/div>";
		i++
		}
		
	},






renderOptionCB: function(pog) {
	var pogid = pog.id;
	var cb = document.createElement('input');
	with(cb)	{
		setAttribute("type","checkbox");
		setAttribute("id", "pog_"+pogid);
		setAttribute("value", "ON");
		setAttribute("name", "pog_"+pogid);
		className =  "zform_checkbox";
		}
	$("div_"+pogid).appendChild(cb);
/*
Creates the 'hidden input' form field in the DOM which is used to let the cart know that the 
checkbox element was present and it's absense in the form post means it wasn't checked.	
*/
	var hidden = document.createElement("input");
	with(hidden) {
		setAttribute("id", "pog_"+pogid+"_cb");
		setAttribute("value", "1");
		setAttribute("name", "pog_"+pogid+"_cb");
		setAttribute("type", "hidden");
		}
	
	$("div_"+pogid).appendChild(hidden);
	},






renderOptionHIDDEN: function(pog) {
	var pogid = pog.id;

//hidden attributes don't need a label.
	$("pog_"+pogid+"_id").style.display = 'none';

//Creates the 'hidden input' form field in the DOM.	
	var textbox = document.createElement("input");
	with(textbox) {
		setAttribute("id", "pog_"+pogid);
//cant set the value to null in IE because it will literally write out 'undefined'. this statement should handle undefined, defined and blank just fine.
		if(pog['default'])
			defaultValue = (pog['default'] == "") ?  "" : pog['default'];
		else
			defaultValue = "";

		setAttribute("value",defaultValue);

		setAttribute("name", "pog_"+pogid);
		setAttribute("type", "hidden");
//can't set maxlength attribute if there is no value (browser treats blank as 0)
		if(pog['maxlength'])
			setAttribute("maxlength", pog['maxlength']);   
		}
		

//make input a new child of the div with the label. should this be a child of the label? I don't think so....
	$("div_"+pogid).appendChild(textbox);
	},







renderOptionATTRIBS: function(pog)	{
//attributes are used with finders. They don't do anything and they don't require a form element in the add to cart.. BUT we may want to do something merchant specific, so here it is.... to overide...
	$("div_"+pog.id).style.display = 'none';
	},




renderOptionTEXT: function(pog) {
	var pogid = pog.id;


//Creates the 'text input' form field in the DOM.	
	var textbox = document.createElement("input");
	with(textbox) {
		setAttribute("id", "pog_"+pogid);
//cant set the value to null in IE because it will literally write out 'undefined'. this statement should handle undefined, defined and blank just fine.
		if(pog['default'])
			defaultValue = (pog['default'] == "") ?  "" : pog['default'];
		else
			defaultValue = "";
		setAttribute("value",defaultValue);

		setAttribute("name", "pog_"+pogid);
		className =  "zform_textbox";
		setAttribute("type", "text");
		}
//can't set maxlength attribute if there is no value (browser treats blank as 0)
// maxlength doesn't work in IE... so there's a js function added to each onkeypress
	if(pog['maxlength'])	{
		textbox.maxlength = pog['maxlength'];
		textbox.onkeyup = function(){textCounter(this,pog['maxlength']);};
		textbox.onkeydown = function(){textCounter(this,pog['maxlength']);};
	}
	
//make input a new child of the div with the label. should this be a child of the label? I don't think so....
	$("div_"+pogid).appendChild(textbox);
	
//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		gHintQmark(pogid,pog['ghint']);
	},





renderOptionCALENDAR: function(pog) {

//load the calendar script, if it hasn't already been loaded.
	loadScript(graphics_url+'/calendarPopup-20090812.js','calendarScript');

	var pogid = pog.id;

	var pogid = pog.id;
//Creates the 'text input' form field in the DOM.	
	var textbox = document.createElement("input");
	with(textbox) {
		setAttribute("id", "pog_"+pogid);
//cant set the value to null in IE because it will literally write out 'undefined'. this statement should handle undefined, defined and blank just fine.
		if(pog['default'])
			defaultValue = (pog['default'] == "") ?  "" : pog['default'];
		else
			defaultValue = "";

		setAttribute("name", "pog_"+pogid);
		className =  "zform_textbox";
		setAttribute("type", "text");
		}

//can't set maxlength attribute if there is no value (browser treats blank as 0)
// maxlength doesn't work in IE... so there's a js function added to each onkeypress
	if(pog['maxlength'])	{
		textbox.maxlength = pog['maxlength'];
		textbox.onkeyup = function(){textCounter(this,pog['maxlength']);};
		textbox.onkeydown = function(){textCounter(this,pog['maxlength']);};
	}

//make input a new child of the div with the label. should this be a child of the label? I don't think so....
	$("div_"+pogid).appendChild(textbox);
	
	var calendarLink = document.createElement("div");
	with(calendarLink)	{
		style.display = 'inline';
		innerHTML = " <a href='#' name='pog"+pogid+"AnCh0R'  id='pog"+pogid+"AnCh0R' onclick=\"var pog"+pogid+" = new CalendarPopup(); pog"+pogid+".select($('pog_"+pogid+"'),'pog"+pogid+"AnCh0R','MM/dd/yyyy'); return false;\">Calendar</a>";
		}
		$("div_"+pogid).appendChild(calendarLink);

//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		gHintQmark(pogid,pog['ghint']);

//if the rush prompt is set, display it under the form.
	if(pog.rush_prompt)	{
		var rush_promptDiv = document.createElement("div");
		with(rush_promptDiv) {
			setAttribute("id",'rush_prompt_'+pogid);
			className = "zhint";
			}
		rush_promptDiv.innerHTML = pog['rush_prompt'];
		$("div_"+pogid).appendChild(rush_promptDiv);
		}
	
	},






renderOptionNUMBER: function(pog) {
	var pogid = pog.id;
//Creates the 'text input' form field in the DOM.	
	var textbox = document.createElement("input");
	with(textbox) {
		setAttribute("id", "pog_"+pogid);

//cant set the value to null in IE because it will literally write out 'undefined'. this statement should handle undefined, defined and blank just fine.
		if(pog['default'])
			defaultValue = (pog['default'] == "") ?  "" : pog['default'];
		else
			defaultValue = "";

 
		setAttribute("name", "pog_"+pogid);
		className = "zform_textbox";
		setAttribute("type", "text");
		}

//can't set maxlength attribute if there is no value (browser treats blank as 0)
// maxlength doesn't work in IE... so there's a js function added to each onkeypress
	if(pog['maxlength'])	{
		textbox.maxlength = pog['maxlength'];
		textbox.onkeyup = function(){textCounter(this,pog['maxlength']);};
		textbox.onkeydown = function(){textCounter(this,pog['maxlength']);};
	}	
//make input a new child of the div with the label. should this be a child of the label? I don't think so....
	$("div_"+pogid).appendChild(textbox);
	},





renderOptionTEXTAREA: function(pog) {
	var pogid = pog.id;


//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		gHintQmark(pogid,pog['ghint']);
		
	var textarea = document.createElement('textarea');
	with(textarea)	{
		setAttribute("id", "pog_"+pogid);
		setAttribute("name", "pog_"+pogid);
		className = "zform_textarea";
		setAttribute("cols",pog['cols']);
		setAttribute("rows",pog['rows']);
		style.display = 'block';
//		setAttribute("wrap","PHYSICAL");
//		setAttribute('ondblclick',foo);
		}
	$("div_"+pogid).appendChild(textarea);

		
	},





renderOptionREADONLY: function(pog) {
	var pogid = pog.id;
	$("div_"+pogid).innerHTML += "<span class='zsmall'>"+pog['default']+"<\/span>";
	},





renderOptionIMGGRID: function(pog)	{
	var pogid = pog.id;
	
//display ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		gHintQmark(pogid,pog['ghint']);
			
	var pogcols = pog.cols;  //number of columns. user defined, defaults to 8 in json.
	myTable = document.createElement("table");
	with(myTable)	{
		setAttribute("id","imggrid_table_"+pogid);
//		className = "ztable_row_head";
		}
	myTableBody = document.createElement("tbody");
	myTableBody.setAttribute("id","imggrid_tbody_"+pogid);
	myTable.appendChild(myTableBody);
	
// Need to know how many rows are present for the first 'for' loop, which creates the rows.
// if there are more columns alloted than options, default to 1.
    var totalRows = (pog['options']['length'] < pogcols) ? 1: pog.options.length / pogcols;

// Need to know how many total columns are present for the second 'for' loop, which creates each td (with image, label, radio, etc).
	var totalCols = (pog['options']['length'] < pogcols) ? pog.options.length : pogcols;

// Can't use i to increment becuase it makes everything go whacky. 
// This is used to increment the pog through the loop below so we can access the individual pog data.
	var inc = 0;  

	var radioInput; //used to create the radio button element.
	var radioLabel; //used to create the radio button label.

//	alert(" pog id = "+pogid+"\n pogcols = "+pogcols+"\n totalRows "+totalRows+"\n total columns = "+totalCols+"\n number of pogs = "+pog['options']['length']);

	
for (r=0; r<totalRows; r++)  {  // controls the number of rows that will appear.
	oRow = myTableBody.insertRow(-1); //adds a row to the table.
	
	for (c=0; c<totalCols; c++)	{  			// ##################      Set 3 to the number of columns.

// safety catch for rows that don't populate all columns.
		if(pog.options[inc])	{

oCell = oRow.insertCell(-1);  
oCell.setAttribute("id","imggrid_row"+r+"_col"+c+"_"+pogid);
oCell.className = "ztable_row";
oCell.innerHTML = "<div><label for='pog_id_"+pogid+"_value_"+pog.options[inc].v+"'><img src='"+zoovyImageUrl(pog.options[inc].img,pog.width,pog.height,'FFFFFF')+"' alt='' border='0' height='"+pog.height+"' width='"+pog.width+"'><\/label><\/div>";




oCell.appendChild(createRadio(pogid,pog.options[inc].v));  //adds the radio button into the DOM
//Creates the radio label and assigns necessary attributes.
radioLabel = document.createElement('label');
with(radioLabel)	{
	className =  "zhint";
	setAttribute("for", "pog_id_"+pogid+"_value_"+pog.options[inc].v);
	}
radioLabel.appendChild(document.createTextNode(pog.options[inc].prompt));  // puts the prompt between the label tags.
oCell.appendChild(radioLabel);  //puts the label tag into the table.

			} //ends safety catch.		
		inc++;  //pog inc is still incremented outside the catch so we don't get stuck in an infinite loop.
		}
	}

	$("div_"+pogid).appendChild(myTable); //add table to dom.
	},





renderOptionUNKNOWN: function(pog) {
	return("UNKNOWN "+pog.type+": "+pog.prompt+" / "+pog.id);
	},




renderOption: function(pog) {
	var pogid = pog.id;
//add a div to the dom that surrounds the pog
	var formFieldDiv = document.createElement("div");
	with(formFieldDiv) {
		setAttribute("id",'div_'+pogid);
		className = "zform_div";
		}

//create the label (prompt) for the form input and make it a child of the newly created div.
	formFieldLabel = document.createElement('label');
	with(formFieldLabel)	{
		setAttribute("for", "pog_"+pogid);
		setAttribute("id", "pog_"+pogid+"_id");
		setAttribute("style", "vertical-align:top;");
		
//if ghint is set, use that as the title attribute, otherwise use the prompt.
		(pog.ghint) ? setAttribute("title",pog.ghint) : setAttribute("title",pog.prompt);
			
		}
	formFieldLabel.appendChild(document.createTextNode(pog.prompt+": "));
	formFieldDiv.appendChild(formFieldLabel);

//Push the new div into a div with id JSONPogDisplay as a new child.
// note - originally, i pushed this onto the add to cart form, but that wasn't very flexible in terms of location.
	$("JSONPogDisplay").appendChild(formFieldDiv);   /// NOTE the form ID on this should probably be auto-generated from the element ID.
 
    if (this.handlers["pogid."+pogid]) {
      return(eval("this."+this.handlers["pogid."+pogid]+"(pog)"));
      }
    else if (this.handlers["type."+pog.type]) {
      return(eval("this."+this.handlers["type."+pog.type]+"(pog)"));
      }
    else {
      return(eval("this."+this.handlers["unknown."]+"(pog)"));
      }

  }});
 




