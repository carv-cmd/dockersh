#!/bin/bash

# Fix orphaned swarm nodes
# [Stuck in DOWN state]

PROGNAME=${0##*/}

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && set -x #sh_c='echo'

SWARM_PORT=${SWARM_PORT:-2377}
REGEX_ADDR='10\.([0-9]{1,3}\.){2}[0-9]{1,3}'

WORKER="${1:-dockpi}"
LEAVE_SWARM='docker swarm leave --force > /dev/stderr'
JOIN_SWARM=  # 'docker swarm join --token $TOKEN $RETURN_ADDR


Usage () {
    cat >&2 <<- EOF
usage: $PROGNAME WORKER

Generate swarm worker token and add WORKER node to swarm.

[WORKER]
 Hostname from '~/.ssh/config' configurations
 Standard CLI arguments for \`rsh\` (quoted)

EOF
exit 1
}

Error () {
    echo -e "\n-${PROGNAME%.*} error: $1\n" > /dev/stderr
    exit 1
}

prepare_join_command () {
    # Build `docker swarm join ...`
    local RETURN_ADDR="`nslookup_return_route`:$SWARM_PORT"
    local DOCK_TOKEN=" `load_swarm_token`"
    JOIN_SWARM="docker swarm join --token $DOCK_TOKEN $RETURN_ADDR"
}

nslookup_return_route () {
    # WSL2 runs under NAT(172.22.32.x), needs ip on 10.x
    if ! nslookup $NAME | grep -Eo "$REGEX_ADDR"; then
        Error 'no `return-to-sender` ip-address'
    fi
}

load_swarm_token () {
    # Get worker join-swarm token.
    if ! $sh_c "docker swarm join-token worker -q"; then
        Error 'load token failed'
    fi
}

kill_orphans () {
    manage_over_rsh "$LEAVE_SWARM"
    if docker node inspect $WORKER &> /dev/null; then
        safe_reset
        remove_named_node
    fi
}

safe_reset () {
    TMOUT=30
    while true; do
        if (( $TMOUT == 0 )); then
            Error 'node alive past timeout'
        elif ! docker node inspect $WORKER --pretty | grep -q 'State:.*Down'; then
            echo -ne "\rnode[!Down]: timeout($TMOUT)"
            TMOUT=$(( TMOUT - 1 )); sleep 1
        else
            break
        fi
    done
}

remove_named_node () {
    # Flush any hanging $WORKER nodes.
    if ! $sh_c "docker node rm '$WORKER'"; then
        Error "remove: $WORKER failed"
    fi
}

manage_over_rsh () {
    local COMMAND_CALL="$1"
    if ! $sh_c "rsh $WORKER '$COMMAND_CALL'"; then
        return 1
    fi
    return 0
}

main () {
    prepare_join_command
    kill_orphans
    manage_over_rsh "$JOIN_SWARM"
}

if [[ "$WORKER" =~ -?-h(elp)? ]]; then
    Usage
fi
main
docker node ls

