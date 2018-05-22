# Getting Started with Hawthorne

!> The following documentation requires a certain extent of knowledge of the English language as well as with (any) Linux OS. Do not attempt to install Hawthorne if you are a beginner, we are not going to learn you how to read.

## Prerequisites
Make sure you have the following items installed and configured on your Linux server, before you proceed with the installation.

!> A common mistake is installing the wrong version of MariaDB or MySQL, which will result in the installation failing.

* A Linux OS server
* Web Server (_nginx recommended_)
* MySQL 5.7+ or MariaDB 10.2.2+ instance (either _local_ or _remote_)

## Current known system limitations
* Hawthorne is unable to run on a subpath like `www.example.com/ht/`. It needs to have it’s own _(sub-)domain_ like `www.ht.example.com`
* Windows is not officially supported by the installation script.

## Installation
Due to the architecture of hawthorne there are multiple components installed, to make the installation easier an installation script was created. To start the installation just execute the following command on your server:

```bash
sh -c "$(curl -fsSL raw.githubusercontent.com/laevis/hawthorne/master/cli/install.sh)"
```

## Installation Modes
> To discover the different installation modes please refer to the `--help` argument.

!> hawthorne also offers a [Docker][6] image for a more easy and managed installation.

## Web server configuration
Currently hawthorne has been tested with _nginx_ and _Apache 2_, every server that is able to redirect traffic through a proxy should be able to serve hawthorne.

> Hawthorne makes use of the [WSGI][4] standard.

!> Example configurations are provided [here][5].

!> **Nginx:** Configuration files are usually placed in `/etc/nginx/sites-avaiable`

## Starting/Restarting/Stopping Hawthorne
To start Hawthorne after the installation is complete, or to restart or stop the service:
```bash
supervisorctl start/stop/restart hawthorne
```

## Additional information
Because there are several different environments out there, it is not possible to say that it will work on your machine reliably. It was tested on numerous machines and over and over tweaked. If there’s a problem with your configuration, let me know by creating a pull request on [GitHub][1] and/or by contacting [me][2] directly.

> This script has been tested on Debian 8+, Ubuntu 13+ as well as CentOS 7+. Windows and macOS are currently **not** supported by the installation script.

## Toolchain integration
Upon installing, the toolchain has been linked to your system over the commands `hawthorne` and `ht`. There are several commands integrated.

[More information available here][3]

[1]:	https://www.github.com/laevis/hawthorne
[2]:	mailto:hawthorne@indietyp.com?subject=installation
[3]:	toolchain/Quickstart.md
[4]:	https://en.wikipedia.org/wiki/Web_Server_Gateway_Interface
[5]:	https://github.com/laevis/hawthorne/tree/master/cli/configs
[6]: 	services/Docker%20Image.md
