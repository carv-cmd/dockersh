#! /usr/bin/env bash

set -e

STACK_NAME="$1"

if ! docker stack ps $STACK_NAME &> /dev/null; then
    docker stack deploy -c <(docker-compose config) $STACK_NAME
else
    docker stack rm $STACK_NAME
fi
