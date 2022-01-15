#!/bin/bash

PROGNAME=${0##*/}

sh_c='echo'
ECHO=${ECHO:-}
USERID="$(id -u)"

SOURCE_URL="https://github.com/docker/compose/releases/download"
SOURCE_REPO="${SOURCE_URL}/1.29.2/docker-compose-$(uname -s)-$(uname -m)"
SAVE_LOCATION=/usr/local/bin/docker-compose


Error () {
    echo -e "-${PROGNAME%.*} error: $1\n" > /dev/stderr
    exit 1
}

command_exists () {
    if command -v docker-compose; then
        Error 'found docker-compose'
    fi
}

permissions () {
    if [ "$USERID" == 0 ]; then
        sh_c='sh -c'
    else
        sh_c='sudo -E sh -c'
    fi
    [ "$ECHO" ] && sh_c="echo $sh_c"
}

curl_source () {
    if ! $sh_c "curl -L $SOURCE_REPO -o $SAVE_LOCATION"; then
        Error 'curl failed'
    fi
}

privilege_compose () {
    if ! $sh_c "chmod +x $SAVE_LOCATION"; then
        Error 'chmod failed'
    fi
}

test_suite () {
    if ! test_compose; then
        compose_symlink 
        if ! test_compose; then
            Error 'installation failed'
        fi
    fi
}

compose_symlink () {
    if ! $sh_c "ln -s $SAVE_LOCATION /usr/bin/docker-compose"; then
        Error 'couldnt symlink'
    fi
}

test_compose () {
    if ! $sh_c "docker-compose --version"; then
        return 1
    fi
}

main () {
    permissions
    curl_source
    privilege_compose
    test_suite
}

command_exists
main

