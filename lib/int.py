def shorten(value):
  for i in ['', 'T', 'M', 'B', 'T']:
    if value < 1000:
      identifier = i
      break
    value = value // 1000

  return '{:0d}{}'.format(value, identifier)
