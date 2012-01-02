$(document).ready(function() {

  function satLum(val,i,val_shift){
    if(val_shift < 0){
      val += val * val_shift;
      if(val < 0.0) val = 0.0;
    }
    else if(val_shift > 0){
      val += (1.0 - val) * val_shift
      if(val > 1.0) val = 1.0;
    }
    return val;
  }

  //INIT JUNK
  $('#demo').hide();
  var auto = false;
  var selected = $('.colorwell-selected');

  //AUTO COLOUR TOGGLE
  $('#auto-colours').click(function(){
    auto = !auto;
    if(auto){
      $(this).css('border','2px inset');
      $('.colorwell').each(function(){$(this).css('opacity', 1).addClass('colorwell-selected');});
    }
    else{
      $(this).css('border','2px outset #606060');
      $('.colorwell-selected').each(function(){$(this).removeClass('colorwell-selected')});
      selected = $('.colorwell').filter(':first').addClass('colorwell-selected');
    }
  });

  //FARBTASTIC
  fb = $.farbtastic('#picker', function (rgb_hex){

    //AUTO COLOUR
    if(auto){
      var rgb_norm = fb.unpack(rgb_hex);
      var hsl_norm = fb.RGBToHSL(rgb_norm);
      $('.colorwell').each(function(rgb_hex){
        var hue_shift = 0.00;
        var sat_shift = 0.00;
        var lum_shift = 0.00;
        var swatch_hsl = [];
        var swatch_rgb = [];
        var swatch_id = this.id;

        //SWATCH TABLE
        switch(swatch_id){
          case      'group_text_colour'  : hue_shift =  0.00; sat_shift = -1.00; lum_shift = (hsl_norm[2] >= 0.33)? -1.00 : 1.00; break;

          case      'group_primary_dark' : hue_shift =  0.00; sat_shift =  0.00; lum_shift =  0.00; break;
          case      'group_primary'      : hue_shift =  0.00; sat_shift =  0.00; lum_shift =  0.11; break;
          case      'group_secondary'    : hue_shift =  0.00; sat_shift =  0.00; lum_shift =  0.33; break;
          case      'group_tertiary'     : hue_shift =  0.00; sat_shift =  0.00; lum_shift =  0.66; break;

          default                        : hue_shift =  0.00; sat_shift =  0.00; lum_shift =  0.00;
        }

        //HUE SHIFT
        var hue = hsl_norm[0];
        hue = hue + hue_shift;
        if(hue > 1.0) hue = hue - 1.0
        else if(hue < 0.0) hue = hue + 1.0;
        swatch_hsl.push(hue);

        //SATURATION SHIFT
        swatch_hsl[1] = satLum(hsl_norm[1],1,sat_shift);

        //LUMINOSITY SHIFT
        swatch_hsl[2] = satLum(hsl_norm[2],2,lum_shift);

        swatch_rgb = fb.HSLToRGB(swatch_hsl);
        $('#' + swatch_id).css('background-color',fb.pack(swatch_rgb));
        $('#' + swatch_id).attr('value', fb.pack(swatch_rgb));
      });
    }
    //END AUTO COLOUR
    
    //MANUAL COLOUR
    else{
      //$(".colorwell-selected").blur(); Wut?
      $('.colorwell').click(function() {
        if (selected) {
          $(selected).removeClass('colorwell-selected').blur();
        }
        $(selected = this).addClass('colorwell-selected');
      });

      $('.colorwell-selected').css('background-color',rgb_hex);
    }
    //END MANUAL COLOUR
  });
  //END FARBTASTIC
});
