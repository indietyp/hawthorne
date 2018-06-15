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
    git fetch

    printf "${GREEN}Pulling changes.\n${NORMAL}"
    # https://stackoverflow.com/a/3278427/9077988
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "$UPSTREAM")
    BASE=$(git merge-base @ "$UPSTREAM")

    if [ $LOCAL = $REMOTE ]; then
      printf "${GREEN} System is already up-to-date${NORMAL} - good job!\n\n"
      exit 1
    fi

    git pull

    printf "${GREEN}Checking dependencies and updating components.\n${NORMAL}"
    pip3 install -U -r requirements.txt
    python3 manage.py migrate
    python3 manage.py collectstatic --noinput

    printf "${GREEN}Recreating permissions.\n${NORMAL}"
    cat $dir/cli/utils/permission_delete.py | python3 manage.py shell
    echo "ALTER TABLE auth_permission AUTO_INCREMENT = 1;" | python3 manage.py dbshell
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
  echo "The hawthorne toolchain is an effort to make updating, reporting and fixing hawthorne easier."
  echo ""
  echo "Commands that are currently supported:"
  echo "    ${GREEN}help${NORMAL}    - What you see here."
  echo "    ${GREEN}update${NORMAL}  - Update hawthorne to the current version."
  echo "    ${GREEN}report${NORMAL}  - Report a problem to the maintainer"
  echo "    ${GREEN}verify${NORMAL}  - Verifies the hawthorne installation to ensure a safe update process"
  echo "    ${GREEN}version${NORMAL} - Checks if a new version for hawthorne is available."
  echo ""
}

report () {
  printf "${YELLOW}Sending the report to the maintainer...\n"

  cd $dir
  python3 manage.py report
}

verify () {
  if git diff-index --quiet HEAD --; then
    printf "${GREEN}You are good to go!${NORMAL}"
  else
    printf "${RED}You are not compatible with remote branch.${NORMAL}\n"

    while true; do
      read -p "Do you want to stash you custom changes? ${GREEN}(y)${NORMAL}es or ${RED}(n)${NORMAL}o: " yn
      case $yn in
          [Yy]* ) git stash; printf "${GREEN}You are now compatible with the remote branch again!${NORMAL}"; break;;
          [Nn]* ) break;;
          * ) echo "Please answer with the answers provided.";;
      esac
    done
  fi
}

version () {
  printf "${YELLOW}Checking your current version${NORMAL}"
  git fetch >/dev/null 2>&1

  upstream=$(git describe origin/master --abbrev=0 --tags --match="v*")
  local=$(git describe --abbrev=0 --tags --match="v*")

  if [ "$upstream" != "$local" ]; then
    printf "\n\nYou really should ${GREEN}update${NORMAL}! Your current version is ${BLUE}$local${NORMAL}, the lastest version is ${BLUE}$upstream${NORMAL}.\n"
  else
    printf "\n\nYou are ${GREEN}up-to-date${NORMAL}!\n(btw you are on version ${BLUE}$local${NORMAL} right now.)\n"
  fi
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
        r|report)
            report
            exit 1
            ;;
        v|version)
            version
            exit 1
            ;;
        verify)
            verify
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
