# rebar3-build
This is a executing docker container that will build erlang projects, using rebar3.

You must supply the connection to a SSH-Agent loaded with the needed keys, if you are accessing private repositories for your dependencies.

docker run --rm --name build_test\
           -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK\
           -e SSH_AUTH_SOCK\
           -v $ERLANG_SRC_DIR:/erlang_app pt_erlang_build\
           [$USERNAME]

ERLANG_SRC_DIR is the directory containing the rebar.config file

USERNAME is the name of the user that fits with the key data given via the SSH-agent. Default is the current user
