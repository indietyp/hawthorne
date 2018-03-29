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

  if [ $utils -ne 1 ]; then
    printf "${RED}You still need to install a webserver of your choosing and provide a mysql server. ${NORMAL}\n\n"
  else
    printf "${RED}You chose the full installation, that installs nginx and mysql-server.${NORMAL}\n\n"
  fi

  printf "Everything will be configured by itelf.\n"
  printf "The configured installation path used will be ${GREEN}${directory}${NORMAL}\n"
  umask g-w,o-w

  printf "${BLUE}Installing the package requirements...${NORMAL}\n"
  if hash apt >/dev/null 2>&1; then
    apt update
    apt install -y libmysqlclient-dev || {
      apt install -y default-libmysqlclient-dev
    }

    apt install -y -q -o=Dpkg::Use-Pty=0 python3 python3-dev python3-pip redis-server libxml2-dev libxslt1-dev libssl-dev libffi-dev git supervisor mysql-client build-essential

    if [ $dev -eq 1 ]; then
      wget -O ruby-install-0.6.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.6.1.tar.gz
      tar -xzvf ruby-install-0.6.1.tar.gz
      cd ruby-install-0.6.1/
      sudo make install --silent
      cd ..
      rm -rf ruby-install-0.6.1
      rm ruby-install-0.6.1.tar.gz
    fi


    curl -sL deb.nodesource.com/setup_8.x | sudo -E bash -
    apt install -y -q -o=Dpkg::Use-Pty=0 nodejs

    if [ $utils -eq 1 ]; then
      apt install -y -q -o=Dpkg::Use-Pty=0 --force-yes --fix-missing mysql-server nginx
    fi

    hash git >/dev/null 2>&1 || {
      printf "${YELLOW}Git not preinstalled. Reinstalling...${NORMAL}\n"
      apt install -q -o=Dpkg::Use-Pty=0 git
    }

  else
    printf "Your package manager is currently not supported. Please contact the maintainer\n"
    printf "${BLUE}opensource@indietyp.com${NORMAL} or open an issue\n"
  fi

  # we need that toal path boi
  directory=$(python3 -c "import os; print(os.path.abspath(os.path.expanduser('$directory')))")

  printf "${BOLD}Cloning the project...${NORMAL}\n"
  env git clone -b pages https://github.com/indietyp/hawthorne $directory || {
    printf "${RED}Error:${NORMAL} git clone of hawthorne repo failed\n"
    exit 1
  }

  printf "${BOLD}Installing dependencies...${NORMAL}\n"
  pip3 install cryptography || {
    printf "${BOLD}Too old pip3 version... upgrading${NORMAL}\n"
    apt install -y wget
    wget https://bootstrap.pypa.io/get-pip.py
    python3 get-pip.py
    rm get-pip.py

    alias pip3="/usr/local/bin/pip3"
  }

  pip3 install gunicorn
  pip3 install -r $directory/requirements.txt
  if [ $dev -eq 1 ]; then
    pip3 install -r $directory/requirements.dev.txt
  fi

  npm install -g --quiet pug

  if [ $dev -eq 1 ]; then
    npm install -g --quiet coffeescript
    gem install -q sass --no-user-install
  fi

  printf "${BOLD}Configuring the project...${NORMAL}\n"
  cp $directory/panel/local.default.py $directory/panel/local.py
  cp $directory/supervisor.default.conf $directory/supervisor.conf
  mkdir -p /var/log/hawthorne
  mkdir -p /tmp/sockets
  mysql -u $MYSQL_USER -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE"

  printf "\n\n${BOLD}Configuring project...${NORMAL}\n"
  # replace the stuff in the local.py and supervisor.conf file
  sed -i "s/'HOST': 'localhost'/'HOST': '$dbhost'/g" $directory/panel/local.py
  sed -i "s/'PORT': 'root'/'PORT': '$dbport'/g" $directory/panel/local.py
  sed -i "s/'NAME': 'hawthorne'/'NAME': '$dbname'/g" $directory/panel/local.py
  sed -i "s/'USER': 'root'/'USER': '$dbuser'/g" $directory/panel/local.py
  sed -i "s/'PASSWORD': ''/'PASSWORD': '$dbpwd'/g" $directory/panel/local.py

  if [ $dev -eq 1 ]; then
    sed -i "s/DEBUG = False/DEBUG = True/g" $directory/panel/local.py
  fi

  sed -i "s#directory=<replace>#directory=$directory#g" $directory/supervisor.conf
  printf "${BLUE}Executing project setupcommands...${NORMAL}\n"
  sed -i "s/SECRET_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'/SECRET_KEY = '$(python3 $directory/manage.py generatesecret | tail -1)'/g" $directory/panel/local.py

  python3 $directory/manage.py migrate
  python3 $directory/manage.py compilestatic
  python3 $directory/manage.py collectstatic --noinput -v 0

  printf "${BOLD}Linking to supervisor...${NORMAL}\n"
  ln -sr $directory/supervisor.conf /etc/supervisor/conf.d/hawthorne.conf
  supervisorctl reread
  supervisorctl update
  supervisorctl restart hawthorne
  printf "Started the unix socket at: ${YELLOW}/tmp/hawthorne.sock${NORMAL}\n"

  printf "${GREEN}Linking the hawthorne command line tool...${NORMAL}\n"
  ln -s $directory/tools/toolchain.sh /usr/bin/hawthorne
  ln -s $directory/tools/toolchain.sh /usr/bin/ht
  chmod +x /usr/bin/hawthorne
  chmod +x /usr/bin/ht
}

parser
