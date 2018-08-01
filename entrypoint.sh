#!/bin/sh
CODEDIR=/code
LINKS=".aws .helm .kube .ssh"

# symlink project configuration directories into user's home
for link in $LINKS; do
  [ ! -e ~/$link -a -d $CODEDIR/$link ] && ln -s $CODEDIR/$link ~
done

[ -n "$*" ] && exec $@ || exec /bin/zsh
