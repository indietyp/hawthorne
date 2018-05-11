# Quickstart

The mainframe is a means to coordinate different centralised services.

?> _Note:_ Currently there's no official documentation for the endpoints provided by the mainframe.

On your instance a `<directory>/mainframe.ini` is created, which saves the current information about the mainframe.

## Mail
!> When sending mails, your server is automaticially registered.

When sending emails, the only information sent, is the UUID4 and email of the recipient, the username of the owner. With this information **it is not possible to trace back who the person is.** This information will then be inserted into template and sent over a sendgrid account.

> You are being rate-limited by 10 mails per day.

> An external mail server is used for sending invitation emails, therefor it was decided to use a rate limited central server to communicate to this server.

## Report

The report feature, is a way for me, as a developer to help you further with solving your problems. The information sent, is discussed in this [chapter][1].

> The information is saved for 24 hours.

## Information sent
If you want to know what information has been saved please email `i-want-my-information-back@indietyp.com`. For proofing your legitimacy please attach your ID to the email.

[1]:	toolchain/reference.md
