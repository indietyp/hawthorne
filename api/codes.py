l_to_s = lambda v: ''.join(v)
l_to_i = lambda v: int(''.join(v)) if not isinstance(v, int) else v
l_to_b = lambda v: True if ''.join(v).lower() == 'true' else False
s_to_l = lambda v: [v]

method = ['request method not allowed'], 405
valid = ['data required was not satisfied'], 417
