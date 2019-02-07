#!/bin/sh
# this is adopted from the oh-my-zsh install script

directory=/hawthorne
nginx=0
demo=0
dev=0
path=0
local=0
docker=0
ui=1

web="nginx"
domain=""

stapi=""
admin=""
user=""
conn=""

# whiptail configuration
MAX_HEIGHT=$(tput lines 2>/dev/null || echo 0)
MAX_WIDTH=$(tput cols 2>/dev/null || echo 0)

MAX_HEIGHT=$(( $MAX_HEIGHT / 2 ))
MAX_WIDTH=$(( $MAX_WIDTH * 3 / 4 ))

export LC_ALL=C

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

# whiptail shortcuts
dconf() {
  whiptail --yesno "$1" --title "$2" $MAX_HEIGHT $MAX_WIDTH
}

dnoti() {
  if [ $ui -eq 1 ]; then
    whiptail --infobox "$1" --title "$2" $MAX_HEIGHT $MAX_WIDTH
  else
    printf "${BOLD}$2:${NORMAL}$1\n"
  fi
}

dmsg() {
  if [ $ui -eq 1 ]; then
    whiptail --msgbox "$1" --title "$2" $MAX_HEIGHT $MAX_WIDTH
  else
    printf "${BOLD}$2:${NORMAL}$1\n"
  fi
}

dinpu() {
  whiptail --inputbox "$1" --title "$2" $MAX_HEIGHT $MAX_WIDTH "$3" 2>&1 1>&3
}

trap cleanup 1 2 3 6

dcolor() {
  if [ "x$1" = "x" ]; then
    NEWT_COLOR="brightblue"
  else
    NEWT_COLOR="$1"
  fi

  export NEWT_COLORS="
    window=cyan,${NEWT_COLOR}
    border=white,${NEWT_COLOR}
    title=white,${NEWT_COLOR}
    textbox=white,${NEWT_COLOR}
    button=black,white
    actbutton=black,red
    compactbutton=white,${NEWT_COLOR}
  "
}

cleanup() {
  log=$(tail -n 25 install.log)

  dcolor "red"
  dmsg "A criticial error occured, installation script is cleaning up.\nStacktrace of the error: (complete log can be found in install.log)\n\n$log" "[EXIT]"
  dcolor

  rm -rf $directory
}


usage() {
  printf "\nThe hawthorne installation tool is an effort to make the installation on unix based system a bit easier and automated."
  printf "\n\n${RED}Installation Modes:${NORMAL}"
  printf "\n\t${GREEN}help${NORMAL}"
  printf "\n\t${GREEN}full${NORMAL}                                     (${RED}default${NORMAL})"
  printf "\n\t${GREEN}install${NORMAL}"
  printf "\n\t${GREEN}configure${NORMAL}"
  printf "\n\n${RED}Installation Options:${NORMAL}"
  printf "\n\t${GREEN}-h${NORMAL}                                       --help"
  printf "\n\t${GREEN}-noui${NORMAL}                                    (disable UI)"
  printf "\n\n${RED}Optional Arguments:${NORMAL}"
  printf "\n\t${GREEN}+d <domain>${NORMAL}                              --domain example.com"
  printf "\n\t${GREEN}+s <steam api key>${NORMAL}                       --steam 665F388103DAF49235356BA3EFD0849E"
  printf "\n\t${GREEN}+p <path>${NORMAL}                                --path /hawthorne"
  printf "\n\t${GREEN}+h <user>:<password>@<host>/<database>${NORMAL}   --database root:12345@localhost:3306/hawthorne"
  printf "\n\t${GREEN}+l${NORMAL}                                       --local"
  printf "\n\t${GREEN}+n${NORMAL}                                       --nginx"
  printf "\n\t${GREEN}+o${NORMAL}                                       --demo"
  printf "\n"
}

parser() {
  configure=0
  install=0

  while [ "$1" != "" ]; do
    case $1 in
        -h | --help | help)               usage
                                          exit
                                          ;;
        -noui)                            ui=0
                                          ;;
        -c | --configure | configure)     configure=1
                                          ;;
        -i | --install | install)         install=1
                                          ;;
        +d | --domain)          shift
                                domain=$1
                                ;;
        +l | --local)           local=1
                                nginx=2
                                ;;
        +s | --steam)           shift
                                stapi=$1
                                ;;
        +p | --path)            shift
                                path=1
                                directory=$1
                                ;;
        +a | --admin)           shift
                                admin=$1
                                ;;
        +h | --database)        shift
                                conn=$1
                                ;;
        +f | --docker)          docker=1
                                ;;
        +n | --nginx)           nginx=1
                                ;;
        +o | --demo)            demo=1
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
  done

  dmsg "Welcome to the automated installation script of Hawthorne. With this script we're going to install and configure all necessary tools to run HT. You may be asked to provide additional information." "Introduction"

  if [ $install -eq 0 -a $configure -eq 0 ]; then
    main
  elif [ $install -eq 1 ]; then
    install
  elif [ $configure -eq 1 ]; then
    configure
  fi

  dcolor "green"
  dmsg "Installation has been successfully finished! You can now use Hawthorne." "Completion"
  dcolor
}

install() {
  exec 3>&1

  if ! [ $(id -u) -eq 0 ]; then
    dcolor "red"
    dmsg "The installation script needs to be run with root privileges." "[01/??] [ERROR] Checking Prerequisites"
    dcolor
    exit 1
  fi

  dmsg "MySQL as well as a webserver are not going to be installed." "[01/??] Checking Prerequisites"

  if [ $path -eq 0 ]; then
    directory=$(dinpu "Please choose an installation directory." "[01/??] Checking Prerequisites" $directory)
  else
    dmsg "Hawthorne will be installed at ${directory}" "[01/??] Checking Prerequisites"
  fi

  umask g-w,o-w

  dnoti "Currently installing packages with the package manager" "[02/??] Installing Packages"
  {
    if hash apt >/dev/null 2>&1; then
      apt update
      apt install -y libmysqlclient-dev || {
        apt install -y default-libmysqlclient-dev
      }

      apt install -y --force-yes --fix-missing python3 python3-dev python3-pip redis-server libxml2-dev libxslt1-dev libssl-dev libffi-dev git supervisor mysql-client build-essential curl bash

      curl -sL deb.nodesource.com/setup_8.x | bash -
      apt install -y nodejs

      hash git >/dev/null 2>&1 || {
        apt install git
      }

    elif hash yum >/dev/null 2>&1; then
      yum -y update
      yum -y install wget
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
      curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -

      yum -y install redis supervisor mysql mysql-devel mysql-lib libxml2-devel libffi-devel libxslt-devel openssl-devel nodejs
      systemctl start redis
      systemctl enable redis

      hash git >/dev/null 2>&1 || {
        yum install http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm
        yum -y install git
      }

      ln -s /usr/local/bin/python3 /usr/bin/python3
      ln -s /usr/local/bin/pip3 /usr/bin/pip3
      /usr/sbin/setsebool -P httpd_can_network_connect 1
    else
      dcolor "red"
      dmsg "The installation has been aborted. Your package manager is currently not supported. \n\n To enable support for your package manager please contact the current maintainer." "[02/??] Installing Packages"
      dcolor

      exit 1
    fi
  } >> install.log 2>&1

  dnoti "Getting the codebase from the internet" "[03/??] Cloning Repository"
  {
    directory=$(python3 -c "import os; print(os.path.abspath(os.path.expanduser('$directory')))")

    if [ $local -eq 0 ]; then
      env git clone https://github.com/indietyp/hawthorne $directory || {
        dcolor "red"
        dmsg "Cloning the Repository failed" "[03/??] [ERROR] Cloning Repository"
        dcolor

        exit 1
      }
    else
      SCRIPT=$(readlink -f "$0")
      current=$(dirname $(dirname "$SCRIPT"))

      mv "$current" "$directory"
      chmod -R +x $directory
    fi
  } >> install.log 2>&1

  dnoti "Currently installing language specific packages" "[04/??] Installing Languages"
  {
    printf "${BOLD}Installing dependencies...${NORMAL}\n"
    pip3 install -U wheel setuptools
    pip3 install cryptography || {
      wget https://bootstrap.pypa.io/get-pip.py
      python3 get-pip.py
      rm get-pip.py

      alias pip3="/usr/local/bin/pip3"
    }

    pip3 install gunicorn
    pip3 install -r $directory/requirements.txt

    npm install -g pug
  } >> install.log 2>&1

  exec 3>&-
}

configure() {
  printf "${GREEN}Configuration has been successfully started...${NORMAL}\n"
  printf "${BOLD}Copying the local only files...${NORMAL}\n"
  cp -rf $directory/panel/local.default.py $directory/panel/local.py
  cp -rf $directory/cli/configs/gunicorn.default.conf.py $directory/gunicorn.conf.py
  cp -rf $directory/cli/configs/supervisor.default.conf $directory/supervisor.conf
  mkdir -p /var/log/hawthorne

  if [ "$conn" = "" ]; then
    printf "\n\n${GREEN}Database configuration:${NORMAL}\n"
    while true; do
      read -p 'Host     (default: localhost):  ' dbhost
      read -p 'Port     (default: 3306):       ' dbport
      read -p 'User     (default: root):       ' dbuser
      read -p 'Database (default: hawthorne):  ' dbname
      read -p 'Password:                       ' dbpwd

      dbhost=${dbhost:-localhost}
      dbport=${dbport:-3306}
      dbuser=${dbuser:-root}
      dbname=${dbname:-hawthorne}

      export MYSQL_PWD=$dbpwd
      export MYSQL_HOST=$dbhost
      export MYSQL_TCP_PORT=$dbport

      if mysql -u $dbuser -e "CREATE DATABASE IF NOT EXISTS $dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"; then
        printf "\n${GREEN}Successfully connected to database.${NORMAL}\n"
        break;
      else
        printf "\n${RED}Could not connect${NORMAL} to database with provided credentials.\n"
      fi
    done
  else
    dbuser=$(echo "$conn" | sed -nE 's#^([[:alpha:]]+)[:@].*#\1#p')
    dbpwd=$(echo "$conn" | sed -nE 's#.*:([^@]+)@.*#\1#p')
    dbhost=$(echo "$conn" | sed -nE 's#.*\@([^:]+)[:/].*#\1#p')
    dbport=$(echo "$conn" | sed -nE 's#.*:([0-9]+)/.*#\1#p')
    dbname=$(echo "$conn" | sed -nE 's#.*/([[:alpha:]]+).*#\1#p')

    dbhost=${dbhost:-localhost}
    dbport=${dbport:-3306}
    dbuser=${dbuser:-root}
    dbname=${dbname:-hawthorne}

    export MYSQL_PWD=$dbpwd
    export MYSQL_HOST=$dbhost
    export MYSQL_TCP_PORT=$dbport

    if mysql -u $dbuser -e "CREATE DATABASE IF NOT EXISTS $dbname"; then
      printf "\n${GREEN}Successfully connected.${NORMAL}\n"
    else
      printf "\n${RED}Could not connect${NORMAL} to database with provided credentials. Exiting configuration\n"
      exit 1
    fi
  fi

  hash mysql_tzinfo_to_sql >/dev/null 2>&1 && {
    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u $dbuser mysql
  }

  if [ "$stapi" = "" ]; then
    printf "\n\n${GREEN}SteamAPI configuration:${NORMAL}\n"
    read -p 'Steam API Key: ' stapi
  fi

  printf "\n\n${BOLD}Setting project specific settings...${NORMAL}\n"
  sed -i "s/'HOST': 'localhost'/'HOST': '$dbhost'/g" $directory/panel/local.py
  sed -i "s/'PORT': 'root'/'PORT': '$dbport'/g" $directory/panel/local.py
  sed -i "s/'NAME': 'hawthorne'/'NAME': '$dbname'/g" $directory/panel/local.py
  sed -i "s/'USER': 'root'/'USER': '$dbuser'/g" $directory/panel/local.py
  sed -i "s/'PASSWORD': ''/'PASSWORD': '$dbpwd'/g" $directory/panel/local.py
  sed -i "s/SOCIAL_AUTH_STEAM_API_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'/SOCIAL_AUTH_STEAM_API_KEY = '$stapi'/g" $directory/panel/local.py

  if [ $demo -eq 1 ]; then
    sed -i "s/DEMO = False/DEMO = True/g" $directory/panel/local.py
  fi

  sed -i "s#directory=<replace>#directory=$directory#g" $directory/supervisor.conf

  printf "${BLUE}Setting up the project...${NORMAL}\n"
  sed -i "s/SECRET_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'/SECRET_KEY = '$(python3 $directory/manage.py generatesecret | tail -1)'/g" $directory/panel/local.py
  python3 $directory/manage.py migrate

  if [ "$admin" = "" ]; then
    python3 $directory/manage.py superusersteam --check
  else
    python3 $directory/manage.py superusersteam --steamid $admin --check
  fi

  python3 $directory/manage.py collectstatic --noinput -v 0

  if [ $nginx -eq 0 ]; then
    printf "${BOLD}Setting up the web server...${NORMAL}\n"
    while true; do
      read -p "Is your webserver ${BOLD}(A)${NORMAL}pache, ${BOLD}(N)${NORMAL}ginx or ${BOLD}(D)${NORMAL}ifferent? " yn
      case $yn in
          [Aa]* ) web="apache"
                  break;;
          [Nn]* ) break;;
          [Dd]* ) web="unspecified"
                  break;;
          * ) echo "Please answer with the choices provided.";;
      esac
    done
  fi

  if [ "$domain" = "" ]; then
    while true; do
      read -p "Is the site on an ${BOLD}(I)${NORMAL}P or ${BOLD}(D)${NORMAL}omain? " yn
      case $yn in
          [Ii]* ) domain=$(curl -sSSL "https://api.ipify.org/?format=text"); break;;
          [Dd]* ) read -p "Which (sub-)domain will hawthorne be hosted? " domain; break;;
          * ) echo "Please answer with the choices provided.";;
      esac
    done
  fi

  sed -i "s|ALLOWED_HOSTS = \[gethostname(), gethostbyname(gethostname())\]|ALLOWED_HOSTS = \['$domain'\]|g" $directory/panel/local.py

  printf "${BOLD}Setting up supervisor...${NORMAL}\n"
  cp -rf $directory/cli/configs/gunicorn.default.conf.py $directory/gunicorn.conf.py
  cp -rf $directory/cli/configs/logrotate.default /etc/logrotate.d/hawthorne

  if hash yum >/dev/null 2>&1; then
    mkdir -p /etc/supervisor/conf.d/
    mkdir -p /etc/supervisord
    cp $directory/cli/configs/supervisord.default.conf /etc/supervisord/supervisord.conf

    wget https://gist.githubusercontent.com/mozillazg/6cbdcccbf46fe96a4edd/raw/2f5c6f5e88fc43e27b974f8a4c19088fc22b1bd5/supervisord.service -O /usr/lib/systemd/system/supervisord.service
    systemctl start supervisord
    systemctl enable supervisord
  fi

  ln -sr $directory/supervisor.conf /etc/supervisor/conf.d/hawthorne.conf

  if [ $docker -eq 1 ]; then
    export LC_ALL=en_US.UTF-8

    sed -i "s#bind = 'unix:/var/run/hawthorne.sock'#bind = '0.0.0.0:8000'#g" $directory/gunicorn.conf.py
    sed -i "s#ROOT = 'root'#ROOT = '$ROOT'#g" $directory/panel/local.py

    cd $directory
    celery -A panel worker -B -l info &> /dev/stdout &
    python3 -m gunicorn.app.wsgiapp panel.wsgi:application
  else
    supervisorctl reread
    supervisorctl update
    supervisorctl restart hawthorne

    printf "${BOLD}Setting up the toolchain...${NORMAL}\n"
    ln -s $directory/cli/helper.py /usr/bin/hawthorne
    ln -s $directory/cli/helper.py /usr/bin/ht
    chmod +x /usr/bin/hawthorne
    chmod +x /usr/bin/ht

    if [ $nginx -eq 1 ]; then
      rm /etc/nginx/sites-enabled/hawthorne
      ln -s $directory/cli/configs/nginx.example.conf /etc/nginx/sites-enabled/hawthorne

      service nginx restart
    fi

    printf "\n\n${GREEN}The installation tool has finished the configuration process${NORMAL}\n"
    printf "Please look over the $directory/${RED}panel/local.py${NORMAL} for additional configuration options. You can restart hawthorne with ${YELLOW}supervisorctl restart hawthorne${NORMAL}\n"
    printf "For additional information about the configuration please refer to ${YELLOW}https://docs.hawthornepanel.org/#/getting-started?id=web-server-configuration${NORMAL}\n"

    if [ $nginx -ne 2 ]; then
      echo "$web"
      printf "${GREEN}These example configurations have been specificially generated for your system, they might need some tweaking: ${NORMAL}\n\n\n"
      if [ "$web" = "nginx" ]; then
        sed -i "s/server_name example.com;/server_name '$domain';/g" $directory/cli/configs/nginx.example.conf
      elif [ "$web" = "apache" ]; then
        sed -i "s#bind = 'unix:/var/run/hawthorne.sock'#bind = '127.0.0.1:8000'#g" $directory/gunicorn.conf.py
        sed -i "s/ServerName example.com/ServerName '$domain'/g" $directory/cli/configs/apache.example.conf
      fi
    fi
  fi

  printf "Without the help of our platinum patreons this wouldn't have been possible. Thank you ${RED}Xypherium${DEFAULT}\n"
}

main() {
  install
  configure
}

dcolor
parser "$@"
