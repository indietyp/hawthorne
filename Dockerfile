MAINTAINER me@indietyp.com
FROM ubuntu:latest
VOLUME /tmp/sockets

RUN apt-get update
RUN apt-get install -y curl
RUN /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/indietyp/hawthorne/master/cli/install.sh) install +p /hawthorne"
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

CMD /bin/sh -c "/hawthorne/cli/utils/wait.sh ${DB_HOST}:${DB_PORT} && /hawthorne/cli/install.sh configure +p /hawthorne +h ${DB} +d ${DOMAIN} +s ${API}"
