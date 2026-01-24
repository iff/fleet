{ pkgs, ... }:

let
  git-ssh-dispatch = pkgs.writeScriptBin "git-ssh-dispatch" ''
    #!/usr/bin/env zsh
    set -eu -o pipefail

    # this script roughly acts like openssh
    # at least in terms of how git uses it

    if [[ $1 == '-G' && $# == 2 ]]; then
        ssh $@
        exit
    fi

    if [[ ! $2 =~ "git-(upload|receive)-pack '(.*)'" && $# == 2 ]]; then
        echo 'unexpected form' $@ >&2
        exit 1
    fi

    target=$1:$match[2]

    case $target in

        (git@github.com:dkuettel/*)
            key=private
            user="Yves Ineichen iff@yvesineichen.com"
            ;;

        (git@github.com:/dkuettel/*)
            key=private
            user="Yves Ineichen iff@yvesineichen.com"
            ;;

        (git@github.com:iff/*)
            key=private
            user="Yves Ineichen iff@yvesineichen.com"
            ;;

        (git@github.com:/iff/*)
            key=private
            user="Yves Ineichen iff@yvesineichen.com"
            ;;

        (git@github.com:mbssacosta/*)
            key=private
            user="Yves Ineichen iff@yvesineichen.com"
            ;;

        (git@github.com:dakies/*)
            key=private
            user="Yves Ineichen iff@yvesineichen.com"
            ;;

        (git@tangled.org:iff.io/*)
            key=private
            user="Yves Ineichen iff@yvesineichen.com"
            ;;

        (git@github.com:wereHamster/*)
            key=private
            user="Yves Ineichen iff@yvesineichen.com"
            ;;

        (*)
            echo 'no match for' $target >&2
            exit 1
            ;;

    esac

    if [[ -e .git && -v user ]]; then
        if ! actual="$(git config --get user.name) $(git config --get user.email)"; then
            echo 'no git user is set instead of' $user >&2
            exit 1
        fi
        if [[ $actual != $user ]]; then
            echo 'git user is' $actual 'but expected' $user >&2
            exit 1
        fi
    fi

    echo $target '->' $key >&2
    ssh -i ~/.ssh/$key $@
  '';

  gpr = pkgs.writeScriptBin "gpr" ''
    #!/usr/bin/env zsh
    set -eu -o pipefail

    gh pr create --editor --fill-verbose
  '';

  wt = pkgs.writeScriptBin "wt" ''
    #!/usr/bin/env zsh
    set -eu -o pipefail

    name=''${1?-worktree name}
    [[ ! -v 2 ]]

    sha=$(git rev-parse HEAD)
    git worktree add --detach $(realpath wt/$name) $sha
    # maybe zsh subshell in this path and remove/purge when returning?
    echo "new tree: $(realpath wt/$name)"
  '';
in
{
  home.packages = [
    pkgs.gh
    pkgs.git
    pkgs.jujutsu
    pkgs.moreutils
    #
    git-ssh-dispatch
    gpr
    wt
  ];

  xdg.configFile."git/config".source = ./git-config;
  xdg.configFile."jj/config.toml".source = ./jujutsu-config.toml;
}
