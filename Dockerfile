FROM ubuntu:latest
VOLUME /tmp/sockets

RUN apt-get update
RUN apt-get install -y curl

CMD /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/indietyp/hawthorne/pages/tools/install.sh)"
