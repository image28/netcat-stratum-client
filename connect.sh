#!/bin/bash
SERVER=""
PORT=""

# Logs into a stratum clinet and gets work
function work()
{
	DATE="`date +%Y.%j.%T`"
	cat connect.json | head -n2 | netcat -v -i1 -q2 $SERVER $PORT >> joblog-$DATE
	
	HEIGHT=`cat joblog-$DATE | grep -iEo "height\":[0-9]*" | grep -iEo "[0-9]*" | tail -n1`
	NONCE=`hexdump -n 8 -e '4/4 "%08X" 1 "\n"' /dev/random | tr -d ' '`
	JOBID=`cat joblog-$DATE | grep -iEo "job_id\":[0-9]*" | grep -iEo "[0-9]*" | tail -n1`
	
	echo "Working on jobid $JOBID on date $DATE at height $HEIGHT with nonce of $NONCE"
	./lean32x8 -n $NONCE -t 24 -r64 `cat joblog-$DATE | tail -n1 | rev | awk -F'"' '{print $2}' | rev` | while IFS=$'\n' read line; 
	do
		echo "$line"
		POW=`echo $line | grep -E "^Solution" | cut -c10- | sed -e s/" "/","/g`
		if ! test -z $POW; 
		then
			cat connect.json | grep -v "getworktemplate" | netcat -v -i1 -q2 $SERVER $PORT >> joblog-$DATE
			sleep 1
			echo "Submitting work"
			cat submit.json | sed -E s/HEIGHT/$HEIGHT/ | sed -E s/JOBID/$JOBID/ | sed -E s/NONCE/$NONCE/ | sed -E s/POW/$POW/ | netcat -v -i1 -q2 $SERVER $PORT;
			pidof lean32x8
			if test $? -ne 0
			then 
				echo "Solver thread has shutdown, shutting down in ten seconds..."
				sleep 10 && break
			fi
			
			echo -e "DATE: `date`\nNONCE: $NONCE\nHEIGHT: $HEIGHT\nJOB: $JOBID\nPOW: $POW\n" >> "submitted-$DATE"
		fi
		sleep 0.2
	done 
}
