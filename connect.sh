#!/bin/bash
SERVER=""
PORT=""

# Logs into a stratum clinet and gets work
function login()
{
    printf '%s' "$(cat connect.json)" | netcat -v -i1 -q10 $SERVER $PORT;
}

function work()
{
	DATE="`date +%Y.%j.%T`"
	login > joblog-$DATE
	
	HEIGHT=`cat joblog-$DATE | grep -iEo "height\":[0-9]*" | grep -iEo "[0-9]*"`
	NONCE=`hexdump -n 8 -e '4/4 "%08X" 1 "\n"' /dev/random`
	JOBID=`cat joblog-$DATE | grep -iEo "job_id\":[0-9]*" | grep -iEo "[0-9]*"`
	
	echo "Working on jobid $JOBID on date $DATE at height $HEIGHT with nonce of $NONCE"
	./mean31x8 -n $NONCE -a -t 8 -r 64 `cat joblog-$DATE | tail -n1 | rev | awk -F'"' '{print $2}' | rev` > worklog-$DATE
	WORK=`cat worklog-$DATE | grep nonce | rev | awk -F' ' '{print $1 "," $2 "," $3 "," $4}' | rev`
	
	submit "$NONCE" "$HEIGHT" "$JOBID" "$WORK"
}

function submit()
{
	login;
	NONCE="$1"
	HEIGHT="$2"
	JOBID="$3"
	WORK="$4"
	echo "Submitting work"
	printf '%s' "$(cat submit.json | sed -E s/HEIGHT/$HEIGHT/ | sed -E s/JOBID/$JOBID/ | sed -E s/NONCE/$NONCE/ | sed -E s/POW/$POW/)" # | netcat -v -i1 -q10 $SERVER $PORT;
	
}

function status()
{
	printf '%s' "$(cat connect.json)"| grep -v "getworktemplate" | netcat -v -i1 -q10 $SERVER $PORT;
}
