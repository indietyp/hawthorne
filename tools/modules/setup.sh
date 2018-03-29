#!/bin/sh

setup () {
  printf "${BLUE}Installing the package requirements...${NORMAL}\n"
  if hash apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y libmysqlclient-dev || {
      apt-get install -y default-libmysqlclient-dev
    }

    apt-get install -y software-properties-common
    apt-get update
    apt-get install -y -q -o=Dpkg::Use-Pty=0 gcc g++ python3 python3-dev python3-pip redis-server libxml2-dev libxslt1-dev libssl-dev libffi-dev git supervisor mysql-client build-essential ruby2.4 ruby2.4-dev ruby-switch
    ruby-switch --set ruby2.4

    curl -sL deb.nodesource.com/setup_8.x | bash -
    apt-get install -y -q -o=Dpkg::Use-Pty=0 nodejs

    hash git >/dev/null 2>&1 || {
      printf "${YELLOW}Git not preinstalled. Reinstalling...${NORMAL}\n"
      apt-get install -y -q -o=Dpkg::Use-Pty=0 git
    }

  else
    printf "Your package manager is currently not supported. Please contact the maintainer\n"
    printf "${BLUE}opensource@indietyp.com${NORMAL} or open an issue\n"
  fi

  # we need that toal path boi
  echo_supervisord_conf > /etc/supervisord.conf
  directory=$(python3 -c "import os; print(os.path.abspath(os.path.expanduser('$directory')))")

  printf "${BOLD}Cloning the project...${NORMAL}\n"
  rm -rf $directory
  env git clone -b pages https://github.com/indietyp/hawthorne $directory || {
    printf "${RED}Error:${NORMAL} git clone of hawthorne repo failed\n"
    exit 1
  }

  printf "${BOLD}Installing dependencies...${NORMAL}\n"
  pip3 install cryptography || {
    printf "${BOLD}Too old pip3 version... upgrading${NORMAL}\n"
    apt-get install -y wget
    wget https://bootstrap.pypa.io/get-pip.py
    python3 get-pip.py
    rm get-pip.py

    alias pip3="/usr/local/bin/pip3"
  }

  redis-server --daemonize yes
  pip3 install gunicorn
  pip3 install -r $directory/requirements.txt

  npm install -g --quiet pug

  npm install -g --quiet coffeescript
  gem install -q sass --no-user-install
}

setup
