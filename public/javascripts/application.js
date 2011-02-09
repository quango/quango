$(document).ready(function(){
$("input#item_video_link").blur(function() {
  $("#spinner").show(); // show the spinner
    var form = $(this).parents("form"); // grab the form wrapping the search bar.
    var url = form.attr("action"); // grab the URL from the form's action value.
    var url = url + "/get_video_info"
    var formData = form.serialize(); // grab the data in the form
    $.get(url, formData, function(html) { // perform an AJAX get, the trailing function is what happens on successful get.
      $("#spinner").hide(); // hide the spinner
      $("#results").html(html).show(); // replace the "results" div with the result of action taken
  });
});
});

// perform JavaScript after the document is scriptable.

$(document).ready(function(){
$(".user-mini").hover(
    function() {$(".avatar-wide").children('.a').stop().animate({"opacity": "0"}, "slow");},
    function() {$(".avatar-wide").children('.a').stop().animate({"opacity": "1"}, "fast");}
);
});

$(document).ready(function(){
$(".avatar-narrow").hover(
    function() {$(this).children('.a').stop().animate({"opacity": "0"}, "slow");},
    function() {$(this).children('.a').stop().animate({"opacity": "1"}, "fast");}
);
});

$(document).ready(function() {
        $('#gallery a').lightBox();
});


$(document).ready(function(){
$(".fade-thumbnails").hover(
    function() {$(this).children('.a').stop().animate({"opacity": "0"}, "slow");},
    function() {$(this).children('.a').stop().animate({"opacity": "1"}, "fast");}
);
});

$(function() {	// setup ul.tabs to work as tabs for each div directly under div.panes	
  $("#member-tabs ul.member-tabs").tabs("div.panes > div.pane", { history: true, effect: 'fade', fadeOutSpeed: 400 });
});

$(document).ready(function() {
$(".answer").hover(
      function() { $(this).find('.toolbox-container').children('.toolbox').fadeIn('slow'); },
      function() { $(this).find('.toolbox-container').children('.toolbox').fadeOut('slow'); }
  );
$(".answer").hover(
      function() { $(this).find('.actionbox-container').children('.actionbox').fadeIn('fast'); },
      function() { $(this).find('.actionbox-container').children('.actionbox').fadeOut('slow'); }
 );
});


// here, we allow the user to sort the items
var setSelector = "#section-listing ul";
// set the cookie name
var setCookieName = "listOrder";
// set the cookie expiry time (days):
var setCookieExpiry = 7;


$(document).ready(function() {

	$(setSelector).sortable({
		axis: "y",
		cursor: "move",
  	placeholder: 'ui-state-highlight',
		update: function() { getOrder(); }
	});
  $(setSelector).disableSelection(); 
	// here, we reload the saved order
	restoreOrder();
});




$(document).ready(function() {

  //$("a.button[title]").tooltip({position: "bottom center"}) #do later
  $("form.nestedAnswerForm").hide();
  $("#add_comment_form").hide();
  $("form").live('submit', function() {
    var textarea = $(this).find('textarea');
    removeFromLocalStorage(location.href, textarea.attr('id'));
    window.onbeforeunload = null;
  });

  $('.confirm-domain').submit(function(){
      var bool = confirm($(this).attr('data-confirm'));
      if(bool==false) return false;

  })
  $("#feedbackform").dialog({ title: "Feedback", autoOpen: false, modal: true, width:"420px" })
  $('#feedbackform .cancel-feedback').click(function(){
    $("#feedbackform").dialog('close');
    return false;
  })
  $('#feedback').click(function(){
    var isOpen = $("#feedbackform").dialog('isOpen');
    if (isOpen){
      $("#feedbackform").dialog('close');
    } else {
      $("#feedbackform").dialog('open');
    }
    return false;
  })

  initAutocomplete();
  initAutocompleteLocations();
  initAutocompletePersons();

  $(".quick-vote-button").live("click", function(event) {
    var btn = $(this);
    btn.hide();
    var src = btn.attr('src');
    if (src.indexOf('/images/dialog-ok.png') == 0){
      var btn_name = $(this).attr("name")
      var form = $(this).parents("form");
      $.post(form.attr("action"), form.serialize()+"&"+btn_name+"=1", function(data){
        if(data.success){
          btn.parents('.item').find('.votes .counter').text(data.average);
          btn.attr('src', '/images/dialog-ok-apply.png');
          showMessage(data.message, "notice")
        } else {
          showMessage(data.message, "error")
          if(data.status == "unauthenticate") {
            window.onbeforeunload = null;
            window.location="/users/login"
          }
        }
        btn.show();
      }, "json");
    }
    return false;
  });

  $("a#hide_announcement").click(function() {
    $("#announcement_message").fadeOut();
    $.post($(this).attr("href"), "format=js");
    return false;
  });

  $('textarea').live('keyup',function(){
      var value = $(this).val();
      var id = $(this).attr('id');
      addToLocalStorage(location.href, id, value);
  })

  initStorageMethods();
  fillTextareas();

  $(".highlight_for_user").effect("highlight", {}, 2000);
  sortValues('#group_language', 'option', ':last', 'text', null);
  sortValues('#language_filter', 'option',  ':lt(2)', 'text', null);
  sortValues('#user_language', 'option',  false, 'text', null);
  sortValues('#lang_opts', '.radio_option', false, 'attr', 'id');

  $('.langbox.jshide').hide();
  $('.show-more-lang').click(function(){
      $('.langbox.jshide').toggle();
      return false;
  })
})

function initAutocomplete(){
  var tagInput = $('.autocomplete_for_tags');
  tagInput.autoSuggest('tags_for_autocomplete.js', {
    queryParam: 'tag',
    formatList: function(data, elem){
      return elem.html(data.caption);
    },
    preFill: tagInput.val(),
    startText: '',
    emptyText: 'No Results',
    limitText: 'No More Selections Are Allowed'
  });
}

function initAutocompleteLocations(){
  var tagInput = $('.autocomplete_for_locations');
  tagInput.autoSuggest('tags_for_locations.js', {
    queryParam: 'location',
    formatList: function(data, elem){
      return elem.html(data.caption);
    },
    preFill: tagInput.val(),
    startText: '',
    emptyText: 'No Results',
    limitText: 'No More Selections Are Allowed'
  });
}

function initAutocompletePersons(){
  var tagInput = $('.autocomplete_for_persons');
  tagInput.autoSuggest('tags_for_persons.js', {
    queryParam: 'person',
    formatList: function(data, elem){
      return elem.html(data.caption);
    },
    preFill: tagInput.val(),
    startText: '',
    emptyText: 'No Results',
    limitText: 'No More Selections Are Allowed'
  });
}

function manageAjaxError(XMLHttpRequest, textStatus, errorThrown) {
  showMessage("sorry, something went wrong.", "error");
}

function showMessage(message, t, delay) {
  $("#notifyBar").remove();
  $.notifyBar({
    html: "<div class='message "+t+"' style='width: 100%; height: 100%; padding: 5px'>"+message+"</div>",
    delay: delay||3000,
    animationSpeed: "normal",
    barClass: "flash"
  });
}

function hasStorage(){
  if (window.localStorage && typeof(Storage)!='undefined'){
    return true;
  } else {
      return false;
  }
}

function initStorageMethods(){
  if(hasStorage()){
    Storage.prototype.setObject = function(key, value) {
        this.setItem(key, JSON.stringify(value));
    }

    Storage.prototype.getObject = function(key) {
        return JSON.parse(this.getItem(key));
    }
  }
}

function fillTextareas(){
   if(hasStorage() && localStorage[location.href]!=null && localStorage[location.href]!='null'){
       localStorageArr = localStorage.getObject(location.href);
       $.each(localStorageArr, function(i, n){
           $("#"+n.id).val(n.value);
           $("#"+n.id).parents('form.commentForm').show();
           $("#"+n.id).parents('form.nestedAnswerForm').show();
       })
    }
}

function addToLocalStorage(key, id, value){
  if(hasStorage()){
    var ls = localStorage[key];
    if($.trim(value)!=""){
      if(ls == null || ls == "null" || typeof(ls)=="undefined"){
          localStorage.setObject(key,[{id: id, value: value}]);
      } else {
          var storageArr = localStorage.getObject(key);
          var isIn = false;
          storageArr = $.map(storageArr, function(n, i){
              if(n.id == id){
                n.value = value;
                isIn = true;
              }
          return n;
        })
      if(!isIn)
        storageArr = $.merge(storageArr, [{id: id, value: value}]);
      localStorage.setObject(key, storageArr);
    }
    } else {removeFromLocalStorage(key, id);}
  }
}

function removeFromLocalStorage(key, id){
  if(hasStorage()){
    var ls = localStorage[key];
    if(typeof(ls)=='string'){
      var storageArr = localStorage.getObject(key);

      storageArr = $.map(storageArr, function(n, i){
          if(n.id == id){
            return null;
          } else {
              return n;
          }
      })
      localStorage.setObject(key, storageArr);
    }
  }
}


function sortValues(selectID, child, keepers, method, arg){
  if(keepers){
    var any = $(selectID+' '+child+keepers);
    any.remove();
  }
  var sortedVals = $.makeArray($(selectID+' '+child)).sort(function(a,b){
    return $(a)[method](arg) > $(b)[method](arg) ? 1: -1;
  });
  $(selectID).empty().html(sortedVals);
  if(keepers)
    $(selectID).prepend(any);
  //updateValueList();
};

function highlightEffect(object) {
  if(typeof object != "undefined") {
    object.fadeOut(400, function() {
      object.fadeIn(400)
    });
  }
}


// function that writes the list order to a cookie
function getOrder() {
	// save custom order to cookie
	$.cookie(setCookieName, $(setSelector).sortable("toArray"), { expires: setCookieExpiry, path: "/" });
}

// function that restores the list order from a cookie
function restoreOrder() {
	var list = $(setSelector);
	if (list == null) return
	
	// fetch the cookie value (saved order)
	var cookie = $.cookie(setCookieName);
	if (!cookie) return;
	
	// make array from saved order
	var IDs = cookie.split(",");
	
	// fetch current order
	var items = list.sortable("toArray");
	
	// make array from current order
	var rebuild = new Array();
	for ( var v=0, len=items.length; v<len; v++ ){
		rebuild[items[v]] = items[v];
	}
	
	for (var i = 0, n = IDs.length; i < n; i++) {
		
		// item id from saved order
		var itemID = IDs[i];
		
		if (itemID in rebuild) {
		
			// select item id from current order
			var item = rebuild[itemID];
			
			// select the item according to current order
			var child = $("ul.ui-sortable").children("#" + item);
			
			// select the item according to the saved order
			var savedOrd = $("ul.ui-sortable").children("#" + itemID);
			
			// remove all the items
			child.remove();
			
			// add the items in turn according to saved order
			// we need to filter here since the "ui-sortable"
			// class is applied to all ul elements and we
			// only want the very first!  You can modify this
			// to support multiple lists - not tested!
			$("ul.ui-sortable").filter(":first").append(savedOrd);
		}
	}
}




