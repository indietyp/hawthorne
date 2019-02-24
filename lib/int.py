def shorten(value):
  for i in ['', 'T', 'M', 'B', 'T']:
    if value < 100:
      identifier = i
      break
    value = value // 100

  return '{:0d}{}'.format(value, identifier)
