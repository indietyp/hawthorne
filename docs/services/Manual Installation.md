# Manual Installation

You are not worthy enough currently, please unlock the **ultimate power**, then you can return. Than you very much. :kiss:

!> **This is only for the experts** This is not pleb secure™

# Requirements
* python (_3.4+_)
* nginx
* redis
* mysql
* curl
* supervisor
* cffi
* xml2
* openssl
* nodejs
* git

?> The packages are for apt are: _git python3 python3-dev python3-pip redis-server libxml2-dev libxslt1-dev libssl-dev libffi-dev git supervisor mysql-client build-essential curl nodejs_

# Setup
1. Clone project over GitHub directory: `https://github.com/indietyp/hawthorne`
2. Install python requirements over `pip` and _gunicorn_
3. Install pug over `npm`
4. Create `/var/log/hawthorne`

# Configuration
1. Copy the file `local.default.py` to `local.py` in **panel/**
2. Copy the files `gunicorn.default.conf.py` and `supervisor.default.conf.py`
3. Modify values in `local.py`, `gunicorn.conf.py` and `supervisor.conf.py`

# Finish
1. migrate
2. collectstatic
3. superusersteam
4. start supervisor

> You are done, _yes you really should use the installations script._
