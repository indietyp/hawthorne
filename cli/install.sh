#!/bin/sh
# this is adopted from the oh-my-zsh install script

directory=/hawthorne
nginx=0
demo=0
dev=0
path=0
local=0
docker=0
redis=1
ui=1

web="nginx"
domain=""
branch="master"

stapi=""
admin=""
user=""
conn=""
distro="$(cat /etc/os-release | grep '^ID=' | head -n 1 | sed -nE 's/^ID=(\")?([^\"]*?)(\")?/\2/p')"

# additional package installation
{
  if hash apt >/dev/null 2>&1; then
    apt update
    if [ "$(apt-cache show mariadb-server | grep Version | head -n 1 | sed -nE 's/.*\:([0-9]+\.[0-9]+).*/\1/p')" != "10.3" ]; then
      apt install software-properties-common dirmngr
      apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
      touch /etc/apt/sources.list.d/mariadb.list

      echo "# MariaDB 10.3" >> /etc/apt/sources.list.d/mariadb.list

      distro="$(lsb_release -i | cut -f2 | tr '[[:upper:]]' '[[:lower:]]')"
      codename="$(lsb_release -c | cut -f2 | tr '[[:upper:]]' '[[:lower:]]')"

      echo "deb [arch=amd64,i386,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.3/$distro $codename main" >> /etc/apt/sources.list.d/mariadb.list
      echo "deb-src http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.3/$distro $codename main" >> /etc/apt/sources.list.d/mariadb.list

      apt update
    fi

    apt install -y lsof
  elif hash yum >/dev/null 2>&1; then
    yum -y update
    yum -y install which newt lsof
  fi
} >> install.log 2>&1

# whiptail configuration
MAX_HEIGHT=$(tput lines 2>/dev/null || echo 0)
MAX_WIDTH=$(tput cols 2>/dev/null || echo 0)

MAX_HEIGHT=$(( $MAX_HEIGHT / 2 ))
MAX_WIDTH=$(( $MAX_WIDTH * 3 / 4 ))

export LANG=C.UTF-8
export LC_ALL=C.UTF-8


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
  printf "${BOLD}$2: ${NORMAL}$1\n"
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

  if [ $? -eq 1 ]; then
    exit 1
  fi
}

dyeno() {
  whiptail --title "$2" --yesno "$1" $MAX_HEIGHT $MAX_WIDTH 2>&1 1>&3; echo $?
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
  printf "\n\n${RED}Optional Arguments:${NORMAL}"
  printf "\n\t${GREEN}+b <branch>${NORMAL}                              --branch master (defaults to master)"
  printf "\n\t${GREEN}+d <domain>${NORMAL}                              --domain example.com"
  printf "\n\t${GREEN}+s <steam api key>${NORMAL}                       --steam 665F388103DAF49235356BA3EFD0849E"
  printf "\n\t${GREEN}+p <path>${NORMAL}                                --path /hawthorne"
  printf "\n\t${GREEN}+h <user>:<password>@<host>/<database>${NORMAL}   --database root:12345@localhost:3306/hawthorne"
  printf "\n\t${GREEN}+l${NORMAL}                                       --local"
  printf "\n\t${GREEN}+n${NORMAL}                                       --nginx"
  printf "\n\t${GREEN}+o${NORMAL}                                       --demo"
  printf "\n\t${GREEN}--headless${NORMAL}                               (disable UI)"
  printf "\n\t${GREEN}--no-redis${NORMAL}                               (remove redis from installation)"
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
        --headless)             ui=0
                                ;;
        --no-redis)             redis=0
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

  if [ $ui -eq 1 ]; then
    if ! [ "$(lsof -i:80,443 -sTCP:LISTEN -P -n)" ]; then
      pnginx=$(dyeno "A webserver doesn't seem to be installed or running. Do you want Hawthorne to install nginx for you?" "[01/09] Checking Prerequisites")

      if [ $pnginx -eq 0 ]; then
        dnoti "Installing nginx (This may take some time)" "[01/09] Checking Prerequisites"
        nginx=1
        {
          if hash apt >/dev/null 2>&1; then
            apt install -y nginx
          elif hash yum >/dev/null 2>&1; then
            yum -y install nginx
          fi
        } >> install.log 2>&1
      fi
    fi

    if ! [ "$(lsof -i:3306 -sTCP:LISTEN -P -n)" ]; then
      pmysql=$(dyeno "MySQL/MariaDB don't seem to be installed or running. Do you want Hawthorne to install MySQL/MariaDB for you?" "[01/09] Checking Prerequisites")

      if [ $pmysql -eq 0 ]; then
        dnoti "Installing and configuring MySQL/MariaDB (This may take some time)" "[01/09] Checking Prerequisites"

        PASSWORD=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

        echo $PASSWORD > ~/mysql.credentials.txt
        dmsg "MySQL/MariaDB autogenerated password is $PASSWORD, it has been saved to ~/mysql.credentials.txt. it is highly advised to delete the file after the installation finished."

        {
          if hash apt >/dev/null 2>&1; then
            export DEBIAN_FRONTEND="noninteractive"

            mkdir -p /root/src
            touch /root/src/debconf.txt
            echo "mariadb-server mysql-server/root_password password ${PASSWORD}" >> /root/src/debconf.txt
            echo "mariadb-server mysql-server/root_password_again password ${PASSWORD}" >> /root/src/debconf.txt

            debconf-set-selections /root/src/debconf.txt
            apt install -y mariadb-server

            export MYSQL_PWD=$dbpwd
            echo "
              use mysql;
              UPDATE user SET password=PASSWORD('${PASSWORD}') WHERE User='root';
              UPDATE user SET plugin='mysql_native_password';
              FLUSH PRIVILEGES;
            " | mysql -uroot
          elif hash yum >/dev/null 2>&1; then
            yum -y install mariadb-server expect

            SECURE_MYSQL=$(expect -c "
            set timeout 10
            spawn mysql_secure_installation

            expect \"Enter current password for root (enter for none):\"
            send -- \"\r\"

            expect \"Change the root password?\"
            send -- \"y\r\"

            expect "New password:"
            send -- "${PASSWORD}\r"

            expect "Re-enter new password:"
            send -- "${PASSWORD}\r"

            expect \"Remove anonymous users?\"
            send -- \"y\r\"

            expect \"Disallow root login remotely?\"
            send -- \"y\r\"

            expect \"Remove test database and access to it?\"
            send -- \"y\r\"

            expect \"Reload privilege tables now?\"
            send -- \"y\r\"

            expect eof
            ")

            echo $SECURE_MYSQL
          fi

          conn="mysql://root:$PASSWORD@localhost/hawthorne"
        } >> install.log 2>&1

        unset PASSWORD
      fi
    fi
  fi

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
      apt install -y libmariadb-dev
      ln -s /usr/bin/mariadb_config /usr/bin/mysql_config

      apt install -y --force-yes --fix-missing python3 python3-dev python3-pip libxml2-dev libxslt1-dev libssl-dev libffi-dev git supervisor mariadb-client build-essential curl bash

      if [ $redis -eq 1 ]; then
        apt install -y redis-server
      fi

      curl -sL deb.nodesource.com/setup_8.x | bash -
      apt install -y nodejs

      hash git >/dev/null 2>&1 || {
        apt install git
      }

    elif hash yum >/dev/null 2>&1; then
      yum -y update
      yum -y install wget yum-utils

      yum -y install https://centos7.iuscommunity.org/ius-release.rpm
      yum -y install python37u

      yum -y install epel-release
      yum -y update
      curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -

      yum -y install supervisor MariaDB MariaDB-devel MariaDB-shared MariaDB-lib libxml2-devel libffi-devel libxslt-devel openssl-devel nodejs

      if [ $redis -eq 1 ]; then
        yum -y install redis
        systemctl start redis
        systemctl enable redis
      fi

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
  ln -sf "$directory/cli/helper.py" /usr/bin/hawthorne
  ln -sf "$directory/cli/helper.py" /usr/bin/ht
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
  else
    webserver="nginx"
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

    if [ $webserver = "Apache 2" ]; then
      bind=port
    else
      bind=socket
    fi

    owner=Owner
    if [ $docker -eq 1 ]; then
      owner=$ROOT
      bind=container
    fi

    hawthorne initialize --database $conn --steam $stapi --demo $demo --host $domain --secret --root $owner
    hawthorne reconfigure --supervisor --no-nginx --no-apache --gunicorn --logrotate --bind $bind
    python3 $directory/manage.py migrate
    python3 $directory/manage.py superusersteam --steamid $admin --check
    python3 $directory/manage.py collectstatic --noinput -v 0

    if [ $docker -eq 1 ]; then
      hawthorne reconfigure --no-supervisor --no-nginx --no-apache --no-gunicorn --no-logrotate
    elif [ "$webserver" = "nginx" ]; then
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
      supervisorctl restart hawthorne:*
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
