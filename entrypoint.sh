#!/bin/sh
[ -n "$*" ] && exec $@ || exec /bin/zsh
