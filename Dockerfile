FROM ubuntu:latest
VOLUME /tmp/sockets

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/indietyp/hawthorne/pages/tools/install.sh)

CMD /bin/bash supervisor start hawthorne
