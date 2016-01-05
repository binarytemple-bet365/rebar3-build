# rebar3-build
This is a executing docker container that will build erlang projects, using rebar3.

You must supply the connection to a SSH-Agent loaded with the needed keys, if you are accessing private repositories for your dependencies.

Also the source code has to be available to the filesystem of the docker host. This can done by mounting network filesystems (e.g. nfs, cifs, etc.) or via shared folders in a VirtualBox Docker VM (e.g. docker-machine).

docker run --rm --name build_test\
           -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK\
           -e SSH_AUTH_SOCK\
           -v $ERLANG_SRC_DIR:/erlang_app pt_erlang_build\
           [$USERNAME]

ERLANG_SRC_DIR is the directory containing the rebar.config file. 

USERNAME is the name of the user that fits with the key data given via the SSH-agent. Default is the current user

If you are using docker-machine on windows, you have to log into the docker-host, as the docker-machine script mangles the file names.
