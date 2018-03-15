#!/bin/sh

dir=/hawthorne

printf "Everything will be configured by itelf.\n"
printf "The configured installation path used will be ${dir}\n"

while true; do
  read -p "Do you want to define a custom path? (y)es or (n)o: " yn
  case $yn in
      [Yy]* ) read -p "Where should hawthorne be installed? " dir; break;;
      [Nn]* ) break;;
      * ) echo "Please answer with the answers provided.";;
  esac
done

dir=/hawthorne

dir=$(python3 -c "import os; print(os.path.abspath(os.path.expanduser('$dir')))")
printf $dir
