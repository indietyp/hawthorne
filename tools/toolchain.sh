#!/bin/sh

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

dir=$(cd $(dirname $(readlink $([ $(uname | tr '[:upper:]' '[:lower:]') = linux* ] && echo "-f") $0)); pwd -P)
dir=$(dirname "$dir")

update () {
    if ! [ $(id -u) = 0 ];
      then echo "Please run as ${RED}root${NORMAL}"
      exit 1
    fi

    cd $dir

    printf "${GREEN}Pulling changes.\n${NORMAL}"
    git pull

    printf "${GREEN}Checking dependencies and executing Django related things.\n${NORMAL}"
    pip3 install -r requirements.txt
    python3 manage.py migrate
    python3 manage.py collectstatic --noinput

    cat $dir/tools/utils/permission_delete.py | python3 manage.py shell
    python3 manage.py migrate --run-syncdb

    hash supervisorctl >/dev/null 2>&1 || {
        printf "${YELLOW}Was unable to detect supervisor - not attempting to restart wsgi\n${NORMAL}"
        exit 1
    }

    printf "${GREEN}Restarting supervisor\n${NORMAL}"
    supervisorctl reread
    supervisorctl update
    supervisorctl restart hawthorne

    printf "${GREEN}Success! :+1:\n${NORMAL}"
}

usage () {
    echo "The hawthorne toolchain is an effort to make updating and fixing easier."
    echo ""
    echo "Commands that are currently supported:"
    echo "\t${GREEN}help${NORMAL}   - What you see here."
    echo "\t${GREEN}update${NORMAL} - Update hawthorne to the current version."
    echo ""
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        h|help)
            usage
            exit 1
            ;;
        u|update)
            update
            exit 1
            ;;
        *)
            printf "${RED}ERROR${NORMAL}: unknown parameter \"${GREEN}$PARAM${NORMAL}\"\n\n"
            usage
            exit 1
            ;;
    esac
    shift
done

echo "Well this is awkward... Here are the commands you might need.\n\n"
usage
