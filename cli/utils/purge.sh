#!/bin/sh

directory=/hawthorne
if which tput >/dev/null 2>&1; then
  ncolors=$(tput colors)
fi

if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  BLUE="$(tput setaf 4)"
  BOLD="$(tput bold)"
  NORMAL="$(tput sgr0)"
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  BOLD=""
  NORMAL=""
fi

set -e

printf "Welcome to the ${RED}purge${DEFAULT}. \n"
printf "${YELLOW}PLEASE BE CAUTIOUS THIS CAN HARM YOUR MACHINE PERMANENTLY${DEFAULT}. \n\n"
while true; do
  read -p "Are you sure you want to delete everything? ${GREEN}(y)${NORMAL}es or ${RED}(n)${NORMAL}o: " yn
  case $yn in
      [Yy]* ) break;;
      [Nn]* ) exit 1;;
      * ) echo "Please answer with the choices provided.";;
  esac
done

while true; do
  read -p "Was HT installed on a custom path?? ${GREEN}(y)${NORMAL}es or ${RED}(n)${NORMAL}o: " yn
  case $yn in
      [Yy]* ) read -p "Where was HT installed? " directory; break;;
      [Nn]* ) break;;
      * ) echo "Please answer with the choices provided.";;
  esac
done

rm -r /static/local
rm -r /var/log/hawthorne
rm -r $directory
rm /usr/bin/hawthorne
rm /usr/bin/ht
