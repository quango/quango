var currentParams = {}

// Sample callback function
function displayResults(paramHash){
    var thumbnailData = paramHash.thumbnailDataURL;
    if(thumbnailData){
        $('thumbnail_preview').innerHTML = '<img src="'+unescape(thumbnailData)+'"/>';
    }
	$('output').innerHTML = $H(paramHash).toJSON().replace(/\"\,/gmi, '",\n');
	//window.location.href = '#results';
	window.scrollTo(0,10000);
}		

function updateParamsForAction(){	
	
	$$('#sample_params li.sample_param').each(function(e,i){
		var isVisible = e.getAttribute('rel') == $('scratch_action').value;
		e.style.display = isVisible ? 'block' : 'none';
	});
	
	if(Prototype.Browser.MobileSafari){
	    if($('scratch_action').value == 'new'){
	        $('file_upload_input').show();
	        $('file_view_input').hide();
	    }else{
	        $('file_upload_input').hide();
	        $('file_view_input').show();	        
        }
	}
	
	currentParams = {};
	
	updateScratchWithCurrentParams();
	
}

function toggleOptionInfoFor(paramName){
	$(paramName+'_description').toggle();
	$(paramName).toggleClassName('selected');
}

function updateScratchWithCurrentParams(){
	// Update the variable inputs	
	for(var paramName in currentParams){
		$(paramName+'_value').value = currentParams[paramName];
	}
	
	// Update the URL
	$('scratch_url').innerHTML = Picup.urlForOptions($('scratch_action').value, currentParams);
	
	// Show which params are selected
	$$('#sample_params li.sample_param').each(function(e,i){
		var isVisible = !!currentParams[e.id];
		// Clear out the value if it's not being used
		if(!isVisible) e.select('input')[0].value = '';
	});			
	
	// Each time the params change, we'll convert the input field.
	// In practice, this will probably be called once, on page load
	if(Prototype.Browser.MobileSafari){
	    Picup.convertFileInput($('file_upload_input'), currentParams);	
	}	
}

function viewScratchURL(){
    window.open(Picup.urlForOptions('view', currentParams), Picup.windowname);
}

document.observe('dom:loaded', function(){


	if(Prototype.Browser.MobileSafari){
		$(document.body).addClassName('iphone');
	}
	// Define the callback handler
	Picup.callbackHandler = displayResults;
	// We'll check the hash when the page loads in-case it was opened in a new page
	// due to memory constraints
	Picup.checkHash();
	
	// Hide the descriptions
	$$('dl.param_description').each(function(e,i){
		e.hide();
	});
	
	// Observe text inputs
	$$('#params_selector input[type="text"]').each(function(input, i){
		input.observe('change', function(e){					
			var input = e.element();
			var paramName = input.id.replace('_value', '');
			var paramValue = input.value.strip();			
			if(!paramValue){
				delete currentParams[paramName];
			}else{	
				currentParams[paramName] = paramValue;
			}
			updateScratchWithCurrentParams();
		});
	});

	updateParamsForAction();

    // Set some starter params	
    currentParams = {
    	'callbackURL' 		: 'http://picupapp.com/done.html',
    	'referrername' 		: escape('Picup Scratchpad'),
    	'referrerfavicon' 	: escape('http://picupapp.com/favicon.ico'),
    	'purpose'           : escape('Select a sample image for the Picup Scratchpad tool.'),
    	'debug' 			: 'true'
    };
		
	updateScratchWithCurrentParams();

});
