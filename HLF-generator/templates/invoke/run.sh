#!/bin/bash

function run {
    filename=$1
    shift
    node dist/$filename $@
}

if [ $# -eq 0 ]; then
    rm -rf dist
    rm -rf wallets
    npm run build
elif [ $1 == 'make' ]; then
    shift
    run 'set' $@
    node dist/enrollAdmin
    node dist/registerUser
else
    run $@
fi


