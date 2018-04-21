
# Getting Started with Hawthorne
Hawthorne is an application that has multiple components, reaching from an API to a logging instance. To provide the best possible results in the installation process a shell script was created. To start the automated installation process execute the following command:

```bash
sh -c "$(curl -fsSL raw.githubusercontent.com/indietyp/hawthorne/master/cli/install.sh)"
```

## Prerequisites
* Web Server (_nginx recommended_)
* MySQL or MariaDB instance (either _local_ or _remote_)

## Additional information
Because there are several different environments out there, it is not possible to say that it will work on your machine reliably. It was tested on numerous machines and over and over tweaked. If there’s a problem with your configuration, let me know by creating a pull request on [GitHub][1] and/or by contacting [me][2] directly.

?> The current only supported mode is _interactive_. A non-interactive mode is planned, but currently not a priority. This script has been tested on Debian 8+, Ubuntu 13+ as well as CentOS 7+. Windows and macOS are currently **not** supported.

## Toolchain integration
Upon installing, the toolchain has been linked to your system over the commands `hawthorne` and `ht`. There are several commands integrated.

!> It is _highly recommended_ that hawthorne update is to be included in a weekly crontab to ensure that hawthorne updates itself.

[More information available here][3]

## Web server configuration

The current web servers that have been reliably tested are _nginx_ and _Apache 2_. It is to note that every web server that has the capability of redirecting traffic over a proxy is capable of being used, due to the usage of the [WSGI][4] technology.

Example configurations are provided [here][5].

!> Please pay close attention to the comments provided. That guide you through the process of configuration.

If the recommended path of the automated installation has been chosen, a pre-configured script for your system would have been displayed.

## Neat things to know

## Current known system limitations
1. Currently, Hawthorne is unable to run on a subpath like /ht/. It needs to have it’s own _(sub-)domain_.

## Frequently Asked Questions
1. I get a** 400 - Bad Request**, what shall I do?
	- In the file `panel/local.py` of the installation directory, the appropriate domain or IP needs to be added to the `ALLOWED_HOSTS` list.  After this, restart hawthorne over `supervisorctl restart hawthorne`.
2. I get the error: **cannot connect to MySQL database**, what shall I do?
	- Is your specified `password` correct? Is your specified `username` correct?
	- Is your MySQL **not** on the current machine? If yes...
		- ... is `bind` on the server correctly configured? [Hint!][6]
		- ... is the MySQL instance accessible from the outside? [Hint!][7]
3. I get a **500** Error.
	- No one can solve a problem with such little information.
	- To clarify the situation please use the command `hawthorne report`, this will send important data for the debugging process to me
	- **You will be given an identifier**. When talking to me, please use this UUID to identify your problem.
	- The information collected is discussed later.
	- _Note:_ Your application will be connected to the mainframe. This action cannot be reversed.
4. Is your problem not listed? You can get in touch with me via [e-mail][8] or [Discord][9]  Want to insult me? Please go ahead under `i-am-a-cunt@indietyp.com` or `insult@indietyp.com`. Get creative. Let me be your guidance into an anger free lifestyle!


[1]:	https://www.github.com/indietyp/hawthorne
[2]:	mailto:hawthorne@indietyp.com?subject=installation
[3]:	toolchain.md "More Information"
[4]:	https://en.wikipedia.org/wiki/Web_Server_Gateway_Interface
[5]:	https://github.com/indietyp/hawthorne/tree/master/tools/configs
[6]:	https://stackoverflow.com/a/21627550/9077988
[7]:	https://stackoverflow.com/a/16288118/9077988
[8]:	mailto:hawthorne@indietyp.com
[9]:	https://discord.gg/3pNEqn8
