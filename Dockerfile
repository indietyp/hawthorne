FROM ubuntu:latest
VOLUME /tmp/sockets

RUN apt-get update
RUN apt-get install -y curl
RUN /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/indietyp/hawthorne/pages/tools/modules/setup.sh?v13)"

CMD /bin/sh -c "/hawthorne/tools/modules/wait.sh ${MYSQL_HOST}:${MYSQL_TCP_PORT} && /hawthorne/tools/modules/configure.sh"
