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
			onSuccess: document.getElementById("contentTaf").innerHTML = tafConfirm
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
		document.getElementById('alertsTaf').innerHTML = alerts;
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
