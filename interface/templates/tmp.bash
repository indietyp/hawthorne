#!/bin/bash

for file in $(grep --files-without-match --include \*.pug -r "load i18n" .); do
	ex -c '0r - load i18n|x' $file
done
