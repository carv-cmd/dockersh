#!/bin/bash

PROGNAME=${0##*/}

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'

Usage () {
    cat >&2 <<- EOF
usage: $PROGNAME
EOF
}

Error () {
    echo -e "-${PROGNAME%.*} error: $1\n" > /dev/stderr
    exit 1
}

main () {
    if ! $sh_c "docker exec -it $IDENTIFIER bash"; then
        Error 'docker exec failed'
    fi
}

IDENTIFIER="$1"
main

