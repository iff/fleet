{ lib, pkgs, ... }:

let
  tm = pkgs.writeScriptBin "tm"
    ''
      #!/usr/bin/env zsh
      set -eux -o pipefail

      session=''${1:-$(basename `pwd`)}

      tmux new-session -A -D -s $session
      # tmux new-session -A -D -e NN_XPS_CACHE=$HOME/.cache/xps -e nn=$HOME/envs/$session -s $session
    '';

  tmux-git = pkgs.writeScriptBin "tmux-git"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      if [[ $(pwd -P) == (/efs|/efs/*|/s3/*) ]]; then
          print -- '󰒲'
          return
      fi

      # TODO either . or nn/nn will be the path we need to show
      local git_path
      if git_path=$(git rev-parse --show-toplevel); then
          # NOTE plain 'git status' with no arguments can be slow because it checks all submodules
          # NOTE parsing like below is actually 2x faster than zsh's vcs_info
          # NOTE --porcelain=v1 would be preferred, but then --show-stash is ignored
          local args=(--branch --ignore-submodules=all --untracked-files=normal --ahead-behind --show-stash)
          # could use 'timeout --kill-after=0.01s 0.01s cmd' to stop git info when it takes too long on a slow filesystem
          (git -c advice.statusHints=false status $args |& awk -v ORS=''' '
              BEGIN { has=1; flags=0; stashed=0 }
              /^fatal: not a git repository/ { has=0 }
              /^On branch / { print " " $3 " " }
              /^HEAD detached at / { print " " $4 " " }
              /^Your branch is up to date with / { }
              /^Your branch is ahead of / { print " " }
              /^Your branch is behind / { print " " }
              /^Your branch and .+ have diverged/ { print " " }
              /^nothing to commit, working tree clean/ { }
              /^Unmerged paths:/ { print "󰅚"; flags++ }
              /^Changes to be committed:/ { print "󰆗"; flags++ }
              /^Changes not staged for commit:/ { print "󰙝"; flags++ }
              /^Untracked files:/ { print ""; flags++ }
              /^Your stash currently has / { stashed=1 }
              END {
                  if (has==0) print ""
                  if (has==1 && flags==0) print "󰄴"
                  if (has==1 && stashed==1) print " 󰊰"
              }
          ') || true
          print -- ""
      else
          print -- '-'
      fi
    '';
in
{
  # FIXME alacritty and TMUX have issues with OSX native ncurses
  # see https://github.com/NixOS/nixpkgs/issues/204144
  home.packages = [ tm tmux-git ] ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.ncurses ];

  programs.tmux = {
    enable = true;
    prefix = "F12";
    baseIndex = 1;
    historyLimit = 5000;
    escapeTime = 0;
    terminal = "tmux-256color";

    extraConfig = ''
      set -g status on
      set -g focus-events on
      set -g renumber-windows on

      # status bar
      set -g status-position top
      set -g status-left-length 100
      set -g status-right-length 50
      set -g status-justify "left"

      set -g mode-style "fg=#232831,bg=#abb1bb"
      set -g message-style "fg=#232831,bg=#abb1bb"
      set -g message-command-style "fg=#232831,bg=#abb1bb"

      set -g pane-border-style "fg=#abb1bb"
      set -g pane-active-border-style "fg=#81a1c1"
      set -g pane-border-lines heavy
      set -g pane-border-format " #{pane_index} "

      set -g status-style "fg=#abb1bb,bg=#232831"

      set -g status-left-style NONE
      set -g status-left "#[fg=#232831,bg=#81a1c1,bold] #{session_name} #(tmux-git) #[fg=#81a1c1,bg=#232831,nobold,nounderscore,noitalics]"

      set -g status-right-style NONE
      set -g status-right "#[fg=#232831,bg=#232831,nobold,nounderscore,noitalics][fg=#81a1c1,bg=#232831] #{prefix_highlight} #[fg=#abb1bb,bg=#232831,nobold,nounderscore,noitalics]#[fg=#232831,bg=#abb1bb] %H:%M #[fg=#81a1c1,bg=#abb1bb,nobold,nounderscore,noitalics]#[fg=#232831,bg=#81a1c1,bold] #h "

      setw -g window-status-activity-style "underscore,fg=#7e8188,bg=#232831"
      setw -g window-status-separator ""
      setw -g window-status-style "NONE,fg=#7e8188,bg=#232831"
      setw -g window-status-format "#[fg=#232831,bg=#232831,nobold,nounderscore,noitalics]#[default] #I  #W #[fg=#232831,bg=#232831,nobold,nounderscore,noitalics]"
      setw -g window-status-current-format "#[fg=#232831,bg=#abb1bb,nobold,nounderscore,noitalics]#[fg=#232831,bg=#abb1bb,bold] #I  #W #[fg=#abb1bb,bg=#232831,nobold,nounderscore,noitalics]"

      # only show pane bare if more than one
      set-hook -g -w pane-focus-in { set-option -Fw pane-border-status '#{?#{e|>:#{window_panes},1},top,off}' }

      # set term caps
      set-option -sa terminal-features 'alacritty:256:clipboard:ccolour:cstyle:focus:mouse:RGB:strikethrough:title:usstyle'
      set-option -sa terminal-overrides 'alacritty:256:clipboard:ccolour:cstyle:focus:mouse:RGB:strikethrough:title:usstyle'

      # keybindings

      # unbind all
      unbind -a -T prefix
      unbind -a -T root
      unbind -a -T copy-mode
      unbind -a -T copy-mode-vi

      setw -g mode-keys vi
      set-option -g status-keys vi

      bind ';' command-prompt
      bind d detach-client

      bind BSpace new-window -c "#{pane_current_path}"
      bind Enter split-window -h -c "#{pane_current_path}"
      bind Tab split-window -v -c "#{pane_current_path}"

      # confirm before killing a window or the server
      bind g confirm kill-window

      # navigate tmux sessions
      bind-key Space new-window zsh -c "tmux list-sessions -F '#{session_name}' | fzf --preview-window=down,30% --preview 'tmux list-windows -t {}' --bind 'enter:become(tmux switch -t {})+abort'"

      # pane selection
      # bind F12 display-panes
      bind-key F12 switch-client -T direct

      # windows
      bind-key -T direct n select-window -t :1
	  bind-key -T direct e select-window -t :2
  	  bind-key -T direct i select-window -t :3
	  bind-key -T direct o select-window -t :4
      
      # pane selection
      bind-key -T direct h select-pane -t 1
      bind-key -T direct , select-pane -t 2
      bind-key -T direct . select-pane -t 3
      bind-key -T direct / select-pane -t 4

      # some movement
      # bind-key h last-window
      # bind-key k last-pane
      # bind -r m select-window -t :-
      # bind -r o select-window -t :+

      # fullscreen pane
      bind-key . resize-pane -Z
      # move to new window
      bind-key Y break-pane
      # rename
      bind-key , command-prompt 'rename-window %%'

      bind a copy-mode
      bind -T copy-mode-vi u send-keys -X cursor-up
      bind -T copy-mode-vi n send-keys -X cursor-left
      bind -T copy-mode-vi i send-keys -X cursor-right
      bind -T copy-mode-vi e send-keys -X cursor-down
      bind -T copy-mode-vi m send-keys -X start-of-line
      bind -T copy-mode-vi o send-keys -X end-of-line
      bind -T copy-mode-vi h send-keys -X page-down
      bind -T copy-mode-vi k send-keys -X page-up
      bind -T copy-mode-vi C-h send-keys -X history-bottom
      bind -T copy-mode-vi C-k send-keys -X history-top
      bind -T copy-mode-vi C-u send-keys -X previous-prompt
      bind -T copy-mode-vi C-e send-keys -X next-prompt
      bind -T copy-mode-vi Escape send-keys -X cancel
    '';
  };

}
