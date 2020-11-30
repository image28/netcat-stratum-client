#!/bin/bash
SERVER=""
PORT=""

# Logs into a stratum clinet and gets work
function login()
{
    printf '%s' "$(cat connect.json | head -n2)" | netcat -v -i1 -q10 $SERVER $PORT;
}

function work()
{
	DATE="`date +%Y.%j.%T`"
	login > joblog-$DATE
	
	HEIGHT=`cat joblog-$DATE | grep -iEo "height\":[0-9]*" | grep -iEo "[0-9]*" | tail -n1`
	NONCE=`hexdump -n 8 -e '4/4 "%08X" 1 "\n"' /dev/random | tr -d ' '`
	JOBID=`cat joblog-$DATE | grep -iEo "job_id\":[0-9]*" | grep -iEo "[0-9]*" | tail -n1`
	
	echo "Working on jobid $JOBID on date $DATE at height $HEIGHT with nonce of $NONCE"
	./mean31x8 -n $NONCE -a -t 8 -r 64 `cat joblog-$DATE | tail -n1 | rev | awk -F'"' '{print $2}' | rev` > worklog-$DATE
	
	#https://stackoverflow.com/questions/18892411/shell-script-to-trigger-a-command-with-every-new-line-in-to-a-file
	tail -f "worklog-$DATE" | while IFS='' read line; do
		WORK=`echo $line | grep -E --line-buffered "^nonce" | rev | awk -F' ' '{print $1 "," $2 "," $3 "," $4}' | rev &`
		submit "$NONCE" "$HEIGHT" "$JOBID" "$WORK"
		pidof mean31x8
		if test $? -ne 0
		then 
			echo "Solver thread has shutdown, shutting down in ten seconds..."
			sleep 10 && exit &
		fi
	done
}

function submit()
{
	login;
	NONCE="$1"
	HEIGHT="$2"
	JOBID="$3"
	POW="$4"
	echo "Submitting work"
	printf '%s' "$(cat submit.json | sed -E s/HEIGHT/$HEIGHT/ | sed -E s/JOBID/$JOBID/ | sed -E s/NONCE/$NONCE/ | sed -E s/POW/$POW/)" # | netcat -v -i1 -q10 $SERVER $PORT;
	
}

function status()
{
	printf '%s' "$(cat connect.json)"| grep -v "getworktemplate" | netcat -v -i1 -q10 $SERVER $PORT;
}
