FROM ubuntu:latest
VOLUME /tmp/sockets
WORKDIR /root

LABEL maintainer="me@indietyp.com"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales whiptail

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && dpkg-reconfigure --frontend=noninteractive locales && update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ADD . hawthorne/

RUN hawthorne/cli/install.sh install --path /hawthorne --local -noui
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

CMD /hawthorne/cli/utils/docker.sh
