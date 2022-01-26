#!/usr/bin/env bash

PROGNAME=${0##*/}

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'

SCRIPTS=~/bin/dockersh/bin
EXECUTE="$1"; shift
ARGS="$@"


Usage () {
    cat >&2 <<- EOF
usage: $PROGNAME SUBCMD [ARGS]

Subcommands:
 stack-up   Docker stack-up/teardown
 tokens     Distribute swarm keys.
 networks   Inspect docker networking.
 exec       Container shell.
 
EOF
exit 1
}

Error () {
    echo -e "-${PROGNAME%.*} error: $1\n" > /dev/stderr
    exit 1
}

check_script () {
    EXECUTE="$SCRIPTS/$EXECUTE.sh"
    if [ ! -x "$EXECUTE" ]; then
        Error 'no screept'
    fi
}

main () {
    check_script
    if ! $sh_c "$EXECUTE $ARGS"; then
        Error 'fatal error'
    fi
}

if [ ! "$EXECUTE" ]; then
    Usage
elif [[ "$EXECUTE" =~ -?-h(elp)? ]]; then
    Usage
else
    main
fi

