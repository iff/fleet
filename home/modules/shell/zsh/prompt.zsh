zmodload zsh/datetime

function prompt_before {
    prompt_start=$EPOCHSECONDS
}

autoload -U add-zsh-hook
add-zsh-hook preexec prompt_before

# enable expansion in prompt strings (PS1 & co)
setopt prompt_subst  # apply parameter expansions
setopt prompt_percent  # apply prompt expansions (%)

prompt_marker=']133;A\'  # lets tmux know where new output started
prompt_alerts='%(?,,
%F{1}%Sexit code = %?%s%f)'
prompt_path='%F{4}%B%~%b%f'
prompt_jobs='%(1j, %F{1}%j&%f,)'

# 󰫍  󰌒    
export PS1='$prompt_marker$prompt_alerts
$prompt_path$prompt_jobs %E%k
 %F{15}%f '

export PS4='%K{0}%F{10}[%N:%i %_]
    %f%k %F{4}%f '
