# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    COLORPREFIX="\[\033["
    COLORSUFFIX="m\]"
    DEEPSLATEGRAY="${COLORPREFIX}38;5;123${COLORSUFFIX}"
    DARKORANGE="${COLORPREFIX}38;5;208${COLORSUFFIX}"
    CHARTREUSE="${COLORPREFIX}38;5;76${COLORSUFFIX}"
    SILVER="${COLORPREFIX}38;5;7${COLORSUFFIX}"
    CLEAR="${COLORPREFIX}00${COLORSUFFIX}"
    PS1="${debian_chroot:+($debian_chroot)}${DEEPSLATEGRAY}\u@\h${CLEAR}:${DARKORANGE}\w${CLEAR} [${CHARTREUSE}\$(git symbolic-ref --short HEAD 2>/dev/null)${CLEAR}] [\$(kubectx -c)] [${SILVER}\$(terraform workspace show 2>/dev/null)${CLEAR}] \$ "
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
#alias ll='ls -l'
#alias la='ls -A'
#alias l='ls -CF'
alias ls='ls -alrt --color=auto'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export ANSIBLE_CONFIG=/media/floor/ansible_home/ansible.cfg
# df is already a thing.. alias df='sudo diff -r /media/storage/$1 /media/tpalko/orange-storange/$2'

#export SCRIPTS_HOME=/media/floor/development/scripts
#alias drysortpics='${SCRIPTS_HOME}/pic_date_sorter.py -s /media/storage/pics/inbox -t /media/storage/pics -d'
#alias sortpics='${SCRIPTS_HOME}/pic_date_sorter.py -s /media/storage/pics/inbox -t /media/storage/pics'
#alias scanflatbed='scanimage -p -v --source FlatBed'
COLORLASERJET="airscan:e2:HP Color LaserJet MFP M182nw (DAB332)"
alias scan='scanimage -d "airscan:e0:HP Color LaserJet MFP M182nw (DAB332)"'
alias batchscan='scanimage -d "${COLORLASERJET}" --batch --format=png --batch-prompt'
alias batchscanalt='scanimage -d "airscan:e0:HP Color LaserJet MFP M182nw (DAB332)" --batch --format=pnm --batch-prompt'
alias topdf='libreoffice --convert-to pdf *.png'
alias pdfu='pdfunite *.pdf'

#alias print='print -P Brother_HL-2270DW_series'
alias ext='ls *.* | awk "{ print $9 }" | sed "s/.*\.//g" | sort | uniq'
alias openrgb='openrgb --noautoconnect'
alias retroarch='flatpak run org.libretro.RetroArch'
alias etcdget='etcdctl get --print-value-only'

export WORKON_HOME=~/.virtualenv
source /usr/share/bash-completion/completions/virtualenvwrapper

. $HOME/.asdf/asdf.sh

. $HOME/.asdf/internal/completions/asdf.bash

PATH="${HOME}/.local/bin:${HOME}/bin:${PATH}"
#export GOPATH=/home/debian/tpalko/go
#PATH=/usr/local/bin/go/bin:$PATH

# BEGIN ANSIBLE MANAGED BLOCK
PATH="${HOME}/.local/bin:${HOME}/bin:${PATH}"
# END ANSIBLE MANAGED BLOCK

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

export DOCKER_REGISTRY=frankendeb:5000

#export GOROOT="/usr/local/bin/go"

export COWIN_ID=FC:58:FA:CB:A1:6E
alias mv='mv -uvn'
alias cp='cp -an'
alias rm='rm -v'
alias df='df -x tmpfs -x squashfs -x overlay -x devtmpfs -T'
