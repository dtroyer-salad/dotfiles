# dtroyer bash_profile

if [ -f $HOME/.aliases ]; then
	. $HOME/.aliases
fi

# OS-specific stuff
case $(uname -s) in
    AIX)
        EDITOR=vi
        ;;
    CYGWIN_NT*)
        ;;
    Darwin)
        eval "$(/opt/homebrew/bin/brew shellenv)"
        EDITOR=vim
        GOROOT=$HOMEBREW_PREFIX/opt/go/libexec
        GOBIN=$HOMEBREW_PREFIX/go/bin
        PATH=/usr/local/bin:$PATH:/usr/local/sbin:$GOBIN:$HOME/android-sdk/platform-tools
        export GOBIN PATH
        ;;
    HP-UX)
        # Look for perl
        if [[ -d /opt/perl ]]; then
            PERL-/opt/perl
        elif [[ -d /opt/perl5 ]]; then
            PERL=/opt/perl5
        fi
        # We need $PERL to appear in the path AHEAD of /usr/contrib/bin because of
        # the really old and incomplete perl that HP ships there
        PATH=$(echo ${PATH} | sed -e "s|:/usr/contrib/bin:||" -e "s|^/usr/contrib/bin:||" -e "s|:/usr/contrib/bin$||")
        X11=/usr/contrib/bin/X11:/usr/bin/X11
        PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin:$PERL/bin:/usr/contrib/bin:$X11:$PATH:
        export PATH
        EDITOR=vi
        ;;
    Linux)
        PATH=$PATH:/usr/sbin:/sbin
        export PATH
        EDITOR=vim
        ;;
    SunOS)
        X11=/usr/X/bin
        PATH=$PATH:$X11:/usr/ccs/bin
        export PATH
        EDITOR=vi
        ;;
esac
unset PERL X11
export EDITOR

# ssh
#ssh-agent -s >.ssh_agent
#. .ssh_agent
##ssh-add .ssh/id_dt

# Remote DISPLAY
if [ "$DISPLAY" = "" ]; then
    export DISPLAY=`set ${SSH_CLIENT:-localhost}; echo $1`:0
fi

# include .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# Ruby setup
#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
#eval "$(rbenv init -)"

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash" || true

