//
// copyright zoovy, 2004
//
function imglib(USERNAME,imgname,height,width,bgcolor,ssl,ext) {

	if (width == '') { width = '0'; }
	if (height == '') { height = '0'; }
	if (bgcolor == '') { height = 'FFFFFF'; }

	var result = "http://static.zoovy.com/img/" + USERNAME + "/W" + width + "-H" + height + "-B" + bgcolor + "/" + imgname;
	if (ext != '') {
		result = result + "." + ext;
		}
	return(result);	
	}



//
// takes a string e.g. k1=v1&k2=v2&k3=v3 and returns an associative array
function kvTxtToArray(txt) {
	var params = new Array();

	if (txt.charAt(0) == '?') {
		txt = txt.substring(1);	 // strip off the ?
		}
	for(var i=0; i < txt.split("&").length; i++) {
		var kvpair = txt.split("&")[i];	
		params[ unescape(kvpair.split("=")[0]) ] = unescape(kvpair.split("=")[1]);
		// params[ unesc(kvpair.split("=")[0]) ] = unesc(kvpair.split("=")[1]);
		}

	// use the line below to test if its working!
	// for(var i in params) { alert(i + ' : ' + params[ i ]); }
	return(params);
	}

// 
function esc(str) {
	// note: eventually we need to make a better escape
	return(encodeURIComponent(str));
	}

function unesc(str) {
	return(decodeURIComponent(str));
	}


// NOTE: this doesn't work!
function kvArrayToTxt(qq) {
	var txt = '';
	var k = '';
	alert('length: '+qq.length);
	for ( k in qq ) {
		alert(k.valueOf);
		if (k != '') {
			alert('KEY: '+k);
			txt = txt + esc(k)+"="+esc( qq[k] )+'&';
			}
		}
	alert(txt);
	return(txt);
	}


//
// purpose: receives one or more response commands from Zoovy servers and attempts
//			to execute them.
//		
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


// checks to see if a specific value is an an array.
Array.prototype.inArray = function (value) {
	var i;
	for (i=0; i < this.length; i++) {
		if (this[i] === value) {
			return true;
		}
	}
	return false;
};

// removes a specific value from an array (useful for keeping state)
Array.prototype.popValue = function (value) {
	var i;
	for (i=0; i < this.length; i++) {
		if (this[i] === value) {
			this.splice(i,1); i--;
		}
	}
};

function getRadioValue(r) {
	var result = undefined;
	for (var i=0; i < r.length; i++) {
   	if (r[i].checked) { result = r[i].value; }
	   }
	return(result);
	}
