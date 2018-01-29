def l_to_s(v):
  if v is not None:
    return ''.join(v)

  return None


def l_to_i(v):
  if v is not None:
    if isinstance(v, int):
      return v
    else:
      v = ''.join(v)
      try:
        return int(v)
      except Exception:
        return -1

  return None


def l_to_b(v):
  if v is not None:
    if isinstance(v, bool):
      return v
    else:
      v = ''.join(v)
      v = v.lower()

      if v == 'false':
        return False
      else:
        return True

  return None


def s_to_l(v):
  if v is not None:
    return [v]
  return None


method = ['request method not allowed'], 405
valid = ['data required was not satisfied'], 417
