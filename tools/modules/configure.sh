configure () {
  if [ -e $directory/panel/local.py ]; then
    /usr/bin/hawthorne update
  else
    printf "${BOLD}Configuring the project...${NORMAL}\n"
    cp $directory/panel/local.default.py $directory/panel/local.py
    cp $directory/supervisor.default.conf $directory/supervisor.conf
    mkdir -p /var/log/hawthorne
    mkdir -p /tmp/sockets
    mysql -u $MYSQL_USER -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE"

    printf "\n\n${BOLD}Configuring project...${NORMAL}\n"
    # replace the stuff in the local.py and supervisor.conf file
    sed -i "s/'HOST': 'localhost'/'HOST': '$MYSQL_HOST'/g" $directory/panel/local.py
    sed -i "s/'PORT': 'root'/'PORT': '$MYSQL_TCP_PORT'/g" $directory/panel/local.py
    sed -i "s/'NAME': 'hawthorne'/'NAME': '$MYSQL_DATABASE'/g" $directory/panel/local.py
    sed -i "s/'USER': 'root'/'USER': '$MYSQL_USER'/g" $directory/panel/local.py
    sed -i "s/'PASSWORD': ''/'PASSWORD': '$MYSQL_PWD'/g" $directory/panel/local.py

    if [ $dev -eq 1 ]; then
      sed -i "s/DEBUG = False/DEBUG = True/g" $directory/panel/local.py
    fi

    sed -i "s#directory=<replace>#directory=$directory#g" $directory/supervisor.conf
    printf "${BLUE}Executing project setupcommands...${NORMAL}\n"
    sed -i "s/SECRET_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'/SECRET_KEY = '$(python3 $directory/manage.py generatesecret | tail -1)'/g" $directory/panel/local.py


    printf "${BOLD}Linking to supervisor...${NORMAL}\n"
    rm -rf /etc/supervisor/conf.d/hawthorne.conf
    ln -s $directory/supervisor.conf /etc/supervisor/conf.d/hawthorne.conf

    printf "${GREEN}Linking the hawthorne command line tool...${NORMAL}\n"
    rm -rf /usr/bin/hawthorne /usr/bin/ht
    ln -s $directory/tools/toolchain.sh /usr/bin/hawthorne
    ln -s $directory/tools/toolchain.sh /usr/bin/ht
    chmod +x /usr/bin/hawthorne
    chmod +x /usr/bin/ht
  fi
  python3 $directory/manage.py migrate
  python3 $directory/manage.py compilestatic
  python3 $directory/manage.py collectstatic --noinput -v 0

  supervisorctl reread
  supervisorctl update
  supervisorctl restart hawthorne
  printf "Started the unix socket at: ${YELLOW}/tmp/hawthorne.sock${NORMAL}\n"

}
