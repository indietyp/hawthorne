# original code from davesag
# http://jsfiddle.net/davesag/qgCrk/6/
to_seconds = (dd, hh, mm) ->
  d = parseInt(dd)
  h = parseInt(hh)
  m = parseInt(mm)
  d ?= 0
  h ?= 0
  m ?= 0
  # if (isNaN(d)) d = 0
  # if (isNaN(h)) h = 0
  # if (isNaN(m)) m = 0

  t = d * 24 * 60 * 60 +
      h * 60 * 60 +
      m * 60
  return t

# expects 1d 11h 11m, or 1d 11h,
# or 11h 11m, or 11h, or 11m, or 1d
# returns a number of seconds.
parseDuration = (sDuration) ->
  if sDuration == null or sDuration == ''
    return 0

  mrx = new RegExp(/([0-9][0-9]?)[ ]?m(?:[^o]|$)/)
  hrx = new RegExp(/([0-9][0-9]?)[ ]?h/)
  drx = new RegExp(/([0-9]{1,2})[ ]?d/)
  wrx = new RegExp(/([0-9][0-9]?)[ ]?w/)
  morx = new RegExp(/([0-9][0-9]?)[ ]?mo/)
  yrx = new RegExp(/([0-9][0-9]?)[ ]?y/)

  days = 0
  hours = 0
  minutes = 0
  if morx.test(sDuration)
    days += morx.exec(sDuration)[1]*31
  if mrx.test(sDuration)
    minutes = mrx.exec(sDuration)[1]
  if hrx.test(sDuration)
    hours = hrx.exec(sDuration)[1]
  if drx.test(sDuration)
    days += drx.exec(sDuration)[1]
  if wrx.test(sDuration)
    days += wrx.exec(sDuration)[1]*7
  if yrx.test(sDuration)
    days += yrx.exec(sDuration)[1]*365

  return to_seconds(days, hours, minutes)

# outputs a duration string based on
# the number of seconds provided.
# rounded off to the nearest 1 minute.
toDurationString = (iDuration) ->
  if iDuration <= 0
    return ''

  m = Math.floor((iDuration/60)%60)
  h = Math.floor((iDuration/3600)%24)
  d = Math.floor(iDuration/86400)
  result = ''
  if d > 0
    result = result + d + 'd '
  if h > 0
    result = result + h + 'h '
  if m > 0
    result = result + m + 'm '
  return result.substring(0, result.length - 1)

DatetoISO8601 = (obj) ->
  year = obj.getFullYear()
  month = if obj.getMonth().toString().length == 1 then '0' + (obj.getMonth() + 1).toString() else obj.getMonth() + 1
  date = if obj.getDate().toString().length == 1 then '0' + obj.getDate().toString() else obj.getDate()
  hours = if obj.getHours().toString().length == 1 then '0' + obj.getHours().toString() else obj.getHours()
  minutes = if obj.getMinutes().toString().length == 1 then '0' + obj.getMinutes().toString() else obj.getMinutes()

  "#{year}-#{month}-#{date}T#{hours}:#{minutes}"

window.style.duration =
  parse: parseDuration
  string: toDurationString

window.style.getOrCreate('utils').date =
  convert:
    to:
      iso: DatetoISO8601
