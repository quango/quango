/**
 * v0.5 Fancy Opts plugin for jQuery
 * http://rommelsantor.com/jquery/fancyopts
 *
 * Author(s): Rommel Santor
 *            http://rommelsantor.com
 *
 * This plugin allows you to create custom, image-based radio buttons and
 * checkboxes seamlessly integrated into existing forms with graceful
 * degradation.
 *
 * Copyright (c) 2011 by Rommel Santor <rommel at rommelsantor dot com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
@*/
/**
 * >> Requirements <<
 *  jQuery v1.4 or better
 *
 * >> Version History <<
 *  Ver 0.5 - 2011-05-05 - Rommel Santor
 *            Fixed method .fancyopts('check',true) for radio buttons to make
 *            sure all other buttons of the same name become unchecked
 *  Ver 0.4 - 2011-05-03 - Rommel Santor
 *            Added getters for 'checked' and 'disabled'; added additional
 *            optional params to 'check', 'disable', and 'focus' methods
 *            to prevent invoking callbacks onCheck(), onDisable(), and
 *            onFocus()
 *  Ver 0.3 - 2011-04-28 - Rommel Santor
 *            Modified onCheck() callback to be passed radio currently
 *            selected value only with "checked" value of true; reversed
 *            order of args
 *  Ver 0.2 - 2011-03-27 - Rommel Santor
 *            Fix for radio buttons in Chrome (Thanks, Patrick Connolly)
 *  Ver 0.1 - 2011-03-16 - Rommel Santor
 *            Initial Release
 *
 * >> Tested <<
 *  Mozilla (Firefox 3+)
 *  Webkit (Chrome 9+, Safari for Windows 5+)
 *  MSIE 7, 8
 *  Opera 11+
 *
 * >> Known issues <<
 *  - none known
 */
/**
 * Methods:
 *  .fancyopts([options])
 *  .fancyopts('init', [options]) - initialize FancyOpts on a new jQuery object
 *    options : see "Options" below
 *
 *  .fancyopts('disable', [on], [nocallback]) - disable/enable the custom input (like calling .attr({disabled:on}))
 *    on : true/false to force on/off; if unspecified, the disabled state is toggled
 *    nocallback : if non-empty, onDisable() callback will not be invoked
 *
 *  .fancyopts('check', [on], [nocallback]) - check/uncheck the custom input (like calling .attr({checked:on}))
 *    on : true/false to force on/off; if unspecified, checkbox state is toggled and radio is checked
 *    nocallback : if non-empty, onCheck() callback will not be invoked
 *
 *  .fancyopts('focus', [on], [nocallback]) - focus or blur the custom input
 *    on : if true, the first matching element receives focus; if false, all matching elements blur
 *    nocallback : if non-empty, onFocus() callback will not be invoked
 *
 *  .fancyopts('checked') - determine if first element in set is checked (like .attr('checked'))
 *
 *  .fancyopts('disabled') - determine if first element in set is disabled (like .attr('disabled'))
 */
/**
 * Required Options:
 *  image - the url to the image containing the custom input states; must be sprite vertically
 *    stacked in order of:
 *      unchecked
 *      [unchecked-active]
 *      checked
 *      [checked-active]
 *      unchecked-disabled
 *      checked-disabled
 *
 *  width - the width of the supplied image
 *
 *  height - the height of each sub-image sprite within the supplied image
 *
 *  hasActive - whether the unchecked-active and checked-active images are included in the supplied image
 *    
 * Optional Options:
 *  activeHover - whether the active state should be triggered on hover; ignored if hasActive if false
 *    true for active onhover, false for active onmousedown
 *
 *  onCheck - see "Overridable Events" below
 *
 *  onDisable - see "Overridable Events" below
 *
 *  onFocus - see "Overridable Events" below
 */
/**
 * Overridable Events:
 *  onCheck(value, checked) - triggered after checkbox is checked/unchecked or after new radio button is checked
 *    value : for checkbox, value of element; for radio, value of newly selected element
 *    checked : for checkbox, true if element is checked, false if unchecked; for radio, always true
 *
 *  onDisable(disabled) - triggered after being disabled or enabled
 *    disabled : true if element has become disabled; false if enabled
 *
 *  onFocus(focused) - triggered after a FancyOpt element gains or loses focus
 *    focused : true if element received focus; false if it lost focus
$*/
(function($){
  var methods = {
    init : function(options) {
      var settings = {
        image : null,     // sprite must be vertically stacked in order of: off-idle, [off-active], on-idle, [on-active], off-disabled, on-disabled
        width : 0,        // width of full sprite image
        height : 0,       // height of each sub-image within sprite
        hasActive : true, // true or false depending on if off-active and on-active are provided
        activeHover : false, // true to go "active" on hover; false for mouse down
        onCheck : function(value, checked) {},
        onDisable : function(disabled) {},
        onFocus : function(focused) {}
      };

      if (typeof options === 'object')
        $.extend(settings, options);
      
      var $this = this;
      
      if (!settings.width || !settings.height || !settings.image)
        return $this;
      
      return $this.each(function(){
        var $this = $(this),
            data = $this.data('fancyopts')
        ;
        
        if (!data) {
          var id = $this.attr('id'),
              type = $this.attr('type'),
              name = $this.attr('name'),
              width = settings.width,
              height = settings.height
          ;
          
          if (!id) {
            id = 'fancyopts_' + Math.floor(Math.random()*1000+1);
            $this.attr('id', id);
          }
        
          var $icon = $('<span class="fancyopts-icon fancyopts-'+type+' fancyopts-name-'+name+'" id="fancyopts-'+id+'"></span>').insertBefore($this);
          $icon.css({width:width+'px',height:height+'px',background:'url('+settings.image+') no-repeat',display:'inline-block'});
          $icon.data('input', $this);
          $icon.append($this);
          
          var offsets = [], top = 0;
          for (var i = 0; i < (settings.hasActive ? 6 : 4); ++i) {
            offsets.push(top);
            top += height;
          }
          
          var pos = {
            off : offsets[0],
            offactive : -offsets[!settings.hasActive ? 0 : 1],
            on : -offsets[!settings.hasActive ? 1 : 2],
            onactive : -offsets[!settings.hasActive ? 1 : 3],
            disoff : -offsets[settings.hasActive ? 4 : 2],
            dison : -offsets[settings.hasActive ? 5 : 3]
          };
          
          data = {
            settings : settings,
            icon : $icon,
            type : type,
            name : name,
            pos : pos,
            mdown : false,
            checked : $this.is(':checked'),
            disabled : $this.is(':disabled')
          };
          
          $this.data('fancyopts', data);
          
          $("label[for='"+id+"']").click(function(){
            $icon.click();
            return false;
          });
          
          $icon.click(function(){
            var $el = $(this).data('input'),
                data = $el.data('fancyopts');
            
            if (data.disabled)
              return false;
            
            if (!document.activeElement || $el.get(0) != document.activeElement)
              $el.focus();

            if (data.type == 'radio') {
              if (data.checked)
                return false;
              
              $("input[type='radio'][name='"+data.name+"']:checked").fancyopts('check', false);
            }
            
            data.checked = !data.checked;
            $el.data('fancyopts', data).fancyopts('check', data.checked);
            return false;
          });
          
          $icon.mousedown(function(){
            var $el = $(this).data('input'),
                data = $el.data('fancyopts');
            
            if (!data.settings.hasActive || data.disabled)
              return;
            
            data.icon.css({backgroundPosition:'0 '+(data.checked ? data.pos.onactive : data.pos.offactive)+'px'});
            
            data.mdown = true;
            $el.data('fancyopts', data);
          });
          
          $icon.mouseup(function(){
            var $el = $(this).data('input'),
                data = $el.data('fancyopts');
            
            if (!data.settings.hasActive || data.disabled)
              return;
            
            data.icon.css({backgroundPosition:'0 '+(data.checked ? data.pos.on : data.pos.off)+'px'});
            
            data.mdown = false;
            $el.data('fancyopts', data);
          });
          
          $icon.mouseover(function(){
            var $el = $(this).data('input'),
                data = $el.data('fancyopts');
            
            if (data.disabled)
              return;
            
            if (data.settings.activeHover || data.mdown)
              $(this).mousedown();
          });
          
          $icon.mouseout(function(){
            var $el = $(this).data('input'),
                data = $el.data('fancyopts'),
                mdown = data.mdown;
            
            if (data.disabled)
              return;
            
            $(this).mouseup();
            
            data.mdown = mdown;
            $el.data('fancyopts', data);
          });
          
          $this
            .css({position:'absolute',left:'-12345px'})
            .focus(function(){
              $(this).fancyopts('focus', true);
            })
            .blur(function(){
              $(this).fancyopts('focus', false);
            });
          ;

          $this.fancyopts('check', data.checked);
          $this.fancyopts('disable', data.disabled);
        }
      });
    },

    focus : function(focused, nocb) {
      return this.each(function(){
        var data = $(this).data('fancyopts');

        if (focused) {
          $('.fancyopts-icon').css({outline:'0'});
          data.icon.css({outline:'1px dotted'});
          if (data.type == 'radio') {
            var value = $(this).attr('value');
            $("input[type='radio'][name='"+data.name+"']").each(function(){
              if ($(this).attr('value') != value)
                $(this).fancyopts('check', false);
            });
          }
          data.settings.onFocus.call(this, true);
          return false;
        }
        
        data.icon.css({outline:'0'});
        
        if (nocb)
          return;
        
        data.settings.onFocus.call(this, false);
      });
    },

    disable : function(disabled, nocb) {
      return this.each(function(){
        var $this = $(this),
        d = disabled;

        var data = $this.data('fancyopts');
        if (!data)
          return;
        
        if (typeof(d)==='undefined')
          d = !data.disabled;
        
        $this.attr({disabled:d});
        
        if (d)
          data.icon.css({backgroundPosition:'0 '+(data.checked ? data.pos.dison : data.pos.disoff)+'px'});
        else
          data.icon.css({backgroundPosition:'0 '+(data.checked ? data.pos.on : data.pos.off)+'px'});
        
        data.disabled = d;
        $this.data('fancyopts', data);
        
        if (nocb)
          return;
        
        data.settings.onDisable.call(this, d);
      });
    },
    
    check : function(checked, nocb) {
      return this.each(function(){
        var $this = $(this);

        var data = $this.data('fancyopts');
        if (!data)
          return;
        
        if (typeof(checked)==='undefined') {
          data.icon.click();
          return;
        }
        
        // if checking radio button, uncheck any other currently checked in set
        if (checked && data.type == 'radio')
          $("input[type='radio'][name='"+data.name+"']:checked").fancyopts('check', false);

        $this.attr({checked:checked});
        
        if (checked)
          data.icon.css({backgroundPosition:'0 '+(data.disabled ? data.pos.dison : data.pos.on)+'px'});
        else
          data.icon.css({backgroundPosition:'0 '+(data.disabled ? data.pos.disoff : data.pos.off)+'px'});

        data.checked = checked;
        $this.data('fancyopts', data);

        if (nocb)
          return;
        
        if (data.type == 'radio')
          checked && data.settings.onCheck.call(this, $("input[type='radio'][name='"+data.name+"']:checked").val(), checked);
        else
          data.settings.onCheck.call(this, $this.attr('value'), checked);
      });
    },

    checked : function(){
      var $this = $(this);

      var data = $this.data('fancyopts');
      if (!data)
        return null;

      return data.checked;
    },

    disabled : function(){
      var $this = $(this);

      var data = $this.data('fancyopts');
      if (!data)
        return null;

      return data.disabled;
    }
  };

  $.fn.fancyopts = function(method) {
    if (methods[method])
      return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    else if (typeof method === 'object' || !method)
      return methods.init.apply(this, arguments);
    else
      $.error('Method ' +  method + ' does not exist on jQuery.fancyopts');
  };
})(jQuery);
