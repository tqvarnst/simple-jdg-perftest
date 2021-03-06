#!/bin/bash
SCRIPT_PATH=`readlink -f $0`
SCRIPT_DIR=`dirname ${SCRIPT_PATH}`
echo ${SCRIPT_DIR}
pushd $SCRIPT_DIR > /dev/null

TESTNAME=test1async

let numThreads=10
let numEntries=0
let valueSize=1024
let sleepTime=50
let sleepInterval=2000
async=true

# input values for the test scenario
let startvalue=200000
let increment=200000
let endvalue=1000000

JDG_HOME=/home/infinispan/jboss-datagrid-server-6.1.0
JAVA_OPS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -Xms13030m -Xmx13030m -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/home/infinispan/jdg-client-gc.log"
RUNNABLE_CLIENT_JAR=jdg-perftest-client-jar-with-dependencies.jar
SERVER_CPU_PIN=0-3
CLIENT_CPU_PIN=22-31

#Cleaning out prevois logs
rm -rf logs/${TESTNAME}

# make sure the initial log directories are created.
mkdir -p logs/$TESTNAME/cpu
mkdir -p logs/$TESTNAME/network
mkdir -p logs/$TESTNAME/server
mkdir -p logs/$TESTNAME/client

echo "start CPU monitoring"
mpstat -P ALL 2 > logs/$TESTNAME/cpu/cpu.out &
CPU_PID=$!

echo "start SAR monitoring"
sar -n DEV 2 > logs/$TESTNAME/network/sar.out &
SAR_PID=$!

let testindex=1

for (( numEntries=$startvalue; numEntries<=$endvalue; numEntries+=$increment ))
do
	# Start the datagrid	
	taskset -c ${SERVER_CPU_PIN} ${JDG_HOME}/bin/standalone.sh > logs/$TESTNAME/server/out.log 2>&1 &
	#echo "Starting JDG server"
	sleep 5	
	JDG_PID=`ps -ef | grep Standalone | grep -v grep | awk '{print $2}'`

	if [[ "$JDG_PID" = "" ]]; then
		echo "JDG Service didn't start correctly"
		exit 1
	fi 
	#echo "Server is running with PID $JDG_PID"

	echo -n "$(date +%H:%M:%S) TEST $testindex: entries=$numEntries, took="

	# This command will run the java client and store the output in it's own file, and att the same time extrapolate the run time. To avoid System.err message which is printed as INFO that the cache manager is started 2 is directed to the same file
	taskset -c ${CLIENT_CPU_PIN} java $JAVA_OPS -jar ${RUNNABLE_CLIENT_JAR} ${numThreads} ${numEntries} ${valueSize} ${sleepTime} ${sleepInterval} ${async} 2>logs/$TESTNAME/client/test${testindex}.out | tee logs/$TESTNAME/client/test${testindex}.out | grep "It took" | awk '{ printf $3 }'


	echo "ms, endtime=$(date +%H:%M:%S)"
	
	sleep 2

	#echo "Stopping JDG server"
	kill $JDG_PID
	sleep 3	
	JDG_PID=`ps -ef | grep Standalone | grep -v grep | awk '{print $2}'`
	if [[ "$JDG_PID" != "" ]]; then
		echo "JDG Service didn't stop correctly, killing it"
		kill -9 $JDG_PID
	fi
	let testindex++
done

kill $SAR_PID
kill $CPU_PID
popd > /dev/null
