/*
Change Log

11/09/2009 - added the subscribe and email validation functions.

*/





//This is called in the ajax themes as well as in the pop_reviews_ajax default layout (for reviews validation).





// Default function that will submit the tell a friend form through ajax.  Executed in validateTAF function.
// LAYOUTID must be declared in the toxml file.
function submitTAF(params) {
//Update the form div so that 'send' isn't pushed twice.
	$('contentTaf').innerHTML = 'Updating - please wait!';

// this gets called by handleResponse (which is in zoovy.js)
	var postBody = 'm=RenderElement&format=LAYOUT&docid='+LAYOUTID+'&element=AJAX_TAF_FORM&targetDiv=contentTaf&'+params;
	new Ajax.Request('/ajax/RenderElement', {
			postBody: postBody, asynchronous: 1,
			onComplete: function(request){handleResponse(request.responseText)},
// If the taf form submits successfully, the contentTaf div is overwritten with the tafConfirm var (set in toxml file - a 'success' message.)
			onSuccess: $("contentTaf").innerHTML = tafConfirm
			}
		);
	}

// execute this function onsubmit for an ajax taf and it will validate tafForm before submission.
// you MUST set a div with id tafAlerts in your toxml near the form to display error messages.
// Set a var in the toxml file 'tafConfirm' for the confirmation message.
// the taf form MUST have an ID and NAME of tafForm and be inside a div called tafContent.
function validateTAF()	{
// we use alerts to compile a list of all the errors for display later.
	var alerts = '';
//Error checking to make sure form fields are populated.  Error messages saved to alerts var. 
	if(document.tafForm.SENTFROM.value == '')
		alerts += 'Please enter your full name. <br>';
	if(document.tafForm.SENDER.value == '')
		alerts += 'Please enter your email. <br>';
	if(document.tafForm.RECIPIENT.value == '')
		alerts += 'Please enter the destination email. <br>';
	if(document.tafForm.TITLE.value == '')
		alerts += 'Please enter the message title (subject line). <br>';
	if(document.tafForm.MESSAGE.value == '')
		alerts += 'Please enter a short, personal message for the intended recipient. <br>';
		
//if there are no alerts, submit the taf form using the submitTAF function.
	if(alerts == '')	{
//put all of the key/values from the tafForm into the params var to be passed along in postBody
	var params = Form.serialize($("tafForm"));
//We pass in the params so that the submitTAF function can be overwritten in the toxml file to perform a different ajax behavior.
		submitTAF(params);
	}
//some important fields were left blank.  Let the user know which.
	else	{
		$('alertsTaf').innerHTML = alerts;
		}
	}

// execute this function onsubmit for an ajax product reviews and it will validate reviewForm before submission.
// requires that you set a div with id reviewAlerts in your toxml near the form to display error messages.
// Set a var in the toxml file 'reviewConfirm' for the confirmation message.

function submitReview()	{
	var alerts = '';
//these validate the form, making sure name, subject, message and score are set.
	if(document.reviewForm.CUSTOMER_NAME.value == '')
		alerts += 'please enter your name<br>';
	if(document.reviewForm.SUBJECT.value == '')
		alerts += 'please enter a subject line<br>';
	if(document.reviewForm.MESSAGE.value == '')
		alerts += 'please write a short review<br>';
	if(document.reviewForm.RATING.value == '')
		alerts += 'please score/rank this product.<br>';	
//If alerts isn't blank, then the customer didn't fill in the entire form.  Display alerts in the alerts div.
	if(alerts != '')	{
		$('alertsReviews').innerHTML = alerts;
		}
//Looks like they filled everything in, upload the review then reload the review elements.
	else	{
		var params = Form.serialize($('reviewForm'));
//	alert(params);
		var postBody = 'm=addReview&PID='+SKU+'&'+params;
		new Ajax.Request('/ajax/addReview', { 
			postBody: postBody, 
			asynchronous: 1,
//		onComplete: function(request){handleResponse(request.responseText)},
		  	onComplete: $('contentReviews').innerHTML = reviewConfirm
			} );
		}
	}




//validates email address.
function echeck(str) {
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
	
	
//ajax post to perform the subscribe
function subscribeCustomer(email,name)	{
	var postBody = 'm=newsletterSubscribe&email='+email+'&fullname='+name;		
	new Ajax.Request('/ajax/newsletterSubscribe', { 
		postBody: postBody, 
		asynchronous: 1,
		onSuccess: function(r) {
			// this would set innerHTML to whatever parameters zoovy returned (which should be parsed)
			// technically speaking this *COULD* return multiple responses
			// on newlines separated by ? -- but pretty sure this only returns 1 response.
			var ro = r.responseText.toQueryParams();
				if (ro.err != 0) {
					$('errorsSubscribe').innerHTML = ro.err;
				}
				else {
					subscribeCustomer(email,name);
//set subscribeSuccess to overload the default 'success' text.
					$('successSubscribe').innerHTML = (subscribeSuccess!=null)?subscribeSuccess:'Thank you, you have been subscribed to our newsletter.';
					
//blank out the error messages.
					$('errorsSubscribe').innerHTML = '';
					
//blank out the content area so it is clear the form was successfully submitted.
					$('contentSubscribe').innerHTML = '';
					
				}
			}
		} );
	}
	
/*


This function gets executed when the submit button is pushed.
It checks (via ajax) if a customer record exists and, if so, sends a coupon to the customer.  
If no record exists yet, an account is created (via ajax subscribe) and then a coupon is emailed.

*/

function submitSubscribe() {
//validate form. make sure appropriate fields are populated and email address is valid.
//Looks like IE removes the form vars from the DOM when the content of the div that contains the form is overwritten with innerHTML, so we save these as vars for later use

	var fullName = $('fullname').value;
	var emailAddress=$('email').value;
	var errors = '';


	
	var emailAddress = document.getElementById('email').value;


//validate the form, making sure name and email are valid.

	if(fullName == '') 
		errors += '<li>Please enter your full name<\/li>'; //no blanks
	else if(fullName.indexOf(' ')== -1 || fullName.indexOf(' ')==0)
		errors += '<li>Full name is required (first and last)<\/li>'; //make sure there is a space (two words)
	if ((emailAddress==null)||(emailAddress=="")){
		errors += "<li>Email address is required<\/li>" ; //make sure email is populated
	}
	else if (echeck(emailAddress)==false){
		errors += "<li>The email address you entered is invalid. Please check for typos and try again.<\/li>" ; //validate email address
	}


//If errors isn't blank, then the customer didn't fill in the entire form.  Display errors in the errors div.
	if(errors != '')	{
		$('errorsSubscribe').innerHTML = errors;
		}

//Looks like they filled everything in. try to subscribe them
	else	{
	

//Update the form div so that 'send' isn't pushed twice.  Clear out any existing errors.

		$('errorsSubscribe').innerHTML = '<div align="center">Updating... please wait.<\/div><div align="center"><img src="\/\/static.zoovy.com\/graphics\/general\/loading\/flower_grey-35x35.gif" width="35" height="35" alt="loading"><\/div>';
		
		subscribeCustomer(emailAddress,fullName);
//		alert(customer);

		}

/* make a sacrifice to the form gods. 
return false so the form does not submit. Even on success, we don't want to reload the page. */

	return false;
	}
