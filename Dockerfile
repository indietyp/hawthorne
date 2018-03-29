FROM ubuntu:latest
VOLUME /tmp/sockets

ARG MYSQL_PWD
ARG MYSQL_HOST
ARG MYSQL_TCP_PORT
ARG MYSQL_USER
ARG MYSQL_DATABASE


RUN apt-get update
RUN apt-get install -y curl
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/indietyp/hawthorne/pages/tools/install.sh)"

CMD /bin/bash supervisorctl start hawthorne
