$(document).ready(function() {

// assuming all checkboxes are unchecked at first
//$("span[class='check_box']").addClass("unchecked");

	$(".check_box").click(function(){

		if($(this).children("input").attr("checked")){
			// uncheck
			$(this).children("input").attr({checked: ""});
			$(this).removeClass("checked");
			$(this).addClass("unchecked");
		}else{
			// check
			$(this).children("input").attr({checked: "checked"});
			$(this).removeClass("unchecked");
			$(this).addClass("checked");
		}

		//alert($(this).children("input").attr("checked"));
	});
});
