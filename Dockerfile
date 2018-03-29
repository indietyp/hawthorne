FROM ubuntu:latest
VOLUME /tmp/sockets

ARG DIRECTORY

RUN apt-get update
RUN apt-get install -y curl
RUN /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/indietyp/hawthorne/pages/tools/modules/setup.sh?v4)"

CMD /bin/sh /hawthorne/configure.sh
