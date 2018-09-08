// Generated by CoffeeScript 2.1.1
(function() {
  fermata.registerPlugin('hawpi', function(transport, base) {
    // I know the name is fcking clever
    this.base = base;
    return function(request, callback) {
      // the rest is "borrowed" from the built-in JSON plugin
      request.headers['Accept'] = 'application/json';
      request.headers['Content-Type'] = 'application/json';
      request.data = JSON.stringify(request.data);
      return transport(request, function(err, response) {
        var e, skip, target;
        if (!err) {
          if (response.status.toFixed()[0] !== '2') {
            err = Error('Bad status code from server: ' + response.status);
          }
          try {
            response = JSON.parse(response.data);
          } catch (error) {
            e = error;
            err = e;
          }
        }
        target = request.options.target;
        skip = request.options.skip_animation;
        if (target) {
          if (!err && !skip) {
            window.style.submit.state(target, true);
          }
          if (err && !skip) {
            window.style.submit.state(target, false);
          }
          if (err || !response.success) {
            window.style.card(true, response.reason);
          }
        }
        callback(err, response);
        if (request.options.target) {
          setTimeout(function() {
            window.style.submit.clear(target);
            if (err) {
              return window.style.card(false);
            }
          }, 2400);
        }
      });
    };
  });

}).call(this);
// Generated by CoffeeScript 2.1.1
(function() {
  var getHeight, insertHtml,
    indexOf = [].indexOf;

  insertHtml = function(value, position, nodes) {
    return nodes.forEach(function(item) {
      var e, results, tmpnode, tmpnodes;
      if (value.includes("<td")) {
        tmpnodes = document.createElement('tbody');
      } else {
        tmpnodes = document.createElement('div');
      }
      tmpnodes.innerHTML = value;
      results = [];
      while ((tmpnode = tmpnodes.lastChild) !== null) {
        try {
          if (position === 'before') {
            results.push(item.parentNode.insertBefore(tmpnode, item));
          } else if (position === 'after') {
            results.push(item.parentNode.insertBefore(tmpnode, item.nextSibling));
          } else if (position === 'append') {
            results.push(item.appendChild(tmpnode));
          } else if (position === 'prepend') {
            results.push(item.insertBefore(tmpnode, item.firstChild));
          } else {
            results.push(void 0);
          }
        } catch (error) {
          e = error;
          break;
        }
      }
      return results;
    });
  };

  $.fn.hasClass = function(className) {
    return !!this[0] && this[0].classList.contains(className);
  };

  $.fn.addClass = function(className) {
    this.forEach(function(item) {
      var classList;
      classList = item.classList;
      return classList.add.apply(classList, className.split(/\s/));
    });
    return this;
  };

  $.fn.removeClass = function(className) {
    this.forEach(function(item) {
      var classList;
      classList = item.classList;
      return classList.remove.apply(classList, className.split(/\s/));
    });
    return this;
  };

  $.fn.toggleClass = function(className, b) {
    this.forEach(function(item) {
      var classList;
      classList = item.classList;
      if (typeof b !== 'boolean') {
        b = !classList.contains(className);
      }
      classList[b ? 'add' : 'remove'].apply(classList, className.split(/\s/));
    });
    return this;
  };

  $.fn.css = function(property, value = null) {
    if (value === null) {
      console.log('this is not yet implemented');
    } else {
      this.forEach(function(item) {
        var e;
        try {
          return item.style[property] = value;
        } catch (error) {
          e = error;
          return console.error('Could not set css style property "' + property + '".');
        }
      });
    }
    return this;
  };

  $.fn.remove = function() {
    this.forEach(function(item) {
      return item.parentNode.removeChild(item);
    });
    return this;
  };

  $.fn.val = function(value = '') {
    if (value !== '') {
      this.forEach(function(item) {
        return item.value = value;
      });
    } else if (this[0]) {
      return this[0].value;
    }
    return this;
  };

  $.fn.html = function(value = null) {
    if (value !== null) {
      this.forEach(function(item) {
        return item.innerHTML = value;
      });
    }
    if (this[0]) {
      return this[0].innerHTML;
    }
    return this;
  };

  $.fn.htmlBefore = function(value) {
    insertHtml(value, 'before', this);
    return this;
  };

  $.fn.htmlAfter = function(value) {
    insertHtml(value, 'after', this);
    return this;
  };

  $.fn.htmlAppend = function(value) {
    insertHtml(value, 'append', this);
    return this;
  };

  $.fn.htmlPrepend = function(value) {
    insertHtml(value, 'prepend', this);
    return this;
  };

  $.fn.fadeIn = function(value) {
    this.forEach(function(item) {
      item.style.display = "block";
      item.style.opacity = "0";
      item.style.transition = "0.2s opacity ease";
      return setTimeout(function() {
        return item.style.opacity = null;
      }, 10);
    });
    return this;
  };

  $.fn.fadeOut = function(value) {
    this.forEach(function(item) {
      item.style.transition = "0.2s opacity ease";
      item.style.opacity = "0";
      return setTimeout(function() {
        return item.style.display = "none";
      }, 200);
    });
    return this;
  };

  $.fn.fadeToggle = function(value) {
    this.forEach(function(item) {
      item.style.transition = "0.2s opacity ease";
      if (window.getComputedStyle(item).display === "none") {
        item.style.display = "block";
        return setTimeout(function() {
          return item.style.opacity = null;
        }, 10);
      } else {
        item.style.opacity = "0";
        return setTimeout(function() {
          return item.style.display = "none";
        }, 200);
      }
    });
    return this;
  };

  $.fn.not = function(value) {
    return $(this.filter((item) => {
      return indexOf.call(value, item) < 0;
    }));
  };

  getHeight = function(el) {
    var el_display, el_max_height, el_position, el_style, el_visibility, wanted_height;
    el_style = window.getComputedStyle(el);
    el_display = el_style.display;
    el_position = el_style.position;
    el_visibility = el_style.visibility;
    el_max_height = el_style.maxHeight.replace('px', '').replace('%', '');
    wanted_height = 0;
    // if its not hidden we just return normal height
    if (el_display !== 'none' && el_max_height !== '0') {
      return el.offsetHeight;
    }
    // the element is hidden so:
    // making the el block so we can meassure its height but still be hidden
    el.style.position = 'absolute';
    el.style.visibility = 'hidden';
    el.style.display = 'block';
    wanted_height = el.offsetHeight;
    // reverting to the original values
    el.style.display = el_display;
    el.style.position = el_position;
    el.style.visibility = el_visibility;
    return wanted_height;
  };

  $.fn.slideToggle = function() {
    this.forEach(function(el) {
      var el_max_height;
      el_max_height = 0;
      if (el.getAttribute('data-max-height')) {
        // we've already used this before, so everything is setup
        if (el.style.maxHeight.replace('px', '').replace('%', '') === '0') {
          return el.style.maxHeight = el.getAttribute('data-max-height');
        } else {
          return el.style.maxHeight = '0';
        }
      } else {
        el_max_height = getHeight(el) + 'px';
        el.style['transition'] = 'max-height 0.5s ease-in-out';
        el.style.overflowY = 'hidden';
        el.style.maxHeight = '0';
        el.setAttribute('data-max-height', el_max_height);
        el.style.display = 'block';
        // we use setTimeout to modify maxHeight later than display (to we have the transition effect)
        return setTimeout((function() {
          el.style.maxHeight = el_max_height;
        }), 10);
      }
    });
    return this;
  };

  $.fn.slideUp = function() {
    if (this.length === 0) {
      return;
    }
    if (this[0].style.display === "block") {
      return this.slideToggle();
    }
  };

  $.fn.slideDown = function() {
    if (this.length === 0) {
      return;
    }
    if (this[0].style.display === "none") {
      return this.slideToggle();
    }
  };

  $.fn.animate = function(values, timing) {
    var animation, current, i, len, property, ref, that;
    animation = "";
    ref = Object.entries(values);
    for (i = 0, len = ref.length; i < len; i++) {
      property = ref[i];
      property[0] = property[0] === "width" ? "max-width" : property[0];
      animation += `${property[0]} `;
    }
    animation += `${timing / 1000}s ease`;
    current = 0;
    this.forEach(function(item) {
      item.style.transition = animation;
      if (Object.keys(values).includes("width")) {
        current = parseInt(item.style['max-width']);
        return item.style["max-width"] = window.getComputedStyle(item).width;
      }
    });
    that = this;
    setTimeout(function() {
      return that.forEach(function(item) {
        var j, len1, ref1, results;
        ref1 = Object.entries(values);
        results = [];
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          property = ref1[j];
          if (property[0] === "width") {
            item.style['max-width'] = property[1];
            if (parseInt(property[1]) < current) {
              results.push(setTimeout(function() {
                return item.style[property[0]] = property[1];
              }, timing));
            } else {
              results.push(item.style[property[0]] = property[1]);
            }
          } else {
            results.push(item.style[property[0]] = property[1]);
          }
        }
        return results;
      });
    }, 10);
    return this;
  };

}).call(this);
// Generated by CoffeeScript 2.1.1
(function() {
  // original code from davesag
  // http://jsfiddle.net/davesag/qgCrk/6/
  var DatetoISO8601, parseDuration, toDurationString, to_seconds;

  to_seconds = function(dd, hh, mm) {
    var d, h, m, t;
    d = parseInt(dd);
    h = parseInt(hh);
    m = parseInt(mm);
    if (d == null) {
      d = 0;
    }
    if (h == null) {
      h = 0;
    }
    if (m == null) {
      m = 0;
    }
    // if (isNaN(d)) d = 0
    // if (isNaN(h)) h = 0
    // if (isNaN(m)) m = 0
    t = d * 24 * 60 * 60 + h * 60 * 60 + m * 60;
    return t;
  };

  // expects 1d 11h 11m, or 1d 11h,
  // or 11h 11m, or 11h, or 11m, or 1d
  // returns a number of seconds.
  parseDuration = function(sDuration) {
    var days, drx, hours, hrx, minutes, morx, mrx, wrx, yrx;
    if (sDuration === null || sDuration === '') {
      return 0;
    }
    mrx = new RegExp(/([0-9][0-9]?)[ ]?m(?:[^o]|$)/);
    hrx = new RegExp(/([0-9][0-9]?)[ ]?h/);
    drx = new RegExp(/([0-9]{1,2})[ ]?d/);
    wrx = new RegExp(/([0-9][0-9]?)[ ]?w/);
    morx = new RegExp(/([0-9][0-9]?)[ ]?mo/);
    yrx = new RegExp(/([0-9][0-9]?)[ ]?y/);
    days = 0;
    hours = 0;
    minutes = 0;
    if (morx.test(sDuration)) {
      days += morx.exec(sDuration)[1] * 31;
    }
    if (mrx.test(sDuration)) {
      minutes = mrx.exec(sDuration)[1];
    }
    if (hrx.test(sDuration)) {
      hours = hrx.exec(sDuration)[1];
    }
    if (drx.test(sDuration)) {
      days += drx.exec(sDuration)[1];
    }
    if (wrx.test(sDuration)) {
      days += wrx.exec(sDuration)[1] * 7;
    }
    if (yrx.test(sDuration)) {
      days += yrx.exec(sDuration)[1] * 365;
    }
    return to_seconds(days, hours, minutes);
  };

  // outputs a duration string based on
  // the number of seconds provided.
  // rounded off to the nearest 1 minute.
  toDurationString = function(iDuration) {
    var d, h, m, result;
    if (iDuration <= 0) {
      return '';
    }
    m = Math.floor((iDuration / 60) % 60);
    h = Math.floor((iDuration / 3600) % 24);
    d = Math.floor(iDuration / 86400);
    result = '';
    if (d > 0) {
      result = result + d + 'd ';
    }
    if (h > 0) {
      result = result + h + 'h ';
    }
    if (m > 0) {
      result = result + m + 'm ';
    }
    return result.substring(0, result.length - 1);
  };

  DatetoISO8601 = function(obj) {
    var date, hours, minutes, month, year;
    year = obj.getFullYear();
    month = obj.getMonth().toString().length === 1 ? '0' + (obj.getMonth() + 1).toString() : obj.getMonth() + 1;
    date = obj.getDate().toString().length === 1 ? '0' + obj.getDate().toString() : obj.getDate();
    hours = obj.getHours().toString().length === 1 ? '0' + obj.getHours().toString() : obj.getHours();
    minutes = obj.getMinutes().toString().length === 1 ? '0' + obj.getMinutes().toString() : obj.getMinutes();
    return `${year}-${month}-${date}T${hours}:${minutes}`;
  };

  window.style.duration = {
    parse: parseDuration,
    string: toDurationString
  };

  window.style.getOrCreate('utils').date = {
    convert: {
      to: {
        iso: DatetoISO8601
      }
    }
  };

}).call(this);
// Generated by CoffeeScript 2.1.1
(function() {
  //= require style.fermata.coffee
  //= require style.ext.coffee
  //= require style.time.coffee
  var InformationCard, InputVerification, copyTextToClipboard;

  copyTextToClipboard = function(text) {
    var err, msg, successful, textArea;
    textArea = document.createElement('textarea');
    // https://stackoverflow.com/questions/400212/how-do-i-copy-to-the-clipboard-in-javascript
    textArea.style.position = 'fixed';
    textArea.style.top = 0;
    textArea.style.left = 0;
    textArea.style.width = '2em';
    textArea.style.height = '2em';
    textArea.style.padding = 0;
    textArea.style.border = 'none';
    textArea.style.outline = 'none';
    textArea.style.boxShadow = 'none';
    textArea.style.background = 'transparent';
    textArea.value = text;
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try {
      successful = document.execCommand('copy');
      msg = successful ? 'successful' : 'unsuccessful';
    } catch (error) {
      err = error;
      console.log('Oops, unable to copy');
    }
    document.body.removeChild(textArea);
  };

  InputVerification = function(mode, event, that) {
    var character, keycode;
    keycode = void 0;
    if (window.event) {
      keycode = window.event.keyCode;
    } else if (event) {
      keycode = event.which;
    }
    character = String.fromCharCode(event.keyCode);
    switch (mode) {
      case 'single':
        if (keycode === 13) {
          return false;
        }
    }
    return true;
  };

  InformationCard = function(show = true, reason) {
    var output;
    if (show) {
      output = '';
      reason.forEach(function(i) {
        if (typeof i === 'string') {
          return output += `<div class='content'>${i}</div>`;
        } else if (typeof i === 'object') {
          return Object.keys(i).forEach(function(k) {
            return i[k].forEach(function(state) {
              state = state.replace(/of uuid type/g, 'present');
              state = state.replace(/value/g, i[k]);
              if (state.search(k === -1)) {
                state = `${k} ${state}`;
              }
              return output += `<div class='content'>${state}</div>`;
            });
          });
        }
      });
      $('.status-card .info').html(output);
      return $('.status-card').addClass('active');
    } else {
      return $('.status-card').removeClass('active');
    }
  };

  window.style.getOrCreate('utils').getOrCreate('verify').input = InputVerification;

  window.style.card = InformationCard;

  window.style.copy = copyTextToClipboard;

  window.endpoint = {
    api: fermata.hawpi('/api/v1'),
    ajax: fermata.raw({
      base: window.location.origin + '/ajax/v1'
    }),
    bare: fermata.raw({
      base: window.location.origin
    })
  };

}).call(this);
