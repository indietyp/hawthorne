# Hawthorne

## **Getting Started with Hawthorne**

Hawthorne is an application that has multiple components, reaching from an API to a logging instance. To provide the best possible results in the installation process a shell script was created. To start the automated installation process execute the following command:

```bash
sh -c "$(curl -fsSL raw.githubusercontent.com/indietyp/hawthorne/master/tools/install.sh)"
```

### Prerequisites

* Web Server \(_nginx recommended_\)
* MySQL or MariaDB instance \(_either local or remote_\)

### Information

Because there are several different environments out there, it is not possible to say that it will work on your machine reliably. It was tested on numerous machines and over and over tweaked. If there’s a problem with your configuration, let me know over an pull request on [GitHub](https://www.github.com/indietyp/hawthorne) or write [me](mailto:hawthorne@indietyp.com?subject=installation) instead.

{% hint style="info" %}
The current only supported mode is _interactive_. A non-interactive mode is planned, but currently not a priority. This script has been tested on Debian 8+, Ubuntu 13+ as well as CentOS 7+. Windows and macOS are currently **not** supported.
{% endhint %}

## **Toolchain Integration**

Upon installing the toolchain has been linked to your system over the commands `hawthorne` and `ht`. There are several commands integrated. 

{% hint style="info" %}
It is _highly recommended_ that `hawthorne update` is to be included in a weekly crontab to ensure that hawthorne updates itself.
{% endhint %}

{% page-ref page="toolchain.md" %}

## **Web Server Integration**

The current web servers that have been reliably tested are _nginx_ and _Apache 2_. It is to note that every web server that has the capability of redirecting traffic over a proxy is capable of being used, due to the usage of the [WSGI](https://en.wikipedia.org/wiki/Web_Server_Gateway_Interface) technology.

Example configurations are provided [here](https://github.com/indietyp/hawthorne/tree/master/tools/configs). Please pay close attention to the comments provided. That guide you through the process of configuration.

If the recommended path of the automated installation has been chosen, an pre-configured script for your system would have been displayed.

## **Neat things to know**

## **Current Limitations**

## **Frequently Asked Questions**

1. I get a** 400 - Bad Request**, what shall I do?  In the file `panel/local.py` of the installation directory the appropriate domain or IP needs to be added to the `ALLOWED_HOSTS` list.  After this restart hawthorne over `supervisorctl restart hawthorne`. 
2. I get the error: **cannot connect to MySQL database**, what shall I do?  Is your specified `password` correct? Is your specified `username` correct?  Is your MySQL **not** on the current machine? If yes... .. is `bind` on the server correctly configured? [Hint!](https://stackoverflow.com/a/21627550/9077988) ... is the MySQL instance accessible from the outside? [Hint!](https://stackoverflow.com/a/16288118/9077988) 
3. I get a **500** Error.  No one can solve a problem with such little information. To clarify the situation please use the command `hawthorne report`, this will send important data for the debugging process to me, you will be given an identifier, when talking to me, please use this UUID to identify your problem. The information collected is discussed later. _Note:_ Your application will be connected to the mainframe. This action cannot be reversed. 
4. You cannot find you problem?  Get in touch with me, under my [mail](mailto:hawthorne@indietyp.com) or [Discord](https://discord.gg/3pNEqn8)  Want to insult me? Please go ahead under `i-am-a-cunt@indietyp.com` or `insult@indietyp.com`. Get creative. Let me be your guidance into an anger free lifestyle!

