$(document).ready(function() {

// assuming all checkboxes are unchecked at first
//$("span[class='check_box']").addClass("unchecked");

	$(".check_box").click(function(){

		if($(this).children("input").is(':checked')){
			// uncheck
			$(this).children("input").attr({value: 0});
      $("form").submit();
		}else{
			// check
			$(this).children("input").attr({value: 1});
      $("form").submit();
		}
	});
});
