#!/bin/sh

DB_HOST=$(echo $DB | sed -nE 's#.*\@([^:]+)[:/].*#\1#p')
DB_PORT=$(echo $DB | sed -nE 's#.*[\:]([0-9]+)\/.*#\1#p')
DB_PORT=${DB_PORT:-3306}

DEMO=${DEMO:-0}
ROOT=${ROOT:-root}

redis-server --daemonize yes
/hawthorne/cli/utils/wait.sh ${DB_HOST}:${DB_PORT}

if [ $DEMO -ne 1 ]; then
  /hawthorne/cli/install.sh configure --path /hawthorne --database $DB --domain $DOMAIN --steam $API --admin $ADMIN --local --docker --headless
fi
  /hawthorne/cli/install.sh configure --path /hawthorne --database $DB --domain $DOMAIN --steam $API --admin $ADMIN --local --docker --demo --headless

cat ~/install.log
