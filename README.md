simple-jdg-perftest
===================

Project runs a simple performance test to a local JDG installation. To be able to run it you need a setting.xml correctly setup (see example)

To build and run the test do the following

	mvn clean install

	mvn assembly:single

	java -jar target/simple-jdg-perftest.jar 4 100 4096 10


The parameters is
 - first is number of threads
 - second is number of entries per thread
 - third is size of each entry
 - fourth is wait/sleep time between entries in ms


 


