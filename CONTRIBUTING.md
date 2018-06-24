# Contributing to Hawthorne
First of, thank you for taking out time on you busy schedule to help this project out. In this document you can find all the important information to have a meaningful and easy time contributing to the project.

This CONTRIBUTING.md is adapted from the atom project.

#### Table Of Contents

[Styleguides](#styleguides)
  * [Git Commit Messages](#git-commit-messages)
  * [Python Styleguide](#python-styleguide)
  * [SourcePawn Styleguide](#sourcepawn-styleguide)

[How Can I Contribute?](#how-can-i-contribute)
  * [Reporting Bugs](#reporting-bugs)
  * [Suggesting Enhancements](#suggesting-enhancements)
  * [Pull Requests](#pull-requests)


## How Can I Contribute?
You can contribute in several ways, even for non tech savy people there's a lot to do.

### Reporting Bugs
When you discovered have discovered a bug, please don't just write that something is wrong - but rather give the developer information to reproduce the problem. This can be done by providing:
* Screenshots
* `hawthorne report`
* Retrieving the last 100 lines of `/var/log/hawthorne/debug.log`

You can submit the bug either as an issue in the GitHub (I will probably not forget about it then - or post it in the Discord.)

### Suggesting Enhancements
Enhancements are one of the most important things for this project, so please let them come. To get a good idea of what you want, please let us know a detailed description of what you want to suggest and also see if it is either not already on the roadmap or already suggested.

You can submit the suggestion either as an issue in the GitHub (I will probably not forget about it then - or post it in the Discord.)

### Pull Requests
* Fill in [the required template](PULL_REQUEST_TEMPLATE.md)
* Do not include issue numbers in the PR title
* Include screenshots and animated GIFs in your pull request whenever possible.
* Follow the [Python](#python-styleguide) and [SourcePawn](#sourcepawn-styleguide) styleguides.
* End all files with a newline
* Avoid platform-dependent code

## Styleguides

### Git Commit Messages
* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less

### Python Styleguide
All Python code must be valid against [PEP-8](https://www.python.org/dev/peps/pep-0008/?), modifications done by the author of the projects are:

* 2 tabspace intend, instead of 4 tabspace intend
* 90-ish characters per line or less

### SourcePawn Styleguide
SourcePawn has no global styleguide so these are the one in the project used - this is a rough adaptation of PEP-8.

* 2 tabspace intend
* 90-ish characters per line or less
* `{` and `}` **never** on a line alone
    Valid:
    ```
        if () {

        } else {

        }
    ```

    Invalid:
    ```
        if ()
        {

        }
        else
        {

        }
    ```
* Functions are in _CamelCase_
* Variables are in _snake_case_
* Global variables that permanent for a server or user lifetime are _UPPERCASE_
