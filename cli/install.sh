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
branch="master"

stapi=""
admin=""
user=""
conn=""

# yum package installation
{
  if hash yum >/dev/null 2>&1; then
    yum -y install which newt
  fi
} >> install.log 2>&1

# whiptail configuration
MAX_HEIGHT=$(tput lines 2>/dev/null || echo 0)
MAX_WIDTH=$(tput cols 2>/dev/null || echo 0)

MAX_HEIGHT=$(( $MAX_HEIGHT / 2 ))
MAX_WIDTH=$(( $MAX_WIDTH * 3 / 4 ))

# fallback if dialog is not present
DIALOG=$(which dialog 2>/dev/null || which whiptail 2>/dev/null || which echo 2>/dev/null)
curl https://gist.githubusercontent.com/indietyp/d35983f3d943b61eb3c503e6104f4ccf/raw/886ebc08885a386aa6d61feb93fad9841b867472/.ht.dialogrc -o ~/.ht.dialogrc >/dev/null 2>&1

export LC_ALL=C
export NCURSES_NO_UTF8_ACS=1
export DIALOGRC="~/.ht.dialogrc"

if which tput >/dev/null 2>&1; then
  ncolors=$(tput colors 2>/dev/null)
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
  whiptail --title "$2" --yesno "$1" $MAX_HEIGHT $MAX_WIDTH
}

dnoti() {
  if [ "$DIALOG" = "$(which whiptail 2>/dev/null)" ]; then
    printf "${BOLD}$2: ${NORMAL}$1\n"
  elif [ $ui -eq 1 ]; then
    $DIALOG --title "$2" --infobox "$1" $MAX_HEIGHT $MAX_WIDTH
  else
    printf "${BOLD}$2: ${NORMAL}$1\n"
  fi
}

dmsg() {
  if [ $ui -eq 1 ]; then
    whiptail --title "$2" --msgbox "$1" $MAX_HEIGHT $MAX_WIDTH
  else
    printf "${BOLD}$2: ${NORMAL}$1\n"
  fi
}

dinpu() {
  whiptail --title "$2" --inputbox "$1" $MAX_HEIGHT $MAX_WIDTH "$3" 2>&1 1>&3
}

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
dcolor

cleanup() {
  log=$(tail -n 25 install.log)

  dcolor "red"
  dmsg "A criticial error occured, installation script is cleaning up.\nStacktrace of the error: (complete log can be found in install.log)\n\n$log" "[EXIT]"
  dcolor

  rm -rf $directory

  if [ $ui -eq 1 ]; then
    clear
  fi
  exit 1
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
  printf "\n\t${GREEN}+b <branch>${NORMAL}                              --branch master (defaults to master)"
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
        +b | --branch)          shift
                                branch=$1
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

  dmsg "Welcome to the automated installation script of Hawthorne. With this script we're going to install and configure all necessary tools to run HT. You may be asked to provide additional information." "[00/09] Introduction"
  {
    if [ $install -eq 0 -a $configure -eq 0 ]; then
      main
    elif [ $install -eq 1 ]; then
      install
    elif [ $configure -eq 1 ]; then
      configure
    fi
  } || cleanup

  dcolor "green"
  dmsg "Installation has been successfully finished! You can now use Hawthorne." "[00/09] Completion"

  if [ $ui -eq 1 ]; then
    clear
  fi
  dcolor
}

install() {
  exec 3>&1

  if ! [ $(id -u) -eq 0 ]; then
    dcolor "red"
    dmsg "The installation script needs to be run with root privileges." "[01/09] [ERROR] Checking Prerequisites"
    dcolor

    exit 1
  fi

  dmsg "MySQL as well as a webserver are not going to be installed." "[01/09] Checking Prerequisites"

  if [ $path -eq 0 ]; then
    directory=$(dinpu "Please choose an installation directory." "[01/09] Checking Prerequisites" $directory)
  else
    dmsg "Hawthorne will be installed at ${directory}" "[01/09] Checking Prerequisites"
  fi

  umask g-w,o-w

  dnoti "Currently installing packages with the package manager (This may take some time)" "[02/09] Installing Packages"
  {
    if hash apt >/dev/null 2>&1; then
      apt update
      apt install -y libmysqlclient-dev || {
        apt install -y default-libmysqlclient-dev
      }

      apt install -y --force-yes --fix-missing python3 python3-dev python3-pip redis-server libxml2-dev libxslt1-dev libssl-dev libffi-dev git supervisor mysql-client build-essential curl bash dialog

      curl -sL deb.nodesource.com/setup_8.x | bash -
      apt install -y nodejs

      hash git >/dev/null 2>&1 || {
        apt install git
      }

    elif hash yum >/dev/null 2>&1; then
      yum -y update
      yum -y install wget yum-utils
      yum-builddep -y python
      curl -O https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz
      tar xf Python-3.7.2.tgz
      rm Python-3.7.2.tgz
      cd Python-3.7.2
      ./configure
      make
      make install
      cd ..
      rm -rf Python-3.7.2

      yum -y install epel-release
      yum -y update
      curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -

      yum -y install redis supervisor mysql mysql-devel MariaDB-shared mysql-lib libxml2-devel libffi-devel libxslt-devel openssl-devel nodejs dialog
      systemctl start redis
      systemctl enable redis

      hash git >/dev/null 2>&1 || {
        yum -y install http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm
        yum -y install git
      }

      ln -nsf /usr/local/bin/python3 /usr/bin/python3
      ln -nsf /usr/local/bin/pip3 /usr/bin/pip3
      /usr/sbin/setsebool -P httpd_can_network_connect 1
    else
      dcolor "red"
      dmsg "The installation has been aborted. Your package manager is currently not supported. \n\n To enable support for your package manager please contact the current maintainer." "[02/09] Installing Packages"
      dcolor

      exit 1
    fi
  } >> install.log 2>&1

  DIALOG=$(which dialog)

  dnoti "Getting the codebase from the internet" "[03/09] Cloning Repository"
  {
    directory=$(python3 -c "import os; print(os.path.abspath(os.path.expanduser('$directory')))")

    if [ $local -eq 0 ]; then
      env git clone --branch $branch https://github.com/indietyp/hawthorne $directory || {
        dcolor "red"
        dmsg "Cloning the Repository failed" "[03/09] [ERROR] Cloning Repository"
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

  dnoti "Currently installing language specific packages" "[04/09] Installing Languages"
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
  exec 3>&1

  mkdir -p /var/log/hawthorne
  ln -nsf $directory/cli/helper.py /usr/bin/hawthorne
  ln -nsf $directory/cli/helper.py /usr/bin/ht
  chmod +x /usr/bin/hawthorne
  chmod +x /usr/bin/ht

  if [ "$conn" = "" ]; then
    pconn=0
  else
    pconn=1
  fi

  while true; do
    if [ $pconn -eq 0 ]; then
      conn=$(dinpu "MySQL URL \n\nFormatting: mysql://<user>:<password>@<host>:<port>/<database>\n(Reference: RFC 1808 and RFC1738 Section 3.1)" "[05/09] Database")
    fi

    conn=$(echo "$conn" | sed -nE 's#(mysql://)?(.*)#\2#p')
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

    if mysql -u $dbuser -e "CREATE DATABASE IF NOT EXISTS $dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"; then
      dcolor "green"
      dmsg "Successfully connected to the database." "[05/09] Database"
      dcolor

      break;
    else
      dcolor "red"
      dmsg "Could not connect to database with the provided credentials, please try again." "[05/09] Database"
      dcolor

      if [ $pconn -eq 1 ]; then
        exit 1
      fi
    fi
  done

  dnoti "Enabling MySQL timezone support" "[05/09] Database"
  {
    hash mysql_tzinfo_to_sql >/dev/null 2>&1 && {
      mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u $dbuser mysql
    }
  } >> install.log 2>&1


  if [ "$stapi" = "" ]; then
    stapi=$(dinpu "Your SteamAPI key" "[06/09] Steam credentials")
  fi
  if [ "$admin" = "" ]; then
    admin=$(dinpu "Your SteamID64" "[06/09] Steam credentials")
  fi
  if [ "$domain" = "" ]; then
    domain=$(dinpu "Which domain/ip is hawthorne going to be hosted on?" "[07/09] HTTP Configuration")
  fi
  if [ $nginx -eq 0 ]; then
    webserver=$(whiptail --radiolist "Choose your used http server" --title "[07/09] HTTP Configuration" $MAX_HEIGHT $MAX_WIDTH 2 "nginx" "" 1 "Apache 2" "" 0 2>&1 1>&3)
  fi

  dnoti "Setting up Hawthorne...." "[08/09] Hawthorne Initialize"
  {
    hash yum >/dev/null 2>&1 && {
      mkdir -p /etc/supervisor/conf.d/
      mkdir -p /etc/supervisord
      cp $directory/cli/configs/supervisord.default.conf /etc/supervisord/supervisord.conf

      wget https://gist.githubusercontent.com/mozillazg/6cbdcccbf46fe96a4edd/raw/2f5c6f5e88fc43e27b974f8a4c19088fc22b1bd5/supervisord.service -O /usr/lib/systemd/system/supervisord.service
      systemctl start supervisord
      systemctl enable supervisord
    }

    bind=socket
    owner=Owner
    if [ $docker -eq 1 ]; then
      owner=$ROOT
      bind=port
    fi

    hawthorne initialize --database $conn --steam $stapi --demo $demo --host $domain --secret --root $owner
    hawthorne reconfigure --supervisor --no-nginx --no-apache --gunicorn --logrotate --bind $bind
    python3 $directory/manage.py migrate
    python3 $directory/manage.py superusersteam --steamid $admin --check
    python3 $directory/manage.py collectstatic --noinput -v 0

    if [ "$webserver" = "nginx" ]; then
      hawthorne reconfigure --no-supervisor --nginx --no-apache --no-gunicorn --no-logrotate
    else
      hawthorne reconfigure --no-supervisor --no-nginx --apache --no-gunicorn --no-logrotate
    fi

    hash getenforce >/dev/null 2>&1 && {
      if [ getenforce != "Disabled" ]; then
        /usr/sbin/setsebool -P httpd_can_network_connect 1
        chcon --user system_u --type httpd_sys_content_t -Rv /local/static
      fi
    }

  } >> install.log 2>&1

  dnoti "Starting Hawthorne..." "[09/09] Supervisor"
  {
    if [ $docker -eq 1 ]; then
      export LC_ALL=en_US.UTF-8

      cd $directory
      celery -A panel worker -B -l info &> /dev/stdout &
      python3 -m gunicorn.app.wsgiapp panel.wsgi:application
    else
      supervisorctl reread
      supervisorctl update
      supervisorctl restart hawthorne
    fi
  } >> install.log 2>&1

  exec 3>&-
}

main() {
  install
  configure
}

dcolor
parser "$@"
