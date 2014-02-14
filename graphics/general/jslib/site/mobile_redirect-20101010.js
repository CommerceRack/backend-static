//mobile device detection script.
// help can be found here:
// http://www.hand-interactive.com/resources/detect-mobile-javascript.htm

//Initialize our user agent string to lower case.
var uagent = navigator.userAgent.toLowerCase();


// Detects if the current device is an iPhone.
// note - this script must be run in the detectdevice function prior to the iphone script because
// the useragent string also contains iphone.

function DetectIpad()	{
   if (uagent.search("ipad") > -1)
      return true;
   else
      return false;
	}


// Detects if the current device is an iPhone.
function DetectIphone()	{
   if (uagent.search("iphone") > -1)
      return true;
   else
      return false;
	}


// Detects if the current device is an iPod Touch.
function DetectIpod()	{
   if (uagent.search("ipod") > -1)
      return true;
   else
      return false;
	}


// Detects if the current device is an Android OS-based device.
function DetectAndroid()	{
   if (uagent.search("android") > -1)
      return true;
   else
      return false;
	}


// Detects if the current browser is the S60 Open Source Browser.
// Screen out older devices and the old WML browser.
function DetectS60OssBrowser()	{
   if (uagent.search("webkit") > -1)
   {
     if ((uagent.search("series60") > -1 || 
          uagent.search("symbian") > -1))
        return true;
     else
        return false;
   }
   else
      return false;
	}


// Detects if the current browser is a Windows Mobile device.
function DetectWindowsMobile()	{
   if (uagent.search("windows ce") > -1)
      return true;
   else
      return false;
	}




// Detects if the current browser is a BlackBerry of some sort.
function DetectBlackBerry()	{
   if (uagent.search("blackberry") > -1)
      return true;
   else
      return false;
	}


// Detects if the current browser is on a PalmOS device.
function DetectPalmOS()	{
   if (uagent.search("palm") > -1)
      return true;
   else
      return false;
	}



// Detects device and redirects accordingly.
function mobileDetectDevice()	{
	if (DetectIpad())
		return true;
	else if (DetectIphone())
		return true;
	else if (DetectIpod())
		return true;
	else if(DetectS60OssBrowser())
		return true;
	else if(DetectAndroid())
		return true;
	else if(DetectWindowsMobile())
		return true;
	else if(DetectBlackBerry())
		return true;	
	else if(DetectPalmOS())
		return true;
    else
       return false;
	}

function mobileRedirect(URL)	{
//	alert(mobileDetectDevice());
	if(mobileDetectDevice())
		window.location = URL
	}
