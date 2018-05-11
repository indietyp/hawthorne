# Reference
This part of the documentation references to different commands that are implemented or will be implemented by the toolchain. Some of the functions are planned, but not realised and may nor have an ETA (estimated time of arrival)

!> This document and the tools are subject of change.

# Help
> **available** since v0.0

The purpose of this command is to output all the other commands. It shows the current capabilities and version of the toolchain.
```bash
hawthorne help
```

# Verify
> **available** since v0.8.1

Verifies the module and deletes or changes files if necessary. You have the choice if you want to stash your local changes. This makes sure that `hawthorne update` does not fail.

```bash
hawthorne verify
```

# Version
> **available** since v0.7.3

Does exactly what the command does. What do you think? This is some vodoo magic? Prints the current version and tells you if you are behind.

It that everything? **Yes**

```bash
hawthorne version
```

?> suggested by **Czar**

# Update
> **available** since v0.0

This command detects if changes happened to the remote repository and then pull the changes, as well as restarts all necessary modules.

```bash
hawthorne update
```

!> It is to the upmost importance that you **do not** tinker with files in the directory, except for `/panel/local.py`.

?> This command is recommended to be included in a regular _weekly_ crontab.

# Report
> **available** since v0.7

This command saves the data required for common debugging of your problem. It has been well tested and only uses the data it needs. This data includes your…
* … **PYTHONPATH** environment variable
* … current python **version**
* … system (e.g. _macOS_, _linux_, _Windows_)
* … distribution (e.g. _ubuntu_, _debian_, _centOS_)
* … recent 100 lines of `/var/log/hawthorne/debug.log`
* … the directory of hawthorne

```bash
hawthorne report
```

?> Your submitted data will be saved for 24 hours.

!> You will be registered to the mainframe, and therefor your instance will be known by a database. **Please bear that in mind.** Only data that is necessary will be saved for the shortest time possible. For more information on the topic please refer to this [chapter].

# Server
## Start
> **ETA** TBD

```bash
hawthorne server start
```

## Restart
> **ETA** TBD

```bash
hawthorne server restart
```

## Stop
> **ETA** TBD

```bash
hawthorne server stop
```

## Unload
> **ETA** TBD

```bash
hawthorne server unload
```

## Load
> **ETA** TBD

```bash
hawthorne server load
```
