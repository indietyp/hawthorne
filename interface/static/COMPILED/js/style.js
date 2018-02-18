// Generated by CoffeeScript 2.1.1
(function() {
  // original code from davesag
  // http://jsfiddle.net/davesag/qgCrk/6/
  var parseDuration, toDurationString, to_seconds;

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
    var days, drx, hours, hrx, minutes, mrx;
    if (sDuration === null || sDuration === '') {
      return 0;
    }
    mrx = new RegExp(/([0-9][0-9]?)[ ]?m/);
    hrx = new RegExp(/([0-9][0-9]?)[ ]?h/);
    drx = new RegExp(/([0-9]{1,2})[ ]?d/);
    days = 0;
    hours = 0;
    minutes = 0;
    if (mrx.test(sDuration)) {
      minutes = mrx.exec(sDuration)[1];
    }
    if (hrx.test(sDuration)) {
      hours = hrx.exec(sDuration)[1];
    }
    if (drx.test(sDuration)) {
      days = drx.exec(sDuration)[1];
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

  $().ready(function() {
    window.endpoint = fermata.json("/api/v1");
    return $("input#inputtimevalue").on('change', function(event, ui) {
      var field, icon, sd, seconds;
      event.preventDefault();
      field = $('input#inputtimevalue');
      icon = $('input#inputtimevalue + label svg');
      sd = field.val();
      seconds = parseDuration(sd);
      if (sd !== '' && seconds === 0) {
        field.css('border-bottom-color', '#FF404B');
        icon.css('stroke', '#FF404B');
        return this.focus();
      } else {
        field.css('border-bottom-color', '');
        icon.css('stroke', '');
        return field.val(toDurationString(seconds));
      }
    });
  });

}).call(this);
