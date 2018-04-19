FROM ubuntu:latest
VOLUME /tmp/sockets
WORKDIR /root

LABEL maintainer="me@indietyp.com"

ADD . hawthorne/

RUN hawthorne/cli/install.sh install --path /hawthorne --local
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

CMD DB_HOST=$(echo $DB | sed -nE 's#.*\@([^:]+)[:/].*#\1#p') && DB_PORT=$(echo $DB | sed -nE 's#.*[\:]([0-9]+)\/.*#\1#p') && DB_PORT=${DB_PORT:-3306} && redis-server --daemonize yes && /hawthorne/cli/utils/wait.sh ${DB_HOST}:${DB_PORT} && /hawthorne/cli/install.sh configure --path /hawthorne --database $DB --domain $DOMAIN --steam $API --admin $ADMIN --local --docker
