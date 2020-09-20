#!/bin/bash
SERVER=""
PORT=""

# Logs into a stratum clinet and gets work
function login()
{
    printf '%s' "$(cat connect.json)" | netcat -v -i1 -q10 $SERVER $PORT;
}