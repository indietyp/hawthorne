#!/bin/sh
# this is adopted from the oh-my-zsh install script

directory=/hawthorne
interactive=1
utils=0
dev=0

web="nginx"
domain=""

stapi=""
user=""
conn=""

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

cleanup() {
  # I AM THE CLEANUP CREW DO NOT MIND ME ^-^
  printf "${RED}Installation failed... Cleaning up${NORMAL}\n"
  rm -rf $directory
}

usage() {
  printf "\nThe hawthorne installation tool is an effort to make installation easier."
  printf "\n\nParameters that are currently supported:"
  printf "\n\t${GREEN}-f${NORMAL}   --full"
  printf "\n\t${YELLOW}-d${NORMAL}   --development"
  printf "\n\t${GREEN}-h${NORMAL}   --help"
}

parser() {
  while [ "$1" != "" ]; do
    case $1 in
        -f | --full)            utils=1
                                ;;
        -d | --development)     dev=1
                                ;;
        -h | --help | help)     usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
  done
  main || {
    printf "${RED}Detected problem, cleaning up.${NORMAL}\n"
    cleanup
  }

}

main() {
  # Use colors, but only if connected to a terminal, and that terminal
  # supports them.
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

  # Only enable exit-on-error after the non-critical colorization stuff,
  # which may fail on systems lacking tput or terminfo
  set -e

  if ! [ $(id -u) = 0 ];
    then echo "Please run as ${RED}root${NORMAL}"
    exit 1
  fi

  export LC_ALL=C

  printf "${YELLOW}This is the automatic and guided installation. ${NORMAL}\n"


  printf "Everything will be configured by itelf.\n"
  printf "The configured installation path used will be ${GREEN}${directory}${NORMAL}\n"
  umask g-w,o-w

  source $directory/panel/modules/setup.sh
  setup

  source $directory/panel/modules/configured.sh
  configure
}

parser
