#!/bin/bash
SERVER="mwc.2miners.com"
PORT="1111"

# Logs into a stratum clinet and gets work
function work()
{
	DATE="`date +%Y.%j.%T`"
	printf '%s' "$(cat connect.json | head -n2)" | netcat -v -i1 -q2 $SERVER $PORT > joblog-$DATE
	
	HEIGHT=`cat joblog-$DATE | grep -iEo "height\":[0-9]*" | grep -iEo "[0-9]*" | tail -n1 > .height`
	NONCE=`hexdump -n 8 -e '4/4 "%08X" 1 "\n"' /dev/random | tr -d ' ' > .nonce`
	JOBID=`cat joblog-$DATE | grep -iEo "job_id\":[0-9]*" | grep -iEo "[0-9]*" | tail -n1 > .id`
	
	echo "Working on jobid $JOBID on date $DATE at height $HEIGHT with nonce of $NONCE"
	./mean31x8 -n $NONCE -a -t 8 -r 256 `cat joblog-$DATE | tail -n1 | rev | awk -F'"' '{print $2}' | rev` | while IFS=$'\n' read line; 
	do
		POW=`echo $line`
		printf '%s' "$(cat connect.json)"| grep -v "getworktemplate" | netcat -v -i1 -q2 $SERVER $PORT
		sleep 1
		echo "Submitting work"
		printf '%s' "$(cat submit.json | sed -E s/HEIGHT/$HEIGHT/ | sed -E s/JOBID/$JOBID/ | sed -E s/NONCE/$NONCE/ | sed -E s/POW/$POW/)" #| netcat -v -i1 -q2 $SERVER $PORT;
		pidof mean31x8
		if test $? -ne 0
		then 
			echo "Solver thread has shutdown, shutting down in ten seconds..."
			sleep 10 && break
		fi
		
		sleep 0.2
	done
}
