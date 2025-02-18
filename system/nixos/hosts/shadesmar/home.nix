{ pkgs, ... }:

let
  # TODO what template to use? and where to get it from?
  mkenv = pkgs.writeScriptBin "mkenv"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      env=$HOME/envs/$1
      mkdir -p $env
      echo 'use flake ./nn/nn' > $env/.envrc
      echo 'export NN_XPS_CACHE=$HOME/.cache/xps' >> $env/.envrc
      echo 'export nn=$(realpath ./nn)' >> $env/.envrc
      cd $env
      tmux new-session -s $1
      # tmux new-session -e NN_XPS_CACHE=$HOME/.cache/xps -e nn=$env/nn -s $1
    '';

  git-clone-nn = pkgs.writeScriptBin "git-clone-nn"
    ''
      #!/usr/bin/env zsh
      set -eux -o pipefail

      # checkout and configure an nn repository
      dir=$1

      if [[ ! -e $dir ]]; then
          git clone git@github.com:ThingWorx/neural-networks.git $dir
          (
              cd $dir

              git config user.name 'Yves Ineichen'
              git config user.email 'yineichen@ptc.com'

              nn/setup/install-hooks
          )
      fi
    '';

  gcnn = pkgs.writeScriptBin "gcnn"
    ''
      #!/usr/bin/env zsh
      set -eux -o pipefail

      dir=$(realpath ./nn)
      git-clone-nn $dir

      branch=$(basename $PWD)
      (
        cd $dir
        git checkout -b yi/$branch
      )
    '';

  nnpr = pkgs.writeScriptBin "nnpr"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      branch=$1
      dir=/tmp/nn-$(echo $1 | tr '/' '-')
      git-clone-nn $dir

      cd $dir/nn
      git checkout $branch
      session=nnpr-$1
      tmux new-session -s $session -d nvim -c :Gclog
    '';

  wt = pkgs.writeScriptBin "wt"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      name=''${1?-worktree name}
      [[ ! -v 2 ]]

      sha=$(git rev-parse HEAD)
      git worktree add --detach $(realpath ../../$name) $sha
      # maybe zsh subshell in this path and remove/purge when returning?
      echo "new tree: $(realpath ../../$name/nn)"
    '';

  primt = pkgs.writeScriptBin "primt"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      gh pr create --editor --fill-verbose --title "FOCUSSDK-78996: "
    '';

  prmt = pkgs.writeScriptBin "prmt"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      gh pr create --editor --fill-verbose --title "FOCUSSDK-62130: "
    '';

  prb = pkgs.writeScriptBin "prb"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      gh pr create --editor --fill-verbose --title "FOCUSSDK-62799: "
    '';

  # TODO aliases?
  kssh = pkgs.writeScriptBin "kssh"
    ''
      #!/usr/bin/env zsh
      set -eux -o pipefail

      kubectl exec -it $1 -- /bin/bash
    '';

  s3v = pkgs.writeScriptBin "s3v"
    ''
      #!/usr/bin/env zsh
      set -eux -o pipefail

      aws s3 cp $1 - | nvim +':setlocal buftype=nofile' -
    '';

  s3ls = pkgs.writeScriptBin "s3ls"
    ''
      #!/usr/bin/env zsh
      set -eux -o pipefail

      aws s3 ls $1
    '';

  tb = pkgs.writeScriptBin "tb"
    ''
      #!/usr/bin/env zsh
      set -eux -o pipefail

      source $nn/nn/.venv/bin/activate
      tensorboard --port 6006 --load_fast=false --logdir=$1
    '';

  drun = pkgs.writeScriptBin "drun"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      # mount a repository file at /xp/src/..
      # function repo_mount  {
      #     args+=(--mount type=bind,source=$1,destination=/xp/src)
      # }

      # "identity" mount a folder (meaning same path on host and in container)
      function id_mount {
          args+=(--mount type=bind,source=''${1:a},destination=''${1:a})
      }

      nn_dir=$nn
      echo "using nn dir=$nn_dir"

      # docker arguments
      args=()

      # interactive
      args+=(--interactive --tty --rm --detach-keys 'ctrl-@,x,x' --privileged)

      # docker in docker
      # args+=(-v /var/run/docker.sock:/var/run/docker.sock)

      args+=(--env NN_S3_CACHE=/data/cache/deep-learning-data)
      args+=(--env NN_XPS_CACHE)
      args+=(--env NN_USER=yineichen)

      args+=(--env AWS_DEFAULT_REGION=eu-west-1)
      args+=(--env AWS_ACCESS_KEY_ID)
      args+=(--env AWS_SECRET_ACCESS_KEY)

      # args+=(--env PYTHONMALLOC=malloc)
      # args+=(--env TF_CPP_MIN_LOG_LEVEL=0)

      # force TF to run on CPU
      # args+=(--env CUDA_VISIBLE_DEVICES="")

      args+=(--env PYTHONBREAKPOINT=IPython.embed)
      args+=(--env DISPLAY=:0)

      # aws config
      # args+=(-v $HOME/.aws:/home/localuser/.aws)

      # home
      # NOTE we need .Xauthority to get X11 inside -- so if we ever stop mounting home!
      # TODO only 
      #   .aws
      #   .Xauthority
      if [ $(pwd) != $HOME ]; then
          id_mount $HOME
      fi

      id_mount /efs
      id_mount /scratch
      id_mount /data
      id_mount /s3

      # id_mount /tmp

      # mount sources over docker sources
      # TODO do we really want this? we anyway build the docker image just before runnning
      # repo_mount $nn_dir

      # workdir is pwd
      # TODO use non-repo dir?
      id_mount $(pwd)
      args+=(--workdir $(pwd))

      # user
      args+=(--user 1000)

      # limit memory
      args+=(--memory "25g")
      args+=(--shm-size=4gb)
      #args+=(--memory-swap "0")

      args+=(--pid=host)
      args+=(--net=host)

      sha=$($nn/nn/docker/build nn-dev)
      docker run --device=nvidia.com/gpu=all $args $sha $@ |& tee out/docker.log
    '';

  dx = pkgs.writeScriptBin "dx"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      # run x in docker

      # "identity" mount a folder (meaning same path on host and in container)
      function id_mount {
          args+=(--mount type=bind,source=''${1:a},destination=''${1:a})
      }

      # docker arguments
      args=()

      # interactive
      args+=(--interactive --tty --rm --detach-keys 'ctrl-@,x,x' --privileged)

      args+=(--env NN_S3_CACHE=/data/cache/deep-learning-data)
      args+=(--env NN_XPS_CACHE)
      args+=(--env NN_USER=yineichen)

      args+=(--env AWS_DEFAULT_REGION=eu-west-1)
      args+=(--env AWS_ACCESS_KEY_ID)
      args+=(--env AWS_SECRET_ACCESS_KEY)

      args+=(--env PYTHONBREAKPOINT=IPython.embed)
      args+=(--env DISPLAY=:0)

      # aws config
      id_mount $HOME/.aws
      id_mount $HOME/.Xauthority
      id_mount $HOME/.cache

      args+=(-v /var/run/docker.sock:/var/run/docker.sock)
      args+=(--group-add $(stat -c '%g' /var/run/docker.sock))

      # data
      id_mount /efs
      id_mount /scratch
      id_mount /data
      id_mount /s3

      # mount github directory for gha weekly updates
      args+=(--mount type=bind,source=$nn/.github,destination=/xp/src/nn/.github)

      # mount pwd
      # NOTE this cant contain bin/build otherwise we dont use the fallback
      # if it exists?
      id_mount $(pwd)/out

      # workdir is pwd
      args+=(--workdir $(pwd)/out)

      # user
      args+=(--user 1000)

      # limit memory
      # args+=(--memory "25g")
      args+=(--shm-size=4gb)

      args+=(--pid=host)
      args+=(--net=host)

      sha=$($nn/nn/docker/build nn-dev)
      docker run --device=nvidia.com/gpu=all $args $sha python -m nn.xpman $@
    '';

  dgha = pkgs.writeScriptBin "dgha"
    ''
      #!/usr/bin/env zsh
      set -eu -o pipefail

      args=()
      args+=(--interactive --tty --rm)
      args+=(--mount type=bind,source=$nn/.github,destination=/xp/src/nn/.github)
      args+=(--user 1000)
      # args+=(--pid=host)
      # args+=(--net=host)

      sha=$($nn/nn/docker/build nn-dev)
      docker run $args $sha python -m nn.xpman.e2e.benchmarking gha-weekly-jobs
    '';
in
{
  home.packages = with pkgs; [
    geeqie
    # work
    awscli2
    ssm-session-manager-plugin
    gh
    # own
    mkenv
    git-clone-nn
    gcnn
    nnpr
    kssh
    s3v
    s3ls
    tb
    drun
    dx
    dgha
    wt
    prb
    prmt
    primt
  ];

  services.blueman-applet.enable = true;

  dots = {
    profiles = {
      dwm.enable = true;
      linux.enable = true;
    };
    alacritty = {
      enable = true;
      font_size = 12.0;
      font_normal = "ZedMono Nerd Font";
    };
    osh.enable = true;
    syncthing.enable = true;
    zen.enable = true;
  };
}
