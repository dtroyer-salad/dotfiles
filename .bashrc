# .bashrc

BASH_ENV=$HOME/.bashrc

set +o histexpand

# Append to history file
shopt -s histappend

# Source global definitions
if [ -f /etc/bashrc ]; then
    source /etc/bashrc
fi

case $(uname -s) in
    AIX|HP-UX)
        eval ` tset -s -Q `
        stty erase "`tput kbs`" kill "^U" intr "^C" eof "^D"
        stty hupcl ixon ixoff
        if [[ "$(uname -s)" = "HP-UX" ]]; then
            tabs
        fi
        ;;
    Darwin)
        EDITOR=vim
        GOBIN=/usr/local/go/bin
        PATH=/usr/local/bin:$PATH:/usr/local/sbin:$GOBIN:$HOME/android-sdk/platform-tools
        export GOBIN PATH
        HOMEBREW_NO_AUTO_UPDATE=1
        HOMEBREW_NO_EMOJI=1
        HOMEBREW_NO_ANALYTICS=1
        export HOMEBREW_NO_AUTO_UPDATE HOMEBREW_NO_EMOJI HOMEBREW_NO_ANALYTICS
        # hack in for now
        if [[ -f $HOME/.git-completion.bash ]]; then
            source .git-completion.bash
        else
            if [[ -f $(/opt/homebrew/bin/brew --prefix)/etc/bash_completion.d/git-completion.bash ]]; then
                source $(/opt/homebrew/bin/brew --prefix)/etc/bash_completion.d/git-completion.bash
            fi
        fi
        ;;
    Linux)
        if [[ -f $HOME/.git-completion.bash ]]; then
            source .git-completion.bash
        else
            if [[ -f /etc/bash_completion.d/git-completion.bash ]]; then
                source /etc/bash_completion.d/git-completion.bash
            fi
        fi
        if [[ -n $WSL_DISTRO_NAME ]]; then
            sudo hostname $WSL_DISTRO_NAME
        fi
        ;;
esac

case $TERM in
    xterm*|rxvt)
        TITLE="\[\e]0;\u@\h: \w\a\]"
        ;;
    screen)
        ;;
esac

# local functions

if [[ -f $HOME/.localrc ]]; then
    source $HOME/.localrc
fi

# Setup bash-specific prompt
# Put something like this in .localrc to set a unique color per host:
#PCOLOR='\[\e[0;36;244m\]'
PCOLOR=${PCOLOR:-'\[\e[0;32;244m\]'}

# Set up git prompt magic
if ! type -t __git_ps1 >/dev/null && [[ -r $HOME/.git-prompt ]]; then
    source $HOME/.git-prompt
    GIT='$(__git_ps1 " ('"${PCOLOR}"'%s\[\e[0;0m\])")'
fi

E='$([[ $? = 0 ]] && echo ")" || echo "(")'
[[ "$UID" = "0" ]] && PCOLOR='\[\e[0;31;244m\]'
PS1="${TITLE}:${E} ${PCOLOR}\u@\h\[\e[0;0m\]:\w${GIT} \$ "
PS2="> "
SUDO_PS1="\u@\h:\w \# "
export PS1 PS2 SUDO_PS1
unset TITLE

# Python helpers
export PIP_DOWNLOAD_CACHE=~/.pip/cache

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
#export PATH="$PATH:$HOME/.rvm/bin"
