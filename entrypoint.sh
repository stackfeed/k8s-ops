#!/bin/sh

if [ -d "$HOME" ]; then
  # init .zshrc only once
  [ -e $HOME/.zshrc ] || init_zshrc=yes

  ## copy skeleton into actual $HOME (one time operation)
  cwd=$(pwd) && cd /home/_home-skeleton_
  ls -a1 | sed '/^\(\.\|\.\.\)$/d' | xargs -I{} sh -c "test -e $HOME/{} || cp -ar {} ${HOME}"
  cd "${cwd}"

  if [ -n "$init_zshrc" ]; then
    awk '/^plugins=\(/,/\)/ { if ( $0 ~ /^plugins=\(/ ) print "plugins=('"${ZSH_PLUGINS}"')"; next } 1' $HOME/.zshrc > /tmp/.zshrc
    mv -f /tmp/.zshrc $HOME/.zshrc
    sed -i 's/\(ZSH_THEME\)=".*"/\1="'${ZSH_THEME}'"/' $HOME/.zshrc
    sed -i 's/^# *\(DISABLE_AUTO_UPDATE=\).*/\1true/' $HOME/.zshrc
    sed -i "s#\(export *ZSH=\).*#\1${HOME}/.oh-my-zsh#" $HOME/.zshrc
  fi
fi

# execute command or fallback into shell
[ -n "$*" ] && exec "$@" || exec /bin/zsh --login
