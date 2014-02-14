var store_product=function(){var r={vars:{},calls:{appProductGet:{init:function(pid,tagObj,Q){var r=0;tagObj=$.isEmptyObject(tagObj)?{}:tagObj;tagObj["datapointer"]="appProductGet|"+pid;if(myControl.model.fetchData(tagObj.datapointer)==false){r+=1;this.dispatch(pid,tagObj,Q)}
else if(typeof myControl.data[tagObj.datapointer]['@inventory']=='undefined'||typeof myControl.data[tagObj.datapointer]['@variations']=='undefined'){r+=1;this.dispatch(pid,tagObj,Q)}
else{myControl.util.handleCallback(tagObj)}
return r;},dispatch:function(pid,tagObj,Q){var obj={};obj["_cmd"]="appProductGet";obj["withVariations"]=1;if(typeof zGlobals=='object'&&zGlobals.globalSettings.inv_mode!=1)
obj["withInventory"]=1;obj["pid"]=pid;obj["_tag"]=tagObj;myControl.model.addDispatchToQ(obj,Q);}},cartItemsAdd:{init:function(formID,tagObj){tagObj=$.isEmptyObject(tagObj)?{}:tagObj;tagObj.datapointer='atc_'+myControl.util.unixNow();this.dispatch($('#'+formID).serializeJSON(),tagObj);return 1;},dispatch:function(obj,tagObj){obj["_cmd"]="cartItemsAdd";obj["_zjsid"]=myControl.sessionId;obj["_tag"]=tagObj;myControl.model.addDispatchToQ(obj,'immutable');myControl.calls.cartSet.init({'payment-pt':null});}},appReviewsList:{init:function(pid,tagObj){var r=0;tagObj=$.isEmptyObject(tagObj)?{}:tagObj;tagObj["datapointer"]="appReviewsList|"+pid;if(myControl.model.fetchData('appReviewsList|'+pid)==false){r=1;this.dispatch(pid,tagObj)}
else{myControl.util.handleCallback(tagObj)}
return r;},dispatch:function(pid,tagObj){myControl.model.addDispatchToQ({"_cmd":"appReviewsList","pid":pid,"_tag":tagObj});}}},callbacks:{init:{onSuccess:function(){var r=true;return r;},onError:function(){myControl.util.dump('BEGIN myControl.ext.store_product.callbacks.init.onError');}},itemAddedToCart:{onSuccess:function(tagObj){myControl.util.dump('BEGIN myControl.ext.store_product.callbacks.itemAddedToCart.onSuccess');$('.atcButton').removeAttr('disabled');$('#atcMessaging_'+myControl.data[tagObj.datapointer].product1).append(myControl.util.formatMessage({'message':'Item(s) added to the cart!','uiIcon':'check'}))},onError:function(responseData,uuid){myControl.util.dump('BEGIN myControl.ext.store_product.callbacks.init.onError');$('.atcButton').removeAttr('disabled');$('#atcMessaging_'+myControl.data[responseData['_rtag'].datapointer].product1).append(myControl.util.getResponseErrors(responseData))}}},validate:{addToCart:function(pid){var sogJSON=myControl.data['appProductGet|'+pid]['@variations']
var valid=true;if($.isEmptyObject(sogJSON)){myControl.util.dump('no sogs present (or empty object)');}
else{$('#JSONpogErrors_'+pid).empty();var thisSTID=pid;var inventorySogPrompts='';var errors='';var pogid,pogType,pogValue,safeid;if(sogJSON){for(var i=0;i<sogJSON.length;i++){pogid=sogJSON[i]['id'];pogType=sogJSON[i]['type'];safeid=myControl.util.makeSafeHTMLId(pogid);myControl.util.dump(' -> pogid = '+pogid+' and type = '+pogType+' and safeid = '+safeid);if(sogJSON[i]['optional']==1){}
else if(pogType=='attribs'||pogType=='hidden'||pogType=='readonly'){}
else{if(pogType=='radio'||pogType=='imggrid'){pogValue=$("input[name='pog_"+pogid+"']:checked").val();}
else{pogValue=$('#pog_'+safeid).val();}
if(pogValue==""||pogValue===undefined){valid=false;errors+="<li>"+sogJSON[i]['prompt']+"<!--  id: "+pogid+" --><\/li>";}}
if(sogJSON[i]['inv']==1){thisSTID+=':'+pogid+pogValue;inventorySogPrompts+="<li>"+sogJSON[i]['prompt']+"<\/li>";}}}
myControl.util.dump('past validation, before inventory validation. valid = '+valid);if(valid==false){$('#JSONpogErrors_'+pid).append(myControl.util.formatMessage("Uh oh! Looks like you left something out. Please make the following selection(s):<ul>"+errors+"<\/ul>"));}
else if(valid==true&&typeof zGlobals=='object'&&zGlobals.globalSettings.inv_mode>1){if(!$.isEmptyObject(myControl.data['appProductGet|'+pid]['@inventory'])&&!$.isEmptyObject(myControl.data['appProductGet|'+pid]['@inventory'][thisSTID])&&myControl.data['appProductGet|'+pid]['@inventory'][thisSTID]['inv']<1){$('#JSONpogErrors_'+pid).append("We're sorry, but the combination of selections you've made is not available. Try changing one of the following:<ul>"+inventorySogPrompts+"<\/ul>");valid=false;}}}
myControl.util.dump('STID = '+thisSTID);return valid;}},renderFormats:{atcForm:function($tag,data){var formID=$tag.attr('id')+'_'+data.bindData.cleanValue;$tag.attr('id',formID).append("<input type='hidden' name='add' value='yes' /><input type='hidden' name='product_id' id='"+formID+"_product_id' value='"+data.value+"' />");},childrenProdlist:function($tag,data){$tag.append(data.value);},quantityDiscounts:function($tag,data){myControl.util.dump("BEGIN store_product.renderFormats.quantityDiscounts");myControl.util.dump("value: "+data.bindData.cleanValue);var o='';var dArr=data.bindData.cleanValue.split(',');var tmp,num;var L=dArr.length;for(i=0;i<L;i+=1){if(dArr[i].indexOf('=')>-1){tmp=dArr[i].split('=');if(tmp[1].indexOf('$')>=0){tmp[1]=tmp[1].substring(1)}
o+="<div>buy "+tmp[0]+"+ for "+myControl.util.formatMoney(Number(tmp[1]),'$','')+" each<\/div>";}
else if(dArr[i].indexOf('/')>-1){tmp=dArr[i].split('/');o+="<div>buy "+tmp[0]+"+ for ";if(tmp[1].indexOf('$')>=0){tmp[1]=tmp[1].substring(1)}
num=Number(tmp[1])/Number(tmp[0])
myControl.util.dump(" -> number = "+num);o+=myControl.util.formatMoney(num,'$','')
o+=" each<\/div>";}
else{myControl.util.dump("qty discount contained neither a / or an =. odd.");}
tmp='';}
if(data.bindData.pretext){o=data.bindData.pretext+o}
if(data.bindData.posttext){o+=data.bindData.posttext}
$tag.append(o);},simpleInvDisplay:function($tag,data){if(data.value>0)
$tag.addClass('instock').append("In Stock");else
$tag.addClass('outofstock').append("Sold Out");},atcQuantityInput:function($tag,data){if(myControl.ext.store_product.util.productIsPurchaseable(data.bindData.cleanValue)){var o='';o+=data.bindData.pretext?data.bindData.pretext:"";o+="<input type='text' value='1' size='3' name='quantity' class='zform_textbox' id='quantity_"+data.bindData.cleanValue+"' />";o+=data.bindData.posttext?data.bindData.posttext:""
$tag.append(o);}
else
$tag.hide().addClass('displayNone');},atcFixedQuantity:function($tag,data){$tag.attr('id','quantity_'+data.bindData.cleanValue);},atcVariations:function($tag,data){var pid=data.bindData.cleanValue;var formID=$tag.parent('form').get(0).id;if(myControl.ext.store_product.util.productIsPurchaseable(pid)){if(!$.isEmptyObject(myControl.data['appProductGet|'+pid]['@variations'])&&myControl.model.countProperties(myControl.data['appProductGet|'+pid]['@variations'])>0){$("<div \/>").attr('id','JSONpogErrors_'+pid).addClass('zwarn').appendTo($tag);var $display=$("<div \/>").attr('id','JSONPogDisplay_'+pid);pogs=new handlePogs(myControl.data['appProductGet|'+pid]['@variations'],{"formId":formID,"sku":pid});var pog;if(typeof pogs.xinit==='function'){pogs.xinit()}
var ids=pogs.listOptionIDs();for(var i=0,len=ids.length;i<len;++i){pog=pogs.getOptionByID(ids[i]);$display.append(pogs.renderOption(pog,pid));}
$display.appendTo($tag);}
else{}}},addToCartButton:function($tag,data){var pid=data.bindData.cleanValue;$tag.attr('id',$tag.attr('id')+'_'+pid).addClass('atcButton').before("<div class='atcSuccessMessage' id='atcMessaging_"+pid+"'><\/div>");if(myControl.ext.store_product.util.productIsPurchaseable(pid)){$tag.show().removeClass('displayNone').removeAttr('disabled');}
else{$tag.hide().addClass('displayNone').before("<span class='notAvailableForPurchase'>This item is not available for purchase<\/span>");}
}},util:{productIsPurchaseable:function(pid){var r=true;if(!pid){myControl.util.dump(" -> pid not passed into store_product.util.productIsPurchaseable");r=false;}
else if(myControl.data['appProductGet|'+pid]['%attribs']['zoovy:base_price']==''){myControl.util.dump(" -> base price not set: "+pid);r=false;}
else if(myControl.data['appProductGet|'+pid]['%attribs']['zoovy:grp_type']=='PARENT'){myControl.util.dump(" -> product is a parent: "+pid);r=false;}
else if(typeof zGlobals=='object'&&zGlobals.globalSettings.inv_mode!=1){if(typeof myControl.data['appProductGet|'+pid]['@inventory']==='undefined'||typeof myControl.data['appProductGet|'+pid]['@variations']==='undefined'){myControl.util.dump(" -> inventory ("+typeof myControl.data['appProductGet|'+pid]['@inventory']+") and/or variations ("+typeof myControl.data['appProductGet|'+pid]['@variations']+") object(s) not defined.");r=false;}
else{if(myControl.ext.store_product.util.getProductInventory(pid)<=0){myControl.util.dump(" -> inventory not available: "+pid);r=false}}}
return r;},getXsellForPID:function(pid,Q){var csvArray=new Array();if(myControl.data['appProductGet|'+pid]['%attribs']['zoovy:related_products'])
csvArray.concat(myControl.data['appProductGet|'+pid]['%attribs']['zoovy:related_products'])
if(myControl.data['appProductGet|'+pid]['%attribs']['zoovy:accessory_products'])
csvArray.concat(myControl.data['appProductGet|'+pid]['%attribs']['zoovy:accessory_products'])
if(myControl.data['appProductGet|'+pid]['%attribs']['zoovy:grp_children'])
csvArray.concat(myControl.data['appProductGet|'+pid]['%attribs']['zoovy:grp_children'])
if(myControl.data['appProductGet|'+pid]['%attribs']['zoovy:grp_parent'])
csvArray.concat(myControl.data['appProductGet|'+pid]['%attribs']['zoovy:grp_parent'])
csvArray=$.grep(csvArray,function(n){return(n);});csvArray=myControl.util.removeDuplicatesFromArray(csvArray);return this.getProductDataForLaterUse(csvArray,Q);},getProductDataForLaterUse:function(csv,Q){var r=0;var L=csv.length;for(var i=0;i<L;i+=1){if(myControl.util.isSet(csv[i])){r+=myControl.ext.store_product.calls.appProductGet.init(csv[i],{},Q)}}
myControl.util.dump(" -> getProdDataForLaterUser numRequests: "+r);return r;},getProductInventory:function(pid){var inv=0;if($.isEmptyObject(myControl.data['appProductGet|'+pid]['@variations'])){inv=myControl.data['appProductGet|'+pid]['@inventory'][pid].inv
}
else{for(var index in myControl.data['appProductGet|'+pid]['@inventory']){inv+=Number(myControl.data['appProductGet|'+pid]['@inventory'][index].inv)}
}
return inv;},showPicsInModal:function(P){if(P.pid){var parentID=P.parentID?P.parentID:"image-modal";var imageAttr="zoovy:prod_image";imageAttr+=P.int?P.int:"1";P.width=P.width?P.width:600;P.height=P.height?P.height:600;var $parent=this.handleParentForModal(parentID,myControl.data["appProductGet|"+P.pid]['%attribs']['zoovy:prod_name'])
if(!P.parentID){$parent.empty()}
if(P.templateID){$parent.append(myControl.renderFunctions.createTemplateInstance(P.templateID,"imageViewer_"+parentID));myControl.renderFunctions.translateTemplate(myControl.data["appProductGet|"+P.pid],"imageViewer_"+parentID);}
else{$parent.append(myControl.util.makeImage({"class":"imageViewerSoloImage","h":"550","w":"550","bg":"ffffff","name":myControl.data['appProductGet|'+P.pid]['%attribs'][imageAttr],"tag":1}));}
$parent.dialog({modal:true,width:P.width,height:P.height});}
else{myControl.util.dump(" -> no pid specified for image viewer.  That little tidbit is required.");}},showReviewSummary:function(P){if(P.pid&&P.parentID&&P.templateID){var $revSum=$('#'+P.parentID);$revSum.append(myControl.renderFunctions.createTemplateInstance(P.templateID,P.parentID+'_summary_'+P.pid));myControl.renderFunctions.translateTemplate(myControl.ext.store_product.util.summarizeReviews(P.pid),P.parentID+'_summary_'+P.pid);}
else{myControl.util.dump("Required parameters missing for showReviewSummary. P.pid = "+P.pid+" and P.templateID = "+P.templateID+" and P.parentID = "+P.parentID);}},showReviews:function(P){if(P.pid&&P.parentID&&P.templateID&&typeof myControl.data['appReviewsList|'+P.pid]!='undefined'){var $reviews=$('#'+P.parentID);var L=myControl.data['appReviewsList|'+P.pid]['@reviews'].length;for(i=0;i<L;i+=1){$reviews.append(myControl.renderFunctions.createTemplateInstance(P.templateID,'prodReview_'+P.pid+'_'+i));myControl.renderFunctions.translateTemplate(myControl.data['appReviewsList|'+P.pid]['@reviews'][i],'prodReview_'+P.pid+'_'+i);}}
else{myControl.util.dump("Required parameters missing for showReviews. P.pid = "+P.pid+" and P.templateID = "+P.templateID+" and P.parentID = "+P.parentID);}},prodDataInModal:function(P){if(P.pid&&P.templateID){var parentID="product-modal"
var $parent=this.handleParentForModal(parentID,myControl.data["appProductGet|"+P.pid]['%attribs']['zoovy:prod_name'])
if(!P.parentID){myControl.util.dump(" -> parent not specified. empty contents.");$parent.empty()}
$parent.append(myControl.renderFunctions.createTemplateInstance(P.templateID,"productViewer_"+parentID));$parent.dialog({modal:true,width:'86%',height:$(window).height()-100});var tagObj={};tagObj.templateID=P.templateID;tagObj.parentID="productViewer_"+parentID;tagObj.callback=P.callback?P.callback:'translateTemplate';tagObj.extension=P.extension?P.extension:'';myControl.ext.store_product.calls.appProductGet.init(P.pid,tagObj);myControl.ext.store_product.calls.appReviewsList.init(P.pid);myControl.model.dispatchThis();}
else{myControl.util.dump(" -> pid ("+P.pid+") or templateID ("+P.templateID+") not set for viewer. both are required.");}},handleParentForModal:function(parentID,title){var $parent=$('#'+parentID);if($parent.length==0){$parent=$("<div \/>").attr({"id":parentID,"title":title}).appendTo(document.body);}
else{$parent.attr('title',title);}
return $parent;},handleAddToCart:function(formID,tagObj){tagObj=$.isEmptyObject(tagObj)?{}:tagObj;tagObj.callback=tagObj.callback?tagObj.callback:'itemAddedToCart';tagObj.extension=tagObj.extension?tagObj.extension:'store_product';if(myControl.ext.store_product.calls.cartItemsAdd.init(formID,tagObj)){myControl.calls.refreshCart.init({},'immutable');myControl.model.dispatchThis('immutable');}},summarizeReviews:function(pid){var L=0;var sum=0;var avg=0;if(typeof myControl.data['appReviewsList|'+pid]=='undefined'||$.isEmptyObject(myControl.data['appReviewsList|'+pid]['@reviews'])){}
else{L=myControl.data['appReviewsList|'+pid]['@reviews'].length;myControl.util.dump(" -> length = "+L);sum=0;avg=0;for(i=0;i<L;i+=1){sum+=Number(myControl.data['appReviewsList|'+pid]['@reviews'][i].RATING);}
avg=Math.round(sum/L);}
return{"average":avg,"total":L}}}}
return r;}