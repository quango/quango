
$(document).ready(function() {
  $("#quick_item #tags, #quick_item .ask_item").hide();
  $("#item_title").focus(function(event) {
    $("#quick_item #tags, #quick_item .ask_item").show();
  });
});
