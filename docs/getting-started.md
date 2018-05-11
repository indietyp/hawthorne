# Getting Started with Hawthorne
## Prerequisites
* Web Server (_nginx recommended_)
* MySQL 5.7+ or MariaDB 10.2.2+ instance (either _local_ or _remote_)

## Installation
Due to the architecture of hawthorne there are multiple components installed, to make the installation easier an installation script was created. To start the installation just execute the following command on your server:

```bash
sh -c "$(curl -fsSL raw.githubusercontent.com/laevis/hawthorne/master/cli/install.sh)"
```

> To discover the different installation modes please refer to the `--help` argument.

!> hawthorne also offers a [Docker][6] image for a more easy and managed installation.

## Web server configuration
Currently hawthorne has been tested with _nginx_ and _Apache 2_, every server that is able to redirect traffic through a proxy should be able to serve hawthorne.

> Hawthorne makes use of the [WSGI][4] standard.

!> Example configurations are provided [here][5].

!> **Nginx:** Configuration files are usually placed in `/etc/nginx/sites-avaiable`

## Additional information
Because there are several different environments out there, it is not possible to say that it will work on your machine reliably. It was tested on numerous machines and over and over tweaked. If there’s a problem with your configuration, let me know by creating a pull request on [GitHub][1] and/or by contacting [me][2] directly.

> This script has been tested on Debian 8+, Ubuntu 13+ as well as CentOS 7+. Windows and macOS are currently **not** supported by the installation script.

## Toolchain integration
Upon installing, the toolchain has been linked to your system over the commands `hawthorne` and `ht`. There are several commands integrated.

[More information available here][3]

## Neat things to know
1. 3 Eastereggs are currently hidden
2. The Gunicorn instance is started/stopped/restarted with `supervisorctl start/stop/restart hawthorne`

## Current known system limitations
1. Currently, Hawthorne is unable to run on a subpath like /ht/. It needs to have it’s own _(sub-)domain_.

[1]:	https://www.github.com/laevis/hawthorne
[2]:	mailto:hawthorne@indietyp.com?subject=installation
[3]:	toolchain/Quickstart.md
[4]:	https://en.wikipedia.org/wiki/Web_Server_Gateway_Interface
[5]:	https://github.com/laevis/hawthorne/tree/master/cli/configs
[6]: 	services/Docker%20Image.md
