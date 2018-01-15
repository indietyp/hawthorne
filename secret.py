import random
import string

output = ''
for _ in range(50):
  output += random.choice(string.printable[:-6])

print('This key just got randomly generated, set the current secret key with this one below: [This is only needed once]')
print(output)
