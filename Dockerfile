FROM ubuntu:latest
VOLUME /tmp/sockets
WORKDIR /root

LABEL maintainer="me@indietyp.com"

ADD . hawthorne/

RUN hawthorne/cli/install.sh install --path /hawthorne --local
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

CMD /hawthorne/cli/utils/docker.sh
