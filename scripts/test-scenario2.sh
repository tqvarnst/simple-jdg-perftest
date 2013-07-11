
SCRIPT_DIR=`dirname $(readlink -f $0)`
pushd $SCRIPT_DIR > /dev/null

TESTNAME=test2

let numThreads=0
let numEntries=50000
let valueSize=1024
let sleepTime=5
let sleepInterval=200
async=true

# input values for the test scenario
let startvalue=0
let increment=5
let endvalue=20

JDG_HOME=/home/tqvarnst/Desktop/jboss-datagrid-server-6.1.0

#Cleaning out prevois logs
rm -rf logs

# make sure the initial log directories are created.
mkdir -p logs/$TESTNAME/cpu
mkdir -p logs/$TESTNAME/network
mkdir -p logs/$TESTNAME/server
mkdir -p logs/$TESTNAME/client

echo "Before staring it's recommended to run 'mpstat -P ALL 2 | tee logs/$TESTNAME/cpu/cpu.out' in another terminal"
echo -n "Press [ENTER]:"
read continue
 
let testindex=1

for (( numThreads=$startvalue; numThreads<=$endvalue; numThreads+=$increment ))
do
	# Check for NULL Threads corner case
	if [[ "$numThreads" = "0" ]]; then
		let numThreads=1
	fi
	# Start the datagrid	
	taskset -c 0 ${JDG_HOME}/bin/standalone.sh > logs/$TESTNAME/server/out.log 2>&1 &
	#echo "Starting JDG server"
	sleep 5	
	JDG_PID=`ps -ef | grep Standalone | grep -v grep | awk '{print $2}'`

	if [[ "$JDG_PID" = "" ]]; then
		echo "JDG Service didn't start correctly"
		exit 1
	fi 
	#echo "Server is running with PID $JDG_PID"

	echo -n "$(date +%H:%M:%S) TEST $testindex: clients=$numThreads, took="

	# This command will run the java client and store the output in it's own file, and att the same time extrapolate the run time. To avoid System.err message which is printed as INFO that the cache manager is started 2 is directed to the same file
	taskset -c 1 java -Xms512m -Xmx512m -jar ../target/jdg-perftest-client-jar-with-dependencies.jar ${numThreads} ${numEntries} ${valueSize} ${sleepTime} ${sleepInterval} ${async} 2>logs/$TESTNAME/client/test${testindex}.out | tee logs/$TESTNAME/client/test${testindex}.out | grep "It took" | awk '{ printf $3 }'


	echo "ms, endtime=$(date +%H:%M:%S)"

	if [[ "$numThreads" = "1" ]]; then
		let numThreads=0
	fi	
	
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
popd > /dev/null
