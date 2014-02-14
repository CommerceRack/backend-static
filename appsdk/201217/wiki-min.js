if(!Parse){var Parse={};}
if(!Parse.Simple){Parse.Simple={};}
Parse.Simple.Base=function(grammar,options){if(!arguments.length){return;}
this.grammar=grammar;this.grammar.root=new this.ruleConstructor(this.grammar.root);this.options=options;};Parse.Simple.Base.prototype={ruleConstructor:null,grammar:null,options:null,parse:function(node,data,options,linkCmdPointer){if(options){for(i in this.options){if(typeof options[i]=='undefined'){options[i]=this.options[i];}}}
else{options=this.options;}
data=data.replace(/\r\n?/g,'\n');this.grammar.root.apply(node,data,options);node.innerHTML=wikiLinks2html(node.innerHTML,linkCmdPointer);if(options&&options.forIE){node.innerHTML=node.innerHTML.replace(/\r?\n/g,'\r\n');}}};Parse.Simple.Base.prototype.constructor=Parse.Simple.Base;Parse.Simple.Base.Rule=function(params){if(!arguments.length){return;}
for(var p in params){this[p]=params[p];}
if(!this.children){this.children=[];}};Parse.Simple.Base.prototype.ruleConstructor=Parse.Simple.Base.Rule;Parse.Simple.Base.Rule.prototype={regex:null,capture:null,replaceRegex:null,replaceString:null,tag:null,attrs:null,children:null,match:function(data,options){return data.match(this.regex);},build:function(node,r,options){var data;if(this.capture!==null){data=r[this.capture];}
var target;if(this.tag){target=document.createElement(this.tag);node.appendChild(target);}
else{target=node;}
if(data){if(this.replaceRegex){data=data.replace(this.replaceRegex,this.replaceString);}
this.apply(target,data,options);}
if(this.attrs){for(var i in this.attrs){target.setAttribute(i,this.attrs[i]);if(options&&options.forIE&&i=='class'){target.className=this.attrs[i];}}}
return this;},apply:function(node,data,options){var tail=''+data;var matches=[];if(!this.fallback.apply){this.fallback=new this.constructor(this.fallback);}
while(true){var best=false;var rule=false;for(var i=0;i<this.children.length;i++){if(typeof matches[i]=='undefined'){if(!this.children[i].match){this.children[i]=new this.constructor(this.children[i]);}
matches[i]=this.children[i].match(tail,options);}
if(matches[i]&&(!best||best.index>matches[i].index)){best=matches[i];rule=this.children[i];if(best.index==0){break;}}}
var pos=best?best.index:tail.length;if(pos>0){this.fallback.apply(node,tail.substring(0,pos),options);}
if(!best){break;}
if(!rule.build){rule=new this.constructor(rule);}
rule.build(node,best,options);var chopped=best.index+best[0].length;tail=tail.substring(chopped);for(var i=0;i<this.children.length;i++){if(matches[i]){if(matches[i].index>=chopped){matches[i].index-=chopped;}
else{matches[i]=void 0;}}}}
return this;},fallback:{apply:function(node,data,options){if(options&&options.forIE){data=data.replace(/\n/g,' \r');}
node.appendChild(document.createTextNode(data));}}};Parse.Simple.Base.Rule.prototype.constructor=Parse.Simple.Base.Rule;Parse.Simple.Creole=function(options){var rx={};rx.img='\\{\\{((?!\\{)[^|}\\n]*(?:}(?!})[^|}\\n]*)*)'+
(options&&options.strict?'':'(?:')+
'\\|([^}~\\n]*((}(?!})|~.)[^}~\\n]*)*)'+
(options&&options.strict?'':')?')+
'}}';var formatLink=function(link,format){if(format instanceof Function){return format(link);}
format=format instanceof Array?format:[format];if(typeof format[1]=='undefined'){format[1]='';}
return format[0]+link+format[1];};var g={hr:{tag:'hr',regex:/(^|\n)\s*----\s*(\n|$)/},br:{tag:'br',regex:/\\\\/},preBlock:{tag:'pre',capture:2,regex:/(^|\n)\{\{\{\n((.*\n)*?)\}\}\}(\n|$)/,replaceRegex:/^ ([ \t]*\}\}\})/gm,replaceString:'$1'},tt:{tag:'tt',regex:/\{\{\{(.*?\}\}\}+)/,capture:1,replaceRegex:/\}\}\}$/,replaceString:''},ulist:{tag:'ul',capture:0,regex:/(^|\n)([ \t]*\*[^*#].*(\n|$)([ \t]*[^\s*#].*(\n|$))*([ \t]*[*#]{2}.*(\n|$))*)+/},olist:{tag:'ol',capture:0,regex:/(^|\n)([ \t]*#[^*#].*(\n|$)([ \t]*[^\s*#].*(\n|$))*([ \t]*[*#]{2}.*(\n|$))*)+/},li:{tag:'li',capture:0,regex:/[ \t]*([*#]).+(\n[ \t]*[^*#\s].*)*(\n[ \t]*\1[*#].+)*/,replaceRegex:/(^|\n)[ \t]*[*#]/g,replaceString:'$1'},table:{tag:'table',capture:0,regex:/(^|\n)(\|.*?[ \t]*(\n|$))+/},tr:{tag:'tr',capture:2,regex:/(^|\n)(\|.*?)\|?[ \t]*(\n|$)/},th:{tag:'th',regex:/\|+=([^|]*)/,capture:1},td:{tag:'td',capture:1,regex:'\\|+([^|~\\[{]*((~(.|(?=\\n)|$)|'+
'\\[\\['+rx.link+'(\\|'+rx.linkText+')?\\]\\]'+
(options&&options.strict?'':'|'+rx.img)+
'|[\\[{])[^|~]*)*)'},singleLine:{regex:/.+/,capture:0},paragraph:{tag:'p',capture:0,regex:/(^|\n)([ \t]*\S.*(\n|$))+/},text:{capture:0,regex:/(^|\n)([ \t]*[^\s].*(\n|$))+/},strong:{tag:'strong',capture:1,regex:/\*\*([^*~]*((\*(?!\*)|~(.|(?=\n)|$))[^*~]*)*)(\*\*|\n|$)/},em:{tag:'em',capture:1,regex:'\\/\\/(((?!'+rx.uriPrefix+')[^\\/~])*'+
'(('+rx.rawUri+'|\\/(?!\\/)|~(.|(?=\\n)|$))'+
'((?!'+rx.uriPrefix+')[^\\/~])*)*)(\\/\\/|\\n|$)'},img:{regex:rx.img,build:function(node,r,options){var img=document.createElement('img');img.src=r[1];img.alt=r[2]===undefined?(options&&options.defaultImageText?options.defaultImageText:''):r[2].replace(/~(.)/g,'$1');}},namedUri:{regex:'\\[\\[('+rx.uri+')\\|('+rx.linkText+')\\]\\]',build:function(node,r,options){var link=document.createElement('a');link.href=r[1];if(options&&options.isPlainUri){link.appendChild(document.createTextNode(r[2]));}
else{this.apply(link,r[2],options);}
node.appendChild(link);}},namedLink:{regex:'\\[\\[('+rx.link+')\\|('+rx.linkText+')\\]\\]',build:function(node,r,options){var link=document.createElement('a');link.href=options&&options.linkFormat?formatLink(r[1].replace(/~(.)/g,'$1'),options.linkFormat):r[1].replace(/~(.)/g,'$1');this.apply(link,r[2],options);node.appendChild(link);}},unnamedUri:{regex:'\\[\\[('+rx.uri+')\\]\\]',build:'dummy'},unnamedLink:{regex:'\\[\\[('+rx.link+')\\]\\]',build:'dummy'},unnamedInterwikiLink:{regex:'\\[\\[('+rx.interwikiLink+')\\]\\]',build:'dummy'},rawUri:{regex:'('+rx.rawUri+')',build:'dummy'},escapedSequence:{regex:'~('+rx.rawUri+'|.)',capture:1,tag:'span',attrs:{'class':'escaped'}},escapedSymbol:{regex:/~(.)/,capture:1,tag:'span',attrs:{'class':'escaped'}}};g.unnamedUri.build=g.rawUri.build=function(node,r,options){if(!options){options={};}
options.isPlainUri=true;g.namedUri.build.call(this,node,Array(r[0],r[1],r[1]),options);};g.unnamedLink.build=function(node,r,options){g.namedLink.build.call(this,node,Array(r[0],r[1],r[1]),options);};g.namedInterwikiLink={regex:'\\[\\[('+rx.interwikiLink+')\\|('+rx.linkText+')\\]\\]',build:function(node,r,options){var link=document.createElement('a');var m,f;if(options&&options.interwiki){m=r[1].match(/(.*?):(.*)/);f=options.interwiki[m[1]];}
if(typeof f=='undefined'){if(!g.namedLink.apply){g.namedLink=new this.constructor(g.namedLink);}
return g.namedLink.build.call(g.namedLink,node,r,options);}
link.href=formatLink(m[2].replace(/~(.)/g,'$1'),f);this.apply(link,r[2],options);node.appendChild(link);}};g.unnamedInterwikiLink.build=function(node,r,options){g.namedInterwikiLink.build.call(this,node,Array(r[0],r[1],r[1]),options);};g.namedUri.children=g.unnamedUri.children=g.rawUri.children=g.namedLink.children=g.unnamedLink.children=g.namedInterwikiLink.children=g.unnamedInterwikiLink.children=[g.escapedSymbol,g.img];for(var i=1;i<=6;i++){g['h'+i]={tag:'h'+i,capture:2,regex:'(^|\\n)[ \\t]*={'+i+'}[ \\t]'+
'([^~]*?(~(.|(?=\\n)|$))*)[ \\t]*=*\\s*(\\n|$)'};}
g.ulist.children=g.olist.children=[g.li];g.li.children=[g.ulist,g.olist];g.li.fallback=g.text;g.table.children=[g.tr];g.tr.children=[g.th,g.td];g.td.children=[g.singleLine];g.th.children=[g.singleLine];g.h1.children=g.h2.children=g.h3.children=g.h4.children=g.h5.children=g.h6.children=g.singleLine.children=g.paragraph.children=g.text.children=g.strong.children=g.em.children=[g.escapedSequence,g.strong,g.em,g.br,g.rawUri,g.namedUri,g.namedInterwikiLink,g.namedLink,g.unnamedUri,g.unnamedInterwikiLink,g.unnamedLink,g.tt,g.img];g.root={children:[g.h1,g.h2,g.h3,g.h4,g.h5,g.h6,g.hr,g.ulist,g.olist,g.preBlock,g.table],fallback:{children:[g.paragraph]}};Parse.Simple.Base.call(this,g,options);};Parse.Simple.Creole.prototype=new Parse.Simple.Base();Parse.Simple.Creole.prototype.constructor=Parse.Simple.Creole;function stripHTML(text){var r=text.replace(/<\/?[a-z][a-z0-9]*[^<>]*>/ig,"");return r;}
function wikiLinks2html(wiki,linkCmdPointer){if(wiki.indexOf("[[",0)>=0){var myOutput=new Array;var myTokens=wiki.split(/(\[\[.*?\].*?\])/);for(var i=0;i<myTokens.length;i++){var chunk=myTokens[i];if(chunk.match(/^\[\[.*?\].*?\]$/)){var output='';var phrase=chunk.match(/^\[\[(.*?)\]/)[1];var operation=chunk.match(/^\[\[.*?\](.*?)\]$/)[1];var suffix='';if(operation.indexOf("=")>0){suffix=operation.match(/^.*?\=(.*?)$/)[1];operation=operation.substring(0,operation.indexOf("="));}
if(operation==''){operation=':search';suffix=phrase;}
if(operation!="category"){}
else if(suffix.substring(0,1)=="."){}
else{suffix="."+suffix;}
switch(operation){case":url":output=typeof linkCmdPointer[":url"]=='function'?linkCmdPointer[":url"](suffix,phrase):"<a href=\""+suffix+"\">"+phrase+"</a>";break;case":search":output=typeof myControl.ext[linkCmdPointer].wiki[":search"]=='function'?myControl.ext[linkCmdPointer].wiki[":search"](suffix,phrase):"<a href=\"/search.cgis?keyword="+suffix+"\">"+phrase+"</a>";break;case":category":output=typeof myControl.ext[linkCmdPointer].wiki[":category"]=='function'?myControl.ext[linkCmdPointer].wiki[":category"](suffix,phrase):"<a href=\"/category/"+suffix+"\">"+phrase+"</a>";break;case":product":output=typeof myControl.ext[linkCmdPointer].wiki[":product"]=='function'?myControl.ext[linkCmdPointer].wiki[":product"](suffix,phrase):"<a href=\"/product/"+suffix+"\">"+phrase+"</a>";break;case":customer":output=typeof myControl.ext[linkCmdPointer].wiki[":customer"]=='function'?myControl.ext[linkCmdPointer].wiki[":customer"](suffix,phrase):"<a href=\"/customer/"+suffix+"\">"+phrase+"</a>";break;case":popup":output=typeof myControl.ext[linkCmdPointer].wiki[":popup"]=='function'?myControl.ext[linkCmdPointer].wiki[":popup"](suffix,phrase):"<a href=\""+suffix+"\" target='popup'>"+phrase+"</a>";break;default:output="<!-- unhandled_token: "+chunk+" -->"+phrase;break;}
myOutput.push(output);}
else{myOutput.push(chunk);}}
wiki=myOutput.join("");}
return(wiki);}