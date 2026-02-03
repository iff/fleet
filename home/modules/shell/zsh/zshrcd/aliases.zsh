function tess {
    tmux capture-pane -peJ -S - -E - > tess.data
    v -R -c 'terminal cat tess.data'
    rm tess.data
}

function take {
    # mkdir and cd dir
    mkdir -p $1
    cd $1
}

alias reload=". ~/.zshrc"
alias ls="eza --header --git --time-style=relative --icons --no-permissions --no-user --long --mounts --sort=name"
alias lr="ls --sort=newest"
alias la="eza --long --header --all --icons --git"
alias ll="eza --header --git --time-style=long-iso --icons --group --long --mounts --sort=name"
alias man="man --no-justification"
alias k="kubectl"
alias nn="jj"
(( $+commands[docker] )) && alias dk="docker kill $(docker ps -q)"
