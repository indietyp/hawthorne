FROM ubuntu:latest
VOLUME /tmp/sockets

RUN apt-get update
RUN apt-get install -y curl
RUN /bin/sh -c "$( curl -fsSL raw.githubusercontent.com/indietyp/hawthorne/pages/tools/modules/setup.sh))"

CMD /bin/sh /hawthorne/configure.sh
