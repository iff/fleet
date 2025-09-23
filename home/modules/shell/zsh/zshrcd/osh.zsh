function __osh {
    osh-oxy $@
}

autoload -U add-zsh-hook

function __osh_before {
    local command=''${1[0,-2]}
    if [[ $command != "" ]]; then
        __osh_current_command=(
            --starttime $(__osh_ts)
            --command $command
            --folder "$(pwd)"
        )
    fi
}
add-zsh-hook zshaddhistory __osh_before

function __osh_after {
    local exit_code=$?
    if [[ ! -v __osh_session_id ]]; then
        __osh_session_id=$(uuidgen)
    fi
    if [[ -v __osh_current_command ]]; then
    __osh_current_command+=(
            --endtime $(__osh_ts)
            --exit-code $exit_code
            --machine "$(hostname)"
            --session $__osh_session_id
        )
        __osh append-event $__osh_current_command &!
        unset __osh_current_command
    fi
}
add-zsh-hook precmd __osh_after

function __osh_search {
    if [[ -v __osh_session_id ]]; then
        __osh_session_id=$(uuidgen)
    fi
    # BUFFER=$(__osh sk --query=$BUFFER --session-id=$__osh_session_id)
    BUFFER=$(__osh sk --query=$BUFFER)
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N __osh_search
bindkey '^r' __osh_search
bindkey -M vicmd '^r' __osh_search
bindkey -M viins '^r' __osh_search
