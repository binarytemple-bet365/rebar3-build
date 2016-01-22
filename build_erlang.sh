#!/bin/bash -ev
#
# run build and test (unit and integration)
#


ERLANG_APP=$1
BUILD_DIR=$2
SSH_USER=$3

PATH="$PATH:/build"

function agent_notice {
    cat <<-EOF

This script requires that you have a ssh-agent running, and have loaded the
required key(s) to
   a) access all git repositories listed in the sources code dependencies
   b) can connect to the test machine(s) without the need for further input of
      authentication information.
       
EOF
}


#
# write configuration info to 
#
function setup_ssh {   
    USERNAME=$1

    mkdir -p ~/.ssh

        cat >>~/.ssh/config <<-EOF
HOST *
    User $USERNAME
    StrictHostKeyChecking no
EOF

}

#
# ensure that agent is available and loaded with key
#
function check_agent {
    agent_line=`ssh-add -l 2>&1`

    case "${agent_line}" in
        [0-9][0-9][0-9][0-9]\ [[:alnum:]]*)
           echo "have key: $agent_line"
        ;;
        "The agent has no identities.")
            echo
            echo "Have reached ssh-agent, the agent has no id's loaded."

            agent_notice
            exit -1
        ;;    
        "Could not open a connection to your authentication agent.")
            echo
            echo "Could not contact agent"

            agent_notice
            exit -1
        ;;
        *)
            echo
            echo "unknown agent reply: ${agent_line}"
            
            agent_notice
            exit -1
        ;;
    esac
}


#########################################
#      PRE FLIGHT CHECKS                #
#########################################
# do we have a loaded agent running? Then set up the ssh configuration
check_agent
setup_ssh $SSH_USER

# check that more than one CPU is present, otherwise race conditions have it too easy to slip by.
cpu_count=`cat /proc/cpuinfo | grep '^processor' | wc -l`
if [ $cpu_count -lt 2 ]
 then
   echo "test environment requires at least 2 cpus to catch a number of race conditions."
   echo "Only ${cpu_count} cpus detected, terminating"
   exit -1
 fi

#########################################
#      START BUILD                      #
#########################################

if [ -d "${BUILD_DIR}/QuPerl_local" ]
 then
  rm -rf "${BUILD_DIR}/QuPerl_local"
 fi

cp -a "${ERLANG_APP}" "${BUILD_DIR}/QuPerl_local"

pushd "${BUILD_DIR}/QuPerl_local"

# remove eclipse fluff
rm -f ebin/*.beam ebin/quickstart.app

rebar3 deps
rebar3 as test eunit
rebar3 as test dialyzer

rebar3 as prod compile
rebar3 as prod release tar

# set minimal test configuration to run everything on local host
echo "{host_info, {master, \"${PWD}\"}}." >test/test.config

# force start of epmd
erl -sname epmd-boot -noshell -run init stop

rebar3 ct

# pack up the test results
TIMESTAMP=`date "+%Y%m%d_%H%M"`

tar cf "/erlang_app/ct_logs_${TIMESTAMP}.tgz" -C "${BUILD_DIR}/QuPerl_local/_build/test" logs
