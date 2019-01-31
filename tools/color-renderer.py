import colorsys
import math
import re

from PIL import Image, ImageDraw, ImageFont


def step(target, repetitions=1):
  _, rgba = target.split(' = ')

  rgba = re.findall(r'rgba\((\d+), (\d+), (\d+), ([\d\.]+)(?:.*)?\)', rgba)[0]
  rgba = [float(x) for x in rgba]
  r, g, b, a = rgba

  lum = math.sqrt(.241 * r + .691 * g + .068 * b)

  h, s, v = colorsys.rgb_to_hsv(r, g, b)

  h2 = int(h * repetitions)
  # lum2 = int(lum * repetitions)
  v2 = int(v * repetitions)

  if h2 % 2 == 1:
    v2 = repetitions - v2
    lum = repetitions - lum

  return (h2, lum, v2)


with open('colors.txt') as file:
  contents = file.read()

colors = contents.split('\n')[:-1]
img = Image.new('RGBA', (512, len(colors) * 255), (0, 0, 0, 0))

pointer = 0
plane = ImageDraw.Draw(img)
fnt = ImageFont.truetype(font='~/Library/Fonts/Lato-Regular.ttf', size=20)

colors.sort(key=lambda x: step(x, 8))
for color in colors:
  name, rgba = color.split(' = ')

  rgba = re.findall(r'rgba\((\d+), (\d+), (\d+), ([\d\.]+)(?:.*)?\)', rgba)[0]
  rgba = [float(x) for x in rgba]
  rgba[-1] = rgba[-1] * 255
  rgba = tuple([int(x) for x in rgba])
  plane.rectangle((256, pointer * 255, 512, (pointer + 1) * 255), fill=rgba)

  rgbav2 = list(rgba)
  rgbav2[-1] = 255
  rgbav2 = tuple(rgbav2)
  plane.rectangle((0, pointer * 255, 256, (pointer + 1) * 255), fill=rgbav2)

  x = 10
  y = pointer * 255

  for i in range(3):
    plane.text((x - i, y), name, font=fnt, fill=(0, 0, 0, 255))
    plane.text((x + i, y), name, font=fnt, fill=(0, 0, 0, 255))
    plane.text((x, y - i), name, font=fnt, fill=(0, 0, 0, 255))
    plane.text((x, y + i), name, font=fnt, fill=(0, 0, 0, 255))

    plane.text((x - i, y - i), name, font=fnt, fill=(0, 0, 0, 255))
    plane.text((x + i, y - i), name, font=fnt, fill=(0, 0, 0, 255))
    plane.text((x - i, y + i), name, font=fnt, fill=(0, 0, 0, 255))
    plane.text((x + i, y + i), name, font=fnt, fill=(0, 0, 0, 255))
  plane.text((x, y), name, fill=(255, 255, 255, 255), font=fnt)

  pointer += 1

img.save('colors.png')
