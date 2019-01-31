#!/bin/sh

dir=$(cd $(dirname $(readlink $([ $(uname | tr '[:upper:]' '[:lower:]') = linux* ] && echo "-f") $0)); pwd -P)
python3 $dir/helper.py $@
