package com.jboss.datagrid.peftest;

import java.io.IOException;

import org.infinispan.client.hotrod.RemoteCache;

public final class SyncLoaderTask implements Runnable {

    private final String name;

    private final long startKey;

    private final int entryCount;

    private final int valueSize;

    private long sleepTime;
    
    private long sleepInterval;

    private final byte[] value;

    private RemoteCache<Long, byte[]> cache;

    private long key;


    public SyncLoaderTask(RemoteCache<Long, byte[]> cache, String name, long startKey, int entryCount,
            int valueSize, long sleepTime, long sleepInterval) throws IOException {
        super();
        this.cache = cache;
        this.name = name;
        this.startKey = startKey;
        this.entryCount = entryCount;
        this.valueSize = valueSize;
        this.sleepTime = sleepTime;
        this.sleepInterval = sleepInterval;
        value = new byte[valueSize];
    }

    public void run() {
        try {
            runInternal();
        } catch (Exception e) {
            throw new RuntimeException("exception in task '" + name + "'", e);
        }
    }

    private void runInternal() throws Exception {

        key = startKey;

        System.out.println("starting task '" + name + "', start key is " + startKey);

        final long startTime = System.currentTimeMillis();
        for (int i = 0; i < entryCount; i++) {
        	cache.put(key++, value);
         	// We will sleep the value of start parameter 4 every X message, where X is start parameter 5
            if (i % sleepInterval == 0) {
                Thread.sleep(sleepTime);
            }
        }
        
        final long endTime = System.currentTimeMillis();
        
        double totalExecTime = (Double.valueOf(endTime) - Double.valueOf(startTime)) / 1000.0;
        
        String resultString = "Task '%s' took %.2f seconds to write %d entries of total size %d bytes\n";
        System.out.printf(resultString, name, totalExecTime, entryCount, entryCount * valueSize);
    }
}
