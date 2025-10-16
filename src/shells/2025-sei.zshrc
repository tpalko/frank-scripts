alias ls='ls -alrth --color=always'
alias mv='mv -nv'
alias cp='cp -anv'
alias grep='grep --color=always'
alias home='nmap -p 22022 --open -sV 74.98.228.0/24'

export JAVA_HOME=$(brew --prefix java)

export HOMEBREW_PREFIX="/Users/tpalko/homebrew";
export HOMEBREW_CELLAR="/Users/tpalko/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/Users/tpalko/homebrew";
export PATH="/Users/tpalko/bin:/Users/tpalko/homebrew/bin:/Users/tpalko/homebrew/sbin:/opt/homebrew/opt/gitlab-runner/bin${PATH+:$PATH}";
export MANPATH="/Users/tpalko/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/Users/tpalko/homebrew/share/info:${INFOPATH:-}";

export REQUESTS_CA_BUNDLE="${HOME}/zscaler/ca-bundle.pem"
export AWS_CA_BUNDLE="${HOME}/zscaler/ca-bundle.pem"
export AZURE_ENVIRONMENT=AzureUSGovernmentCloud
#export AZURE_ADDITIONALLY_ALLOWED_TENANTS=REDACTED
#export AZURE_TENANT_ID=REDACTED
#export AZURE_CLIENT_ID=REDACTED

#export ARM_SUBSCRIPTION_ID="REDACTED"
#export ARM_TENANT_ID="REDACTED"
export ARM_CLIENT_ID="<service_principal_appid>"
export ARM_CLIENT_SECRET="<service_principal_password>"

export HISTCONTROL=ignoreboth 

if [[ ${SET_PROXY} -eq 1 ]]; then 
  export https_proxy=http://cloudproxy.sei.cmu.edu:80
  export http_proxy=${https_proxy}
  export no_proxy=localhost,127.0.0.1,.local,.sei.cmu.edu,.cert.org,repo1.dso.mil
  export NO_PROXY=${no_proxy}
  export HTTPS_PROXY=${https_proxy}
fi 

RED="\e[31m"
WHITE="\e[97m"
LCYAN="\e[96m"
LYELLOW="\e[93m"
CLOSECOLOR="\e[0m"

fix_prompt() {

  CURR_BRANCH=$(git branch --show-current 2>/dev/null)
  if [[ -z "${CURR_BRANCH}" ]]; then 
    CURR_BRANCH=$(git branch --list 2>/dev/null | grep -E "^\*" | awk '{ $1=""; $2=$2; print }')
  fi 

  VENV_PROMPT="" 
  if [[ -n "${VIRTUAL_ENV_PROMPT}" ]]; then 
    VENV_PROMPT="[${VIRTUAL_ENV_PROMPT}] "
  fi 
 
  # PSBASE="\e[31m%n@%m ${LCYAN}%5~ "  
  PSBASE="${VENV_PROMPT}%{$fg[yellow]%}%n@%m %{$fg[green]%}%7~ "
  if [[ -n "${CURR_BRANCH}" ]]; then 
    PSBASE="${PSBASE}%{$fg[cyan]%}[${CURR_BRANCH}] "
  fi 

  PSBASE="${PSBASE}%{$reset_color%}$ "

  PS1=${PSBASE}
  # PS1="%{$fg[red]%}%n%{$reset_color%}@%{$fg[blue]%}%m %{$fg[yellow]%}%~ %{$reset_color%}%% "
}

autoload -U add-zsh-hook colors
#add-zsh-hook chpwd fix_prompt
add-zsh-hook precmd fix_prompt
colors

eval "$(goenv init -)"
source /opt/homebrew/bin/virtualenvwrapper.sh

fix_prompt
