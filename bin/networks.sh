#!/bin/bash

PROGNAME=${0##*/}

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'

OPTION="$1"
TAG_ID="$2"

INSPECT="network inspect -f" 
FILTER=


Usage () {
    cat >&2 <<- EOF
usage: $PROGNAME OPTION TAG_ID

Options:
 --shell        Shell into [container_name]
 --inet      Inspect network by [container_name]
 --ipam         Check a networks ipam subnet by [inet_name]
 --stack        View IP's in [inet_name] stack network

EOF
exit 1
}

Error () {
    echo -e "-${PROGNAME%.*} error: $1\n" > /dev/stderr
    exit 1
}

parse_args () {
    case "$OPTION" in
        --inet ) inet_from_container_tag;;
        --ipam ) ipam_from_network_tag;;
        --stack ) inet_from_network_tag;;
        --shell ) get_shell;;
        -h | --help ) Usage;;
        * ) Error 'invalid option'
    esac
}

get_shell () {
    if ! $sh_c "docker exec -it $TAG_ID bash"; then
        Error "fatal !shell('${TAG_ID}')"
    fi
    echo -e "THANK YOU\nHAVE NICE DAY\n"
    exit 0
}

inet_from_container_tag () {
    INSPECT="inspect -f" 
    FILTER="'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'" 
    FILTER="$FILTER $TAG_ID"
}

ipam_from_network_tag () {
    FILTER="'{{range .IPAM.config}}{{.subnet}}{{end}}'"
    FILTER="$FILTER $TAG_ID"
}

inet_from_network_tag () {
    FILTER="'{{json .Containers}}'"
    FILTER="$FILTER $TAG_ID | jq '.[] | .Name + \":\" + .IPv4Address'"
}

main () {
    parse_args
    if [[ ! "$TAG_ID" =~ ^[[:alnum:]]+(\_|\-|[[:alnum:]])$ ]]; then
        Error "invalid identifier '$TAG_ID'"
    fi
    $sh_c "docker $INSPECT $FILTER"
}

if [ ! "$OPTION" ]; then
    Error 'requires arguments'
fi
main



