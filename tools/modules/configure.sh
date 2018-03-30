#!/bin/sh

configure () {
  if [ -f "/hawthorne/panel/local.py" ]; then
    /usr/bin/hawthorne update
  else
    printf "${BOLD}Configuring the project...${NORMAL}\n"
    cp /hawthorne/panel/local.default.py /hawthorne/panel/local.py
    cp /hawthorne/supervisor.default.conf /hawthorne/supervisor.conf
    mkdir -p /var/log/hawthorne
    mkdir -p /tmp/sockets
    mysql -u $MYSQL_USER -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE"

    printf "\n\n${BOLD}Configuring project...${NORMAL}\n"
    # replace the stuff in the local.py and supervisor.conf file
    sed -i "s/'HOST': 'localhost'/'HOST': '$MYSQL_HOST'/g" /hawthorne/panel/local.py
    sed -i "s/'PORT': 'root'/'PORT': '$MYSQL_TCP_PORT'/g" /hawthorne/panel/local.py
    sed -i "s/'NAME': 'hawthorne'/'NAME': '$MYSQL_DATABASE'/g" /hawthorne/panel/local.py
    sed -i "s/'USER': 'root'/'USER': '$MYSQL_USER'/g" /hawthorne/panel/local.py
    sed -i "s/'PASSWORD': ''/'PASSWORD': '$MYSQL_PWD'/g" /hawthorne/panel/local.py

    if [ $dev -eq 1 ]; then
      sed -i "s/DEBUG = False/DEBUG = True/g" /hawthorne/panel/local.py
    fi

    sed -i "s#directory=<replace>#directory=/hawthorne#g" /hawthorne/supervisor.conf
    printf "${BLUE}Executing project setupcommands...${NORMAL}\n"
    sed -i "s/SECRET_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'/SECRET_KEY = '$(python3 /hawthorne/manage.py generatesecret | tail -1)'/g" /hawthorne/panel/local.py

    python3 /hawthorne/manage.py migrate
    python3 /hawthorne/manage.py compilestatic
    python3 /hawthorne/manage.py collectstatic --noinput -v 0

    printf "${BOLD}Linking to supervisor...${NORMAL}\n"
    rm -rf /etc/supervisor/conf.d/hawthorne.conf
    ln -s /hawthorne/supervisor.conf /etc/supervisor/conf.d/hawthorne.conf

    printf "${GREEN}Linking the hawthorne command line tool...${NORMAL}\n"
    rm -rf /usr/bin/hawthorne /usr/bin/ht
    ln -s /hawthorne/tools/toolchain.sh /usr/bin/hawthorne
    ln -s /hawthorne/tools/toolchain.sh /usr/bin/ht
    chmod +x /usr/bin/hawthorne
    chmod +x /usr/bin/ht
  fi

  printf "Starting at unix socket at: ${YELLOW}/tmp/hawthorne.sock${NORMAL}\n"
  cd /hawthorne
  python3 -m gunicorn.app.wsgiapp panel.wsgi:application
}

configure
