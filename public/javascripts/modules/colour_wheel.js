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

$(document).ready(function() {
  $('a.auto-colors.button.inner-button').click(function(){

  fb = $.farbtastic('#picker', function(rgb_hex){
    var rgb_norm = fb.unpack(rgb_hex);
    var hsl_norm = fb.RGBToHSL(rgb_norm);
    $('.colorwell').each(function(){
      var hue_shift = 0.00;
      var sat_shift = 0.00;
      var lum_shift = 0.00;
      var swatch_hsl = [];
      var swatch_rgb = [];
      var swatch_id = this.id;

      //SWATCH TABLE
      switch(swatch_id){
        case      'group_text_colour'  : hue_shift =  0.00; sat_shift = -1.00; lum_shift = (hsl_norm[2] >= 0.33)? -1.00 : 1.00; break;

        case      'group_primary_dark' : hue_shift =  0.00; sat_shift =  0.00; lum_shift = -0.50; break;
        case      'group_primary'      : hue_shift =  0.00; sat_shift =  0.00; lum_shift =  0.00; break;
        case      'group_secondary'    : hue_shift =  0.08; sat_shift =  0.00; lum_shift =  0.00; break;
        case      'group_tertiary'     : hue_shift = -0.08; sat_shift =  0.00; lum_shift =  0.00; break;

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
    });
  });
});

});

$(document).ready(function() {
  $('#demo').hide();
  var f = $.farbtastic('#picker');
  var p = $('#picker').css('opacity', 0.25);
  var selected;
  $('.colorwell')
    .each(function () { f.linkTo(this); $(this).css('opacity', 1); })
    .focus(function() {
      if (selected) {
        $(selected).css('opacity', 1).removeClass('colorwell-selected').blur();
      }
      f.linkTo(this);
      p.css('opacity', 1);
      $(selected = this).css('opacity', 1).addClass('colorwell-selected').blur();
      /*$(selected = this).parent('.form-item').style('background-image','0'));*/
    });
});


$(document).ready(function(){
$(".colorwell-selected").focus();
});

