#!/bin/bash

for file in $(grep --files-without-match --include \*.pug -r "load i18n" .); do
	exec 3<> $file && awk -v TEXT="- load i18n" 'BEGIN {print TEXT}{print}' $file >&3
done

