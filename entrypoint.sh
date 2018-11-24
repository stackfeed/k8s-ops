#!/bin/sh

## install oh-my-zsh and enable given plugins and theme
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

## set zsh plugins and theme
awk '/^plugins=\(/,/\)/ { if ( $0 ~ /^plugins=\(/ ) print "plugins=('"${ZSH_PLUGINS}"')"; next } 1' $HOME/.zshrc > /tmp/.zshrc
mv /tmp/.zshrc $HOME/.zshrc && sed -i 's/\(ZSH_THEME\)=".*"/\1="'${ZSH_THEME}'"/' $HOME/.zshrc

# execute command or fallback into shell
[ -n "$*" ] && exec $@ || exec /bin/zsh
