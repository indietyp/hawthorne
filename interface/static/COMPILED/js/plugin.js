var g=g||{};g.scope={};g.findInternal=function(c,a,e){c instanceof String&&(c=String(c));for(var f=c.length,d=0;d<f;d++){var b=c[d];if(a.call(e,b,d,c))return{i:d,v:b}}return{i:-1,v:void 0}};g.ASSUME_ES5=!1;g.ASSUME_NO_NATIVE_MAP=!1;g.ASSUME_NO_NATIVE_SET=!1;g.defineProperty=g.ASSUME_ES5||"function"==typeof Object.defineProperties?Object.defineProperty:function(c,a,e){c!=Array.prototype&&c!=Object.prototype&&(c[a]=e.value)};
g.getGlobal=function(c){return"undefined"!=typeof window&&window===c?c:"undefined"!=typeof global&&null!=global?global:c};g.global=g.getGlobal(this);g.polyfill=function(c,a){if(a){var e=g.global;c=c.split(".");for(var f=0;f<c.length-1;f++){var d=c[f];d in e||(e[d]={});e=e[d]}c=c[c.length-1];f=e[c];a=a(f);a!=f&&null!=a&&g.defineProperty(e,c,{configurable:!0,writable:!0,value:a})}};g.polyfill("Array.prototype.find",function(c){return c?c:function(a,c){return g.findInternal(this,a,c).v}},"es6","es3");
g.polyfill("Array.from",function(c){return c?c:function(a,c,f){c=null!=c?c:function(b){return b};var d=[],b="undefined"!=typeof Symbol&&Symbol.iterator&&a[Symbol.iterator];if("function"==typeof b){a=b.call(a);for(var h=0;!(b=a.next()).done;)d.push(c.call(f,b.value,h++))}else for(b=a.length,h=0;h<b;h++)d.push(c.call(f,a[h],h));return d}},"es6","es3");
(function(){$(function(){return c()});var c=function(a){a=void 0===a?document:a;$('[data-trigger="[dropdown/toggle]"]',a).off("click");$('[data-trigger="[dropdown/toggle]"]',a).on("click",function(){$(".expand").not($(".expand",this.parentElement)).slideUp();$(".menu > ul > li > a").not($(this)).removeClass("navActive");$(this).toggleClass("navActive");$(".expand",this.parentElement).slideToggle()});$("[data-trigger='[modal/open]']",a).off("click");$("[data-trigger='[modal/open]']",a).on("click",
function(){$(".overlay").fadeIn("fast");var b=this.getAttribute("data-trigger-target");b=$("[data-component='"+b+"']");b.fadeIn("fast");if(this.hasAttribute("data-trigger-overrides")){var a=this.getAttribute("data-trigger-overrides");var c=$("form",b);a.split(";").forEach(function(b){b=b.split("=");return $("[name='"+b[0]+"']",c)[0].value=b[1]})}});$("[data-trigger='[server/item]']",a).off("click");$("[data-trigger='[server/item]']",a).on("click",function(){$(this).toggleClass("toggableListActive");
$(this).find(".content").fadeToggle("fast")});$("[data-trigger='[modal/close]']",a).off("click");$("[data-trigger='[modal/close]']",a).on("click",function(){var b;$(".overlay").fadeOut("fast");for(b=this.parentElement;!$(b).hasClass("modal");)b=b.parentElement;$(b).fadeOut("fast")});$(".overlay",a).off("click");$(".overlay",a).on("click",function(){$(".overlay").fadeOut("fast");$(".modal").fadeOut("fast")});$("[data-trigger='[system/messages/open]']",a).off("click");$("[data-trigger='[system/messages/open]']",
a).on("click",function(){$(".notificationsArea",this).fadeToggle("fast");$($("a",this)[0]).toggleClass("userMenuActive")});$('[data-trigger="[announcement/expand]"]',a).off("click");$('[data-trigger="[announcement/expand]"]',a).on("click",function(){$(".announcement-expand",this).slideToggle()});$('[data-trigger="[user/toggle]"]',a).off("click");$('[data-trigger="[user/toggle]"]',a).on("click",function(){$(".dropdown",this).fadeToggle("fast")});$(".search input",a).off("click");$(".search input",
a).on("click",function(){$(".modal").fadeOut("fast");$(".searchOverlay").fadeIn("fast");$(".searchArea").fadeToggle("fast","grid");$(".search").animate({width:"30%"},250)});var c=function(){$(".searchOverlay").fadeOut("fast");$(".searchArea").fadeOut("fast");$(".search").animate({width:"20%"},250)};$(".searchOverlay",a).off("click");$(".searchOverlay",a).on("click",c);$(".search input",a).off("keyup");$(".search input",a).on("keyup",function(b){window.search(b.target.value)});$(".search .searchArea",
a).off("click");$(".search .searchArea",a).on("click",function(b){if("A"===b.target.nodeName)return c(b)});$(".timeTable tbody tr td .checkmarkContainer",a).off("mousedown");$(".timeTable tbody tr td .checkmarkContainer",a).on("mousedown",function(){$(this.parentElement.parentElement).toggleClass("logSelected");$(".checkboxDialogue").not($(".checkboxDialogue",this.parentElement)).fadeOut("fast");$("input",this)[0].checked?$(".checkboxDialogue",this.parentElement).fadeOut("fast"):$(".checkboxDialogue",
this.parentElement).fadeIn("fast")});$(".timeTable tbody tr td .checkboxDialogue .paginationTabsDanger",a).off("click");$(".timeTable tbody tr td .checkboxDialogue .paginationTabsDanger",a).on("click",function(){$(this.parentElement).fadeOut("fast");var b=$(this).parent("tbody")[0];$("tr.logSelected",b).removeClass("logSelected");$("input:checked",b).forEach(function(b){return b.checked=!1});window.batch=[]});var f=function(){var b=$(this).parent("._Dynamic_Select");var a=$("._Dynamic_Layer",b);b.toggleClass("_Dynamic_Select_Activated");
$("._Select",b).toggleClass("selected");a.toggleClass("selected");a.hasClass("selected")&&(a.on("click",function(a){f.call(this);var h=new MouseEvent(a.type,a);a=document.elementFromPoint(a.clientX,a.clientY);a.matches("input")&&a.focus();b=$(this).parent("._Dynamic_Select");$("._Title",b)[0]!==a&&a.dispatchEvent(h);return $(this).off("click")}),$("._Select_Search input",b)[0].focus())};$('[data-trigger="[composer/select/open]"]',a).off("click");$('[data-trigger="[composer/select/open]"]',a).on("click",
f);var d=[];$('[data-trigger="[composer/select/choose]"]',a).off("click");$('[data-trigger="[composer/select/choose]"]',a).on("click",function(){if($("._Title",$(this).parent("._Dynamic_Select"))[0].hasAttribute("data-select-multiple")){var b=$(this).find("p").text();var a=$(this).find(".checkmarkContainer input");if(a.is(":checked"))for(a.prop("checked",!1),a=0;a<d.length;){if(d[a]===b){d.splice(a,1);break}a+=1}else a.prop("checked",!0),d.push(b);$(this).closest("._Dynamic_Select").find("._Title").text("("+
d.length+") selections")}else b=$(this).parent("._Dynamic_Select"),b.toggleClass("_Dynamic_Select_Activated"),$("._Select",b).toggleClass("selected"),$("._Dynamic_Layer",b).toggleClass("selected"),$("._Title",b)[0].textContent=$("p",this)[0].textContent,$("._Value",b)[0].value=this.getAttribute("data-value")});$('[data-trigger="[composer/select/steam]"]',a).off("keyup");$('[data-trigger="[composer/select/steam]"]',a).on("keyup",function(){var b=this.value;var a=this.hasAttribute("data-email");var c=
/^(?:https:\/\/)?steamcommunity\.com\/profiles\/(\d+)$/i.exec(b);var d=/^(?:https:\/\/)?steamcommunity\.com\/id\/(.+)$/i.exec(b);var k=/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/.exec(b);var f={"X-CSRFToken":window.csrftoken};if(SteamIDConverter.isSteamID(b)||SteamIDConverter.isSteamID3(b))b=SteamIDConverter.toSteamID64(b);else if(c)b=c[1];else if(d)b=d[1];else if(a&&k)return;c=d?JSON.stringify({steam:b}):
SteamIDConverter.isSteamID64(b)?JSON.stringify({steam64:b}):a&&k?JSON.stringify({email:b}):JSON.stringify({local:b});var e=$(this).parent("._Dynamic_Select");$("._Loading",e).addClass("selected");$("._Container",e)[0].innerHTML="";return window.endpoint.ajax.utils.search.post(f,c,function(b,a){$("._Container",e)[0].innerHTML=a.data;$("._Loading",e).removeClass("selected");window._.init($("._Container",e)[0])})});$('[data-trigger="[composer/select/search]"]',a).off("keyup");$('[data-trigger="[composer/select/search]"]',
a).on("keyup",function(b){var a=[];var c=this.value;var d=$(this).parent("._Select");d=$("._Container",d);$("p",d).forEach(function(b){a.push(b)});if(""===this.value)a.forEach(function(b){return $(b).parent("li")[0].style.display="block"});else if(!(90<=b.which||48>=b.which)){var e=[];a.forEach(function(b){$(b).parent("li")[0].style.display="none";return e.push([b,distance(b.textContent,c)])});e.sort(function(b,a){return a[1]-b[1]});e=e.slice(0,5);e.forEach(function(b){return $(b[0]).parent("li")[0].style.display=
"block"})}});$("[data-trigger='[ct/switch]']",a).off("click");$("[data-trigger='[ct/switch]']",a).on("click",function(){$(".paginationTabSelected",this.parentElement).removeClass("paginationTabSelected");var b=this.getAttribute("data");$(this).addClass("paginationTabSelected");history.replaceState({location:window._.location,scope:window._.scope},null,"#"+b);window.lazy(this.parentElement.getAttribute("data-target"),"")});$("[data-trigger='[ct/toggle]']",a).off("change");$("[data-trigger='[ct/toggle]']",
a).on("change",function(){var b;for(b=this.parentElement;"tr"!==b.nodeName.toLowerCase();)b=b.parentElement;var a=-1;window.batch.forEach(function(c){if(c.getAttribute("data-id")===b.getAttribute("data-id"))return a=window.batch.indexOf(c)});-1!==a&&window.batch.splice(a,1);if(this.checked)return window.batch.push(b)});$("[data-trigger='[table/choice]']",a).off("click");$("[data-trigger='[table/choice]']",a).on("click",function(){var b=$(this).parent(".modalSelect");var a=this.getAttribute("data-mode");
switch($("select",b)[0].value){case "delete":return window.api.remove(a,window.batch,!0);case "edit":$(".overlay").fadeIn("fast");a=$("[data-component='[modal/"+a+"/edit]']");a.fadeIn("fast");if(1===window.batch.length){$("input.single",a).removeClass("hidden");$("input.batch",a).addClass("hidden");var c=window.batch[0];return $("input:not(.skip):not([type=checkbox])",a).forEach(function(a){b=$(a).parent();a.value=c.getAttribute("data-"+a.name);if(b.hasClass(a.value))return a=$("._Container li[data-value='"+
a.value+"'] p",b)[0].textContent,$("._Title",b)[0].textContent=a})}$("input:not(.skip):not([type=checkbox])",a).forEach(function(a){return a.value=""});$("input.batch",a).removeClass("hidden");$("input.single",a).addClass("hidden");a=$("input.batch",a)[0];return a.value=a.value.replace(/(\d+)/g,window.batch.length)}});$("[data-trigger='[modal/action]']",a).off("click");$("[data-trigger='[modal/action]']",a).on("click",function(){var a=$(this).parent(".modal");var c=this.getAttribute("data-mode");
switch(this.getAttribute("data-action")){case "delete":return window.api.remove(c,a[0],!1)}});$("[data-trigger='[modal/form]']",a).off("submit");$("[data-trigger='[modal/form]']",a).on("submit",function(a){a.preventDefault();a=this.getAttribute("data-mode");switch(this.getAttribute("data-action")){case "create":return window.api.create(a,this,!1);case "edit":return window.api.edit(a,this,0<window.batch.length);case "misc":return window.api.misc(a,this)}});$("[data-trigger='[grid/delete]']",a).off("click");
$("[data-trigger='[grid/delete]']",a).on("click",function(){var a=$(this).parent(".serverGridItem");var c=this.getAttribute("data-mode");return window.api.remove(c,a[0],!1)});$('[data-trigger="[clip/copy]"]',a).off("click");$('[data-trigger="[clip/copy]"]',a).on("click",function(){return window.style.copy(this.getAttribute("data-clipboard-text"))});$('[data-trigger="[input/duration]"]',a).off("keypress");$('[data-trigger="[input/duration]"]',a).on("keypress",function(a){a.preventDefault();var b=this.selectionStart;
if(/[PTYDHMS0-9]/.test(a.key.toUpperCase()||1!==a.key.length)){var c=a.target.value;c=c.substr(0,b)+a.key+c.substr(b);c=c.toUpperCase();"P"!==c[0]&&(c="P"+c,b+=1);a.target.value=c;this.setSelectionRange(b+1,b+1);try{return $(this).removeClass("invalid"),new Duration(c)}catch(l){return $(this).addClass("invalid")}}});$('[data-trigger="[input/range]"]',a).off("keypress");$('[data-trigger="[input/range]"]',a).on("keypress",function(a){a.preventDefault();var b=this.selectionStart;var c=this.getAttribute("data-min");
var d=this.getAttribute("data-max");if(/[0-9]/.test(a.key.toUpperCase()||1!==a.key.length)){var e=a.target.value;e=e.substr(0,b)+a.key+e.substr(b);e=parseInt(e);e>parseInt(d)&&(e=d);e<parseInt(c)&&(e=c);a.target.value=e;return this.setSelectionRange(b+1,b+1)}});$('[data-trigger="[select/multiple/double]"]',a).on("click",function(){var a=$(this.getAttribute("data-source"));var c=$(this.getAttribute("data-target"));return Array.from(a[0].selectedOptions).forEach(function(a){return c[0].insertBefore(a,
c[0].firstChild)})})};window._={init:c,menu:function(){$(".paginationTabs").forEach(function(a){var c;var f=a.children;var d=[];var b=0;for(c=f.length;b<c;b++)a=f[b],window.location.hash&&window.location.hash.substring(1)===a.getAttribute("data")?d.push($(a).addClass("paginationTabSelected")):d.push(void 0);return d})}};window.batch=[]}).call(this);
