//Zoovy javaScript version. 
//case oddness is present to increase likelyhood of this being a unique var id.
ZjSv = 1;

//here for testing.
//var image_url = 'http://static.zoovy.com/v1/img/sporks/';


//will generate a image url and or tag/url.
//tag is boolean. set to 1 to generate the img src tag in addition to just the image url.
function imglib(USERNAME,IMGNAME,H,W,BG,EXT,TAG) {

//image_url should be set to %IMAGE_URL% in the theme to be more CDN friendly. 
	if (typeof image_url == 'undefined') {
		image_url = '//static.zoovy.com/img/' + USERNAME + '/';
		}

	if (W == '') { W = '0'; }
	if (H == '') { H = '0'; }
	if (BG == '') { H = 'FFFFFF'; }
	if (TAG == '')	{TAG = 0;}

	var r = image_url + "W" + W + "-H" + H + "-B" + BG + "/" + IMGNAME;

	if (EXT != '') {
		r = r + "." + EXT;
		}
	if(TAG == 1)	{
		r = "<img src='"+r+"' width='"+W+"' height='"+H+"' border='0' alt='' />";  //add http: to src if testing locally.
		}

	return(r);

	}




// takes a string e.g. k1=v1&k2=v2&k3=v3 and returns an associative array
function kvTxtToArray(txt) {
	var r = new Array();

	if (txt.charAt(0) == '?') {
		txt = txt.substring(1);	 // strip off the ?
		}

	for(var i=0; i < txt.split("&").length; i++) {
		var kvpair = txt.split("&")[i];	
		r[ unescape(kvpair.split("=")[0]) ] = unescape(kvpair.split("=")[1]);
		}

	// use the line below to test if its working!
	// for(var i in params) { alert(i + ' : ' + params[ i ]); }

	return(r);

	}



// do we still need these? escape() is a function. see cookie functions for example

function esc(str) {
	// note: eventually we need to make a better escape
	return(encodeURIComponent(str));
	}


function unesc(str) {
	return(decodeURIComponent(str));
	}



//toggle the display of an element by ID. Done without AJAX.
//the display state is returned so that additional actions can occur, if needed, without another lookup.
function toggle(ID)	{
	d = document.getElementById(ID).style.display;  //get current display value
	if(d == 'block') {d='none'}
	else {d = 'block'} //default to display mode. safer this way.
	return d;
	}






function openWindow(url,w,h) {
	if(w == ''){w = '600'}
	if(h == ''){h = '450'}
	adviceWin = window.open(url,'advice','status=no,width='+w+',height='+h+',menubar=no,scrollbars=yes');
	adviceWin.focus(true);
	}


//used for image enlargement (largely replaced by MagicToolBox 
function zoom (imageurl) {
	z = window.open('','zoom_popUp','status=0,directories=0,toolbar=0,menubar=0,resizable=1,scrollbars=1,location=0');
	z.document.write('<html>\n<head>\n<title>Picture Zoom<\/title>\n<\/head>\n<body>\n<div align="center">\n<img src="' + imageurl + '" /><br />\n<form><input type="button" value="Close Window" onClick="self.close(true)" /><\/form>\n<\/div>\n<\/body>\n<\/html>\n');
	z.document.close();
	z.focus(true);
	}





// ######################## FORM functions



//get selected radio button object.
function getRadioCheckedObj(radio_name,form_name)	{
	var oRadio = document.forms[form_name].elements[radio_name];
	for(var i = 0, m = oRadio.length; i < m; i++)	{
		if(oRadio[i].checked)	{
			return oRadio[i];  //return form object. having the return here also ends the loop.
			}
		}
	return null;
	}

//pass in the id of a select list or (this) to have the selected index object returned.
function getSelectedIndexObj(selectID)	{
	var selObj = '';
	if(typeof selectID == 'object')	{
		selObj = selectID;
		}
	else
		selObj = document.getElementById(selectID);
		
	var selIndex = selObj.selectedIndex;
	var r = selObj.options[selIndex];
//	alert(r.id);
	return r;
	}



//set for onFocus and onBlur of a pre-populated text input.  
//Will hide default text on focus and will reset value on blur if the field is blank. pass (this) into function.
function handleTextInput(fieldObject)	{
//reset to default value if field is blank. should get here onBlur if no new value is set.
	if(fieldObject.value == '')
		fieldObject.value = fieldObject.defaultValue;

//blank out field if the default value is set. should get here on ititial Focus
	else if (fieldObject.defaultValue == fieldObject.value)
		fieldObject.value = "";
	
	else{} // catch all
	}


//make sure the value of a field is a valid email address
function validateEmail(str) {

		var at="@"
		var dot="."
		var lat=str.indexOf(at)
		var lstr=str.length
		var ldot=str.indexOf(dot)
		if (str.indexOf(at)==-1){
			return false
			}

		if (str.indexOf(at)==-1 || str.indexOf(at)==0 || str.indexOf(at)==lstr){
			return false
			}

		if (str.indexOf(dot)==-1 || str.indexOf(dot)==0 || str.indexOf(dot)==lstr){
			return false
			}

		 if (str.indexOf(at,(lat+1))!=-1){
			return false
			}

		 if (str.substring(lat-1,lat)==dot || str.substring(lat+1,lat+2)==dot){
			return false
			}

		 if (str.indexOf(dot,(lat+2))==-1){
			return false
			}
		
		 if (str.indexOf(" ")!=-1){
			return false
			}

	return true					

	}



//   ######################## COOKIE functions
// http://w3schools.com/js/js_cookies.asp


function setCookie(c_name,value,expiredays)	{
	var exdate=new Date();
	exdate.setDate(exdate.getDate()+expiredays);
	document.cookie=c_name+ "=" +escape(value)+((expiredays==null) ? "" : ";expires="+exdate.toUTCString());
	}

function getCookie(c_name){
	if (document.cookie.length>0)	{
		c_start=document.cookie.indexOf(c_name + "=");
		if (c_start!=-1)	{
			c_start=c_start + c_name.length+1;
			c_end=document.cookie.indexOf(";",c_start);
			if (c_end==-1)
				c_end=document.cookie.length;
			return unescape(document.cookie.substring(c_start,c_end));
			}
		}
	return "";
	}


function eraseCookie(name)	{
	createCookie(name, "", -1);
	}



//  #################  AJAX functions


//
// purpose: receives one or more response commands from Zoovy servers and attempts
//			to execute them.
//		##### NOTE - currently still set up for prototype. Needs to be modified for jquery.
function handleResponse(txt) {

   if (txt == '') {
      // empty response, must have been a set only
      }
   else if (txt.indexOf('?') == 0) {
      // NOTE: multiple ? can be returned.
      // ?k1=v1 (NOT XML)
      var txtLines = new Array();
      txtLines = txt.split('?');    // split the txt into lines (separated by ?)
      for (var i = 0;i<txtLines.length;i++) {

			while ((txtLines[i].substring(0,1) == "\n") || (txtLines[i].substring(0,1) == "\r")) { 
				// strip trailing CR/LF's
				txtLines[i] = txtLines[i].substring(1); 
				}

			// alert('txtLine: '+txtLines[i]);

         var params = kvTxtToArray('?' + txtLines[i]);

         // alert('i['+i+']='+txtLines[i]);
         if (txtLines[i] == '') {}  // blank line (probably the first record)
         else if (params['m'] == 'pong') {
				// 
            alert('PONG FROM SERVER: '+params['t']);
            }
         else if ((params['m'] == 'updateDiv') || (params['m'] == 'loadcontent')) {
				// requires parameters:
				//		div=[the div to be updated]
				//		html=[the content to be put in the div]
            var thisDiv = $( params['div'] );
            thisDiv.innerHTML = params['html'];
				if (params['html'] == '') {
					// IE screws this up, it leaves a blank space if we don't do this.
					var txt = thisDiv.outerHTML;
					thisDiv.replace( txt );
					// alert(txt);
					}
            }
			else if (params['m'] == 'setFocus') {

				if ($(params['id'])) {
					$(params['id']).focus();
					}
				else {
					alert("Could not set focus on: "+params['id']);
					}
				}
			else if (params['m'] == 'loadselect') {
				// to set options pass: c=count#&s=selectedid&t0=text0&v0=value0&t1=text1&v1=value1
				var theSel = $(params['id']);
				theSel.options.length = 0; // removes all options.
				var i=0;
				while (params['t'+i] != undefined) {
					theSel.options[i] = new Option(params['t'+i],params['v'+i]);
					i++;
					}
				}
			else if (params['m'] == 'updateProduct') {
				// check for the existance of an "updateProduct" function
				// execute that, passing the key/value pairs returned (params)
				}
			else if (params['m'] == 'updateCart') {
				updateCart();
				}
         else {
            // unknown request handler!
            alert('unknown response: ['+txtLines[i]+']');
            }
         // end of each line.
         }
      }
   else {
      alert('unknown data format sent to handleResponse: '+txt);
      }
   }


