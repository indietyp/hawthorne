#!/bin/sh
# this is adopted from the oh-my-zsh install script

directory=/hawthorne
interactive=1
utils=0
dev=0

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
  printf "\n\t${GREEN}-n${NORMAL}   --non-interactive (not recommended)"
  printf "\n\t${GREEN}-f${NORMAL}   --full"
  printf "\n\t${YELLOW}-d${NORMAL}   --development"
  printf "\n\t${GREEN}-h${NORMAL}   --help"
}

parser() {
  while [ "$1" != "" ]; do
    case $1 in
        -n | --non-interactive) interactive=0
                                ;;
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

  while true; do
    read -p "Do you want to define a custom path? ${GREEN}(y)${NORMAL}es or ${RED}(n)${NORMAL}o: " yn
    case $yn in
        [Yy]* ) read -p "Where should hawthorne be installed? " directory; break;;
        [Nn]* ) break;;
        * ) echo "Please answer with the answers provided.";;
    esac
  done

  umask g-w,o-w

  printf "${BLUE}Installing the package requirements...${NORMAL}\n"
  if hash apt >/dev/null 2>&1; then
    apt update
    apt install -y libmysqlclient-dev || {
      apt install -y default-libmysqlclient-dev
    }

    apt install -y --force-yes --fix-missing python3 python3-dev python3-pip redis-server libxml2-dev libxslt1-dev libssl-dev libffi-dev git supervisor mysql-client build-essential

    # wget -O ruby-install-0.6.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.6.1.tar.gz
    # tar -xzvf ruby-install-0.6.1.tar.gz
    # cd ruby-install-0.6.1/
    # sudo make install --silent
    # cd ..
    # rm -rf ruby-install-0.6.1
    # rm ruby-install-0.6.1.tar.gz

    # ruby-install --system --latest ruby

    curl -sL deb.nodesource.com/setup_8.x | sudo -E bash -
    apt install -y nodejs

    if [ $utils -eq 1 ]; then
      if [ $interactive -eq 0 ]; then
        debconf-set-selections | 'mysql-server mysql-server/root_password password root'
        debconf-set-selections | 'mysql-server mysql-server/root_password_again password root'
      fi
      apt install -y --force-yew --fix-missing mysql-server nginx
    fi

  elif hash yum >/dev/null 2>&1; then
    yum -y update
    yum -y install yum-utils wget
    yum-builddep python
    curl -O https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tgz
    tar xf Python-3.6.4.tgz
    rm Python-3.6.4.tgz
    cd Python-3.6.4
    ./configure
    make
    make install
    cd ..
    rm -rf Python-3.6.4

    yum -y install epel-release
    yum -y update
    yum -y install redis
    systemctl start redis
    systemctl enable redis

    yum -y install mysql mysql-devel mysql-lib
    yum -y install libxml2-devel libffi-devel libxslt-devel openssl-devel
    yum -y install git supervisor

    curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -
    yum -y install nodejs

  else
    printf "Your package manager is currently not supported. Please contact the maintainer\n"
    printf "${BLUE}opensource@indietyp.com${NORMAL} or open an issure\n"
  fi

  # we need that toal path boi
  directory=$(python3 -c "import os; print(os.path.abspath(os.path.expanduser('$directory')))")


  hash git >/dev/null 2>&1 || {
    echo "Error: git is not installed"
    exit 1
  }

  printf "${BLUE}Cloning the project...${NORMAL}\n"
  env git clone https://github.com/indietyp/hawthorne $directory || {
    printf "${RED}Error:${NORMAL} git clone of hawthorne repo failed\n"
    exit 1
  }

  printf "${BLUE}Installing python3 dependencies...${NORMAL}\n"

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

  printf "${BLUE}Installing ruby and npm dependencies...${NORMAL}\n"
  npm install -g pug
  # coffeescript
  # gem install sass --no-user-install

  printf "${BLUE}Configuring the project...${NORMAL}\n"
  cp $directory/panel/local.default.py $directory/panel/local.py
  cp $directory/supervisor.default.conf $directory/supervisor.conf
  mkdir -p /var/log/hawthorne

  printf "\n\n${YELLOW}Database configuration:${NORMAL}\n"
  while true; do
    if [ $interactive -eq 1 ]; then
      read -p 'Host     (default: localhost):  ' dbhost
      read -p 'Port     (default: 3306):       ' dbport
      read -p 'User     (default: root):       ' dbuser
      read -p 'Database (default: hawthorne):  ' dbname
      read -p 'Password:                       ' dbpwd
    fi

    dbhost=${dbhost:-localhost}
    dbport=${dbport:-3306}
    dbuser=${dbuser:-root}
    dbname=${dbname:-hawthorne}

    if [ $interactive -eq 0 ]; then
      dbpwd=root
    fi

    export MYSQL_PWD=$dbpwd
    export MYSQL_HOST=$dbhost
    export MYSQL_TCP_PORT=$dbport

    if mysql -u $dbuser -e "CREATE DATABASE IF NOT EXISTS $dbname"; then
      printf "\n${GREEN}successfully connected to mysql and created the database.${NORMAL}\n"
      break;
    else
      printf "\n${YELLOW}I could not connected to mysql with the credentials you provided, try again.${NORMAL}\n"
    fi
  done

  printf "\n\n${YELLOW}SteamAPI configuration:${NORMAL}\n"
  if [ $interactive -eq 1 ]; then
    read -p 'Steam API Key: ' stapi
  fi

  printf "\n\n${GREEN}Just doing some file transmutation magic:${NORMAL}\n"
  # replace the stuff in the local.py and supervisor.conf file
  sed -i "s/'HOST': 'localhost'/'HOST': '$dbhost'/g" $directory/panel/local.py
  sed -i "s/'PORT': 'root'/'PORT': '$dbport'/g" $directory/panel/local.py
  sed -i "s/'NAME': 'hawthorne'/'NAME': '$dbname'/g" $directory/panel/local.py
  sed -i "s/'USER': 'root'/'USER': '$dbuser'/g" $directory/panel/local.py
  sed -i "s/'PASSWORD': ''/'PASSWORD': '$dbpwd'/g" $directory/panel/local.py

  if [ $interactive -eq 1 ]; then
    sed -i "s/SOCIAL_AUTH_STEAM_API_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'/SOCIAL_AUTH_STEAM_API_KEY = '$stapi'/g" $directory/panel/local.py
  fi

  sed -i "s#directory=<replace>#directory=$directory#g" $directory/supervisor.conf
  printf "${BLUE}Executing project setupcommands...${NORMAL}\n"
  sed -i "s/SECRET_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'/SECRET_KEY = '$(python3 $directory/manage.py generatesecret | tail -1)'/g" $directory/panel/local.py

  python3 $directory/manage.py migrate

  if [ $interactive -eq 1 ]; then
    python3 $directory/manage.py superusersteam
  fi

  # python3 $directory/manage.py compilestatic
  python3 $directory/manage.py collectstatic --noinput

  printf "${BLUE}Linking to supervisor...${NORMAL}\n"
  ln -sr $directory/supervisor.conf /etc/supervisor/conf.d/hawthorne.conf
  supervisorctl reread
  supervisorctl update
  supervisorctl restart hawthorne
  printf "Started the unix socket at: ${YELLOW}/tmp/hawthorne.sock${NORMAL}\n"

  printf "${BLUE}Linking the hawthorne command line tool...${NORMAL}\n"
  ln -s $directory/tools/toolchain.sh /usr/bin/hawthorne
  ln -s $directory/tools/toolchain.sh /usr/bin/ht
  chmod +x /usr/bin/hawthorne
  chmod +x /usr/bin/ht

  if [ $utils -eq 1 ]; then
    rm /etc/nginx/sites-enabled/hawthorne
    ln -s $directory/tools/configs/nginx.example.conf /etc/nginx/sites-enabled/hawthorne

    service nginx restart
  fi

  printf "\n\n${GREEN}You did it (Well rather I did). Everything seems to be installed.${NORMAL}\n"
  printf "Please look over the $directory/${RED}panel/local.py${NORMAL} to see if you want to configure anything. And restart the supervisor with ${YELLOW}supervisorctl restart hawthorne${NORMAL}\n"
  printf "To configure your webserver please refer to the project wiki: ${YELLOW}https://github.com/indietyp/hawthorne/wiki/Webserver-Configuration${NORMAL}\n"

  if [ $interactive -eq 0 ]; then
    printf "PLEASE RUN ${YELLOW}$directory/manage.py superusersteam${NORMAL}\n"
    printf "INSERT YOUR DEVKEY IN ${YELLOW}$directory/${RED}panel/local.py${NORMAL}\n"
  fi

}

parser
