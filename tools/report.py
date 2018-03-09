import sys
import platform


# https://stackoverflow.com/questions/136168/get-last-n-lines-of-a-file-with-python-similar-to-tail
def tail(f, lines=20):
  total_lines_wanted = lines

  BLOCK_SIZE = 1024
  f.seek(0, 2)
  block_end_byte = f.tell()
  lines_to_go = total_lines_wanted
  block_number = -1
  blocks = []
  while lines_to_go > 0 and block_end_byte > 0:
    if (block_end_byte - BLOCK_SIZE > 0):
      # read the last block we haven't yet read
      f.seek(block_number * BLOCK_SIZE, 2)
      blocks.append(f.read(BLOCK_SIZE))
    else:
      # file too small, start from begining
      f.seek(0, 0)
      # only read what was not read
      blocks.append(f.read(block_end_byte))
    lines_found = blocks[-1].count('\n')
    lines_to_go -= lines_found
    block_end_byte -= BLOCK_SIZE
    block_number -= 1
  all_read_text = ''.join(reversed(blocks))
  return '\n'.join(all_read_text.splitlines()[-total_lines_wanted:])


uname = platform.uname()
with open('/var/log/hawthorne/debug.log', 'r') as log:
  traceback = tail(log, 100)

payload = {
    'path': sys.path,
    'version': platform.python_version(),
    'system': {x: uname.__getattribute__(x) for x in uname._fields},
    'distro': '-'.join(platform.linux_distribution()),
    'log': traceback
}

print(payload)
