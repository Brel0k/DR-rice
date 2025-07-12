#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

fastfetch

alias ls='ls --color=auto'
alias grep='grep --color=auto'

alias pls='sudo'
alias ff='fastfetch'
alias c='clear'
alias termwarp='warp-terminal'

PS1='[\u@\h \W]\$ '
