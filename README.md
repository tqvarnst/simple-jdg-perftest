simple-jdg-perftest
===================

Project runs a simple performance test to a local JDG installation. To be able to run it you need a setting.xml correctly setup (see example)

You also need to start a JDG 6.1 with the following entry in configuratio (for example standalone.xml)

	<local-cache name="HotRodcache" start="EAGER"/>

To build and run the test do the following

	mvn clean install

	mvn assembly:single

	java -Xms1303m -Xmx1303m -jar target/jdg-perftest-client-jar-with-dependencies.jar 4 10 100 10


The parameters is
 - first is number of threads
 - second is number of entries per thread
 - third is size of each entry
 - fourth is wait/sleep time between entries in ms


TODO:
 * Add hotrod configuration
 * Add referense how to setup a local repository


 


