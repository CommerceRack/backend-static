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
This is somewhat legacy stuff here, adopted to work within the new framework.
it is not an extension for this reason.
at some point in the future, it should to be.
*/

handlePogs = function(v,o) {
	this.initialize(v,o);
	}


$.extend(handlePogs.prototype, {
// object variables
//	pogsJSON : handlePogs, //not sure what this is. appears we may not need it.

initialize: function(pogs,o) {
	this.pogs = pogs;
	this.invCheck = o.invCheck ? o.invCheck : false; //set to true and a simple inventory check occurs on add to cart.
	this.imgClassName = o.imgClassName ? o.imgClassName : 'sogImage'; //allows a css class to be set on images (for things like magicZoom)
	this.sku = o.sku; //
//	myControl.util.dump('inventory check = '+this.invCheck+' and className = '+this.imgClassName);

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

addHandler: function(key,value,f) {
// adds a new entry to the this.handlers e.g.: this.handlers.renderOptionTEXT
	this.handlers[ key+"." + value ] = f;
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

////////////////////////////      DEFAULT HANDLERS       \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

//upgraded to jquery.
renderOptionSELECT: function(pog,safeid) {
//	myControl.util.dump('BEGIN renderOptionSELECT for pog '+pog.id+' and safe id = '+safeid);
	var pogid = pog.id;
	var $selectList = $("<select>").attr({"id":"pog_"+safeid,"name":"pog_"+pogid}).addClass('zform_select');
    var i = 0;
    var len = pog.options.length;

	var selOption; //used to hold each option added to the select
	var optionTxt;

//if the option is 'optional' AND has more than one option, add blank prompt. If required, add a please choose prompt first.
	if(len > 0)	{
		optionTxt = (pog['optional'] == 1) ?  "" :  "Please choose (required)";
		selOption = "<option value='' disable='disabled' selected='selected'>"+optionTxt+"<\/option>";
		$selectList.append(selOption);
		}
//adds options to the select list.
    while (i < len) {
		optionTxt = pog['options'][i]['prompt'];
		if(pog['options'][i]['p'])
			optionTxt += pogs.handlePogPrice(pog['options'][i]['p']); //' '+pog['options'][i]['p'][0]+'$'+pog['options'][i]['p'].substr(1);
		selOption = "<option value='"+pog['options'][i]['v']+"' id='option_"+pogid+""+pog['options'][i]['v']+"'>"+optionTxt+"<\/option>";
		$selectList.append(selOption);
		i++;
		}

	$selectList.appendTo($("#div_"+safeid));

//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);

//	myControl.util.dump('END renderOptionSELECT for pog '+pog.id);

	},


/*
//better for non-pad devices
renderOptionBIGLIST: function(pog,safeid) {

	var pogid = pog.id;
	var selOptions;
	var optGrp, lastOptGrp;
	var inc = 0;
    var len = pog.options.length;
	var $focusOptGrp;
// this select list isn't used for the pog value. it's here purely for usability. it contains the 'first' set of choices.
	var $selectListSkip = $("<select \/>").attr({"id":"pog_"+safeid+"skip","name":"pog_"+pogid+"skip"}).addClass("zform_select zform_biglist zform_biglist1").bind('change',function(){
		var sogsafeid = this.id.replace('skip','');
		var sogValue = this.value
			$('#'+sogsafeid).children().each(function(e,i) {
//				myControl.util.dump(sogValue);								  
				$focusOption = $(this).addClass('displayNone');
//				myControl.util.dump($focusOption.attr('data-parent'));
				if($focusOption.attr('data-parent') == sogValue){$focusOption.removeClass('displayNone')}
				});
			$('#'+sogsafeid).val('');
			});
	
	var $selectList = $("<select \/>").attr({"id":"pog_"+safeid,"name":"pog_"+pogid}).addClass("zform_select zform_biglist zform_biglist2");
//sets the first options on both select lists.
	$selectListSkip.append("<option value='' disable='disabled' selected='selected'>Please Choose...<\/option>");
	$selectList.append("<option value='' disable='disabled' selected='selected'><\/option>");

	//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);

//create first optgroup and set supporting vars.
//These are here instead of in the while loop to save a lookup during each iteration. Otherwise we need to 
//check if at iteration 1 (inc = 0) each time in the loop. this is gives us a tighter loop.

	selValues = pog['options'][inc]['prompt'].split('|');
	$selectListSkip.append("<option value='"+pog['options'][inc]['v']+"'>"+selValues[0]+"<\/option>");
	lastOptGrp = selValues[0];



	while (inc < len) {

//selValues[0] = first dropdown prompt/opt group.
//selValues[1] = second dropdown prompt.
		selValues = pog['options'][inc]['prompt'].split('|');
		optGrp = selValues[0];

//at each 'change' of grouping, add the current group to the select list.
		if(optGrp != lastOptGrp)	{
			$selectListSkip.append("<option value='"+selValues[0]+"'>"+selValues[0]+"<\/option>"); //add option to first dropdown list.
			}
		
		selOptions += "<option value='"+pog['options'][inc]['v']+"' data-parent='"+selValues[0]+"' class='displayNone'>"+selValues[1]+"<\/option>\n";
		lastOptGrp = selValues[0]
		inc += 1;
		}

	$selectList.append(selOptions); //append last group.
	$("#div_"+safeid).append($selectListSkip).append($selectList);
	
	}, //renderOptionBIGLIST
*/
renderOptionBIGLIST: function(pog,safeid) {

	var pogid = pog.id;
	var selOptions;
	var lastOptGrp;
	var inc = 0;
    var len = pog.options.length;
	
	var $selectList = $("<select \/>").attr({"id":"pog_"+safeid,"name":"pog_"+pogid}).addClass("zform_select zform_biglist");
//sets the first options on both select lists.
	$selectList.append("<option value='' disable='disabled' selected='selected'>Please Choose...<\/option>");

	//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);

/*
create first optgroup.
These are here instead of in the while loop to save a lookup during each iteration. Otherwise we need to 
check if at iteration 1 (inc = 0) each time in the loop. this is gives us a tighter loop.
*/
	selValues = pog['options'][inc]['prompt'].split('|');
	lastOptGrp = selValues[0];
	selOptions += "<optgroup label='"+selValues[0]+"'>"; //add option to first dropdown list.
	while (inc < len) {

//selValues[0] = first dropdown prompt/opt group.
//selValues[1] = second dropdown prompt.
		selValues = pog['options'][inc]['prompt'].split('|');
		optGrp = selValues[0];

//at each 'change' of grouping, add the current group to the select list.
		if(optGrp != lastOptGrp)	{
			selOptions += "<\/optgroup><optgroup label='"+selValues[0]+"'>"; //add option to first dropdown list.
			}
		
		selOptions += "<option value='"+pog['options'][inc]['v']+"'>"+selValues[1]+"<\/option>\n";
		lastOptGrp = selValues[0]
		inc += 1;
		}
	selOptions += "<\/optgroup>";
	$selectList.append(selOptions); //append last group.
	$("#div_"+safeid).append($selectList);
	
	}, //renderOptionBIGLIST



//upgraded to jquery.
renderOptionIMGSELECT: function(pog,safeid) {
//	myControl.util.dump('BEGIN renderOptionIMGSELECT for pog '+pog.id);
	var pogid = pog.id;
	var $parentDiv = $("#div_"+safeid);
	var $selectList = $("<select>").attr({"id":"pog_"+safeid,"name":"pog_"+pogid}).addClass('zform_select').bind('change', function(e){
		var thumbnail = $("#pog_"+safeid+" option:selected").attr('data-thumbnail');
		$("#selectImg_"+safeid).attr('src',myControl.util.makeImage({"w":pog.width,"h":pog.height,"name":thumbnail,"b":"FFFFFF","tag":false,"lib":myControl.username,"id":"selectImg_"+safeid}));
		});
    var i = 0;
    var len = pog.options.length;

	var selOption; //used to hold each option added to the select
	var optionTxt;

//if the option is 'optional' AND has more than one option, add blank prompt. If required, add a please choose prompt first.
	if(len > 0)	{
		optionTxt = (pog['optional'] == 1) ?  "" :  "Please choose (required)";
		selOption = "<option value='' disabled='disabled' selected='selected'>"+optionTxt+"<\/option>";
		$selectList.append(selOption);
		}
//adds options to the select list.
    while (i < len) {
		optionTxt = pog['options'][i]['prompt'];
		if(pog['options'][i]['p'])
			optionTxt += pogs.handlePogPrice(pog['options'][i]['p']); //' '+pog['options'][i]['p'][0]+'$'+pog['options'][i]['p'].substr(1);
		selOption = "<option value='"+pog['options'][i]['v']+"' data-thumbnail='"+pog['options'][i]['img']+"' id='option_"+pogid+""+pog['options'][i]['v']+"'>"+optionTxt+"<\/option>";
		$selectList.append(selOption);
		i++;
		}

	$selectList.appendTo($parentDiv);

//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);

	$imageDiv = $('<div>').attr({"id":"imgSelect_"+safeid+"_img"}).addClass('imageselect_image');
	$imageDiv.html(myControl.util.makeImage({"w":pog.width,"h":pog.height,"name":"blank.gif","b":"FFFFFF","tag":true,"lib":myControl.username,"id":"selectImg_"+pogid}));
	$imageDiv.appendTo($parentDiv);

	myControl.util.dump('END renderOptionIMGSELECT for pog '+pog.id);
	},

//upgraded to jquery. needs css love.
renderOptionRADIO: function(pog,safeid)	{
	var pogid = pog.id;

	var $parentDiv = $('#div_'+safeid);
	
//display ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);
	
	var $radioInput; //used to create the radio button element.
	var radioLabel; //used to create the radio button label.
    var i = 0;
    var len = pog['options'].length;
	while (i < len) {
		radioLabel = "<label for='pog_id_"+safeid+"_value_"+pog['options'][i]['v']+"'>"+pog['options'][i]['prompt']+"<\/label>";
		$radioInput = $('<input>').attr({type: "radio", name: "pog_"+pogid, value: pog['options'][i]['v'], id: "pog_id_"+safeid+"_value_"+pog['options'][i]['v']});
		$parentDiv.append($radioInput).append(radioLabel);
		i++
		}
	},


//upgraded to jquery.
renderOptionCB: function(pog,safeid) {
	var pogid = pog.id;
	var $parentDiv = $('#div_'+safeid);
	var $checkbox = $('<input>').attr({type: "checkbox", name: "pog_"+pogid, value: 'ON', id: "pog_"+safeid});
//Creates the 'hidden input' form field in the DOM which is used to let the cart know that the checkbox element was present and it's absense in the form post means it wasn't checked.		
	var $hidden = $('<input>').attr({type: "hidden", name: "pog_"+pogid+"_cb", value: '1', id: "pog_"+safeid});
	$parentDiv.append($checkbox).append($hidden);
//display ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);
	},



//upgraded to jquery.
renderOptionHIDDEN: function(pog,safeid) {
	var pogid = pog.id;
//hidden attributes don't need a label.
	document.getElementById("pog_"+safeid+"_id").style.display = 'none';
//cant set the value to null in IE because it will literally write out 'undefined'. this statement should handle undefined, defined and blank just fine.
	var defaultValue = myControl.util.isSet(pog['default']) ?  pog['default'] : "";
	var $parentDiv = $('#div_'+safeid);
//Creates the 'hidden input' form field in the DOM which is used to let the cart know that the checkbox element was present and it's absense in the form post means it wasn't checked.		
	var $hidden = $('<input>').attr({type: "hidden", name: "pog_"+pogid, value: defaultValue, id: "pog_"+safeid});
	$parentDiv.append($hidden);
	},


//upgraded to jquery.
renderOptionATTRIBS: function(pog,safeid)	{
//attributes are used with finders. They don't do anything and they don't require a form element in the add to cart.. BUT we may want to do something merchant specific, so here it is.... to overide...
	document.getElementById("div_"+safeid).style.display = 'none';
	},



//upgraded to jquery.
renderOptionTEXT: function(pog,safeid) {
	var pogid = pog.id;
//cant set the value to null in IE because it will literally write out 'undefined'. this statement should handle undefined, defined and blank just fine.
	var defaultValue = myControl.util.isSet(pog['default']) ?  pog['default'] : "";
	var $parentDiv = $('#div_'+safeid);
//Creates the 'hidden input' form field in the DOM which is used to let the cart know that the checkbox element was present and it's absense in the form post means it wasn't checked.		
	var $textbox = $('<input>').attr({type: "text", name: "pog_"+pogid, value: defaultValue, id: "pog_"+safeid}).addClass('zform_textbox')
	if(pog['maxlength'])	{
		$textbox.keyup(function(){
			if (this.value.length > (pog['maxlength'] - 1)) // if too long...trim it!
		        this.value = this.value.substring(0, pog['maxlength']);
			});
		}
	$parentDiv.append($textbox);
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);
	},




//upgraded to jquery.
renderOptionCALENDAR: function(pog,safeid) {
	var pogid = pog.id;
	
	var defaultValue = myControl.util.isSet(pog['default']) ?  pog['default'] : "";
	
	var $parentDiv = $('#div_'+safeid);
	var $textbox = $('<input>').attr({type: "text", name: "pog_"+pogid, value: defaultValue, id: "pog_"+safeid}).addClass('zform_textbox').datepicker({altFormat: "DD, d MM, yy"});
	$parentDiv.append($textbox);

//output ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);

//if the rush prompt is set, display it under the form.
	if(pog.rush_prompt)	{
		$parentDiv.append("<div class='zhint' id='rush_prompt_"+safeid+">"+pog['rush_prompt']+"<\/div>");
		}
	},






renderOptionNUMBER: function(pog,safeid) {
	var pogid = pog.id;
//cant set the value to null in IE because it will literally write out 'undefined'. this statement should handle undefined, defined and blank just fine.
	var defaultValue = myControl.util.isSet(pog['default']) ?  pog['default'] : "";
	var $parentDiv = $('#div_'+safeid);
//right now, 'number' isn't widely supported, so a JS regex is added to strip non numeric characters
	var $textbox = $('<input>').attr({type: "number", name: "pog_"+pogid, value: defaultValue, id: "pog_"+safeid}).addClass('zform_textbox').keyup(function(){
		this.value = this.value.replace(/[^0-9]/g, '');
		});

	if(pog['max'])
		$textbox.attr('max',pog['max']);
	if(pog['min'])
		$textbox.attr('max',pog['max']);
		
	$parentDiv.append($textbox);
	
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);
	},





renderOptionTEXTAREA: function(pog,safeid) {
	var pogid = pog.id;
//cant set the value to null in IE because it will literally write out 'undefined'. this statement should handle undefined, defined and blank just fine.
	var defaultValue = myControl.util.isSet(pog['default']) ?  pog['default'] : "";
	var $parentDiv = $('#div_'+safeid);
//Creates the 'hidden input' form field in the DOM which is used to let the cart know that the checkbox element was present and it's absense in the form post means it wasn't checked.		
	var $textbox = $('<textarea>').attr({name: "pog_"+pogid, value: defaultValue, id: "pog_"+safeid}).addClass('zform_textarea');
	$parentDiv.append($textbox);
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);
		
	},




//needs testing.
renderOptionREADONLY: function(pog,safeid) {
	
	document.getElementById("div_"+safeid).innerHTML += "<span class='zsmall'>"+pog['default']+"<\/span>";
	},



//create an override for IMGGRID to be used for webapp. no radio button, just thumbnails that, on click, will set a hidden input. !!!!!!!!!!!!!
//also explore frameworks (jqueryui or jquerymobile ?) for better handling of form display.

renderOptionIMGGRID: function(pog,safeid)	{

	var pogid = pog.id;

	var $parentDiv = $('#div_'+safeid);
	
//display ? with hint in hidden div IF ghint is set
	if(pog['ghint'])
		pogs.showHintIcon(pogid,pog['ghint']);
	
	var $radioInput; //used to create the radio button element.
	var radioLabel; //used to create the radio button label.
	var thumbnail; //guess what this holds
    var i = 0;
    var len = pog['options'].length;
	while (i < len) {
		thumbnail = myControl.util.makeImage({"w":pog.width,"h":pog.height,"name":pog['options'][i]['img'],"b":"FFFFFF","tag":true,"lib":myControl.username,"id":"selectImg_"+safeid});
		radioLabel = "<label for='pog_id_"+safeid+"_value_"+pog['options'][i]['v']+"'>"+pog['options'][i]['prompt']+"<\/label>";
		$radioInput = $('<input>').attr({type: "radio", name: "pog_"+pogid, value: pog['options'][i]['v'], id: "pog_id_"+safeid+"_value_"+pog['options'][i]['v']});
		$parentDiv.append(thumbnail).append($radioInput).append(radioLabel).wrap("<div class='floatLeft'><\/div>");;
		i++
		}


	},


renderOptionUNKNOWN: function(pog,safeid) {
	return("UNKNOWN "+pog.type+": "+pog.prompt+" / "+pog.id);
	},


showHintIcon : function(pogid,pogHint)	{
	$("#div_"+pogid).append("<span class='ghint_qmark_container'><a href='#' onclick='$(\"#ghint_"+pogid+"\").toggle(); return false;' class='ghint_qmark'>?<\/a></span>");
	$("#div_"+pogid).append("<div style='display:none;' class='zhint' id='ghint_"+pogid+"'>"+pogHint+"</div>");
	},






//there's a lot of logic with how price should be displayed.  This is a dumbed down version.
//myControl.util.formatMoney is not used here because the text is formatted by the merchant (we leave it alone).
 handlePogPrice : function(P)	{
	var price;
//Puts the + sign, if present, in the correct spot
	if(P.charAt(0) == '+')	{
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
	},




renderOption: function(pog,pid) {
	var pogid = pog.id;
	var safeid = myControl.util.makeSafeHTMLId(pogid); //pogs have # signs, which must be stripped to be jquery friendly.
//add a div to the dom that surrounds the pog
	var $formFieldDiv = $("<div>").attr("id","div_"+safeid).addClass("zform_div");

//if ghint is set, use that as the title attribute, otherwise use the prompt.
	var labelTitle = (pog.ghint) ? pog.ghint : pog.prompt;


//create the label (prompt) for the form input and make it a child of the newly created div.
	var $formFieldLabel = $('<label>').attr({"for":"pog_"+safeid,"id":"pog_"+safeid+"_id","title":labelTitle}).text(pog.prompt);

	$formFieldDiv.append($formFieldLabel);
	
//Push the new div into a div with id JSONPogDisplay as a new child.
// note - originally, i pushed this onto the add to cart form, but that wasn't very flexible in terms of location.
	var $displayObject = $("#JSONPogDisplay_"+pid);
	$displayObject.append($formFieldDiv);   /// NOTE the form ID on this should probably be auto-generated from the element ID.

    if (this.handlers["pogid."+pogid]) {
      return(eval("this."+this.handlers["pogid."+pogid]+"(pog,safeid)"));
      }
    else if (this.handlers["type."+pog.type]) {
      return(eval("this."+this.handlers["type."+pog.type]+"(pog,safeid)"));
      }
    else {
      return(eval("this."+this.handlers["unknown."]+"(pog,safeid)"));
      }
  }

	});









