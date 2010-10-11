
$(document).ready(function() {
  $("label#rqlabel").hide();

  $(".text_field#item_title").focus( function() {
    highlightEffect($("#sidebar .help"))
  });

  $("#ask_item").searcher({ url : "/items/related_items.js",
                              target : $("#related_items"),
                              fields : $("input[type=text][name*=item]"),
                              behaviour : "focusout",
                              timeout : 2500,
                              extraParams : { 'format' : 'js', 'per_page' : 5 },
                              success: function(data) {
                                $("label#rqlabel").show();
                              }
  });

  $("#ask_item").bind("keypress", function(e) {
    if (e.keyCode == 13) {
       return false;
     }
  });

});
