/*Hello*/

$(document).ready(function() {
  $('#demo').hide();
  var f = $.farbtastic('#picker');
  var p = $('#picker').css('opacity', 0.25);
  var selected;
  $('.colorwell')
    .each(function () { f.linkTo(this); $(this).css('opacity', 1); })
    .focus(function() {
      if (selected) {
        $(selected).css('opacity', 0.75).removeClass('colorwell-selected');
      }
      f.linkTo(this);
      p.css('opacity', 1);
      $(selected = this).css('opacity', 1).addClass('colorwell-selected').addTouch();
      /*$(selected = this).parent('.form-item').style('background-image','0'));*/
    });
});


$(document).ready(function(){
$(".colorwell-selected").focus();
});
