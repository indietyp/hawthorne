#! /bin/bash

while read p; do
  convert -size $p"x"$p favicon.svg $p".png"
done <sizes.txt
