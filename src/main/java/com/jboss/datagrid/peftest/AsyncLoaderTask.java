package com.jboss.datagrid.peftest;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import org.infinispan.client.hotrod.RemoteCache;
import org.infinispan.client.hotrod.RemoteCacheManager;
import org.infinispan.util.concurrent.NotifyingFuture;

public final class AsyncLoaderTask implements Runnable {

    private final String name;

    private final long startKey;

    private final int entryCount;

    private final int valueSize;

    private long sleepTime;
    
    private long sleepInterval;
    
    private boolean async;

    private final byte[] value;

    private RemoteCacheManager remoteCacheManager;

    private RemoteCache<Long, byte[]> cache;

    private long key;

    public AsyncLoaderTask(RemoteCacheManager remoteCacheManager, String name, long startKey, int entryCount,
            int valueSize, long sleepTime, long sleepInterval, boolean async) throws IOException {
        super();
        this.name = name;
        this.startKey = startKey;
        this.entryCount = entryCount;
        this.valueSize = valueSize;
        this.sleepTime = sleepTime;
        this.sleepInterval = sleepInterval;
        this.async = async;
        
        value = new byte[valueSize];
        //		Properties hotrodProps = new Properties();
        //		hotrodProps.load(Thread.currentThread().getContextClassLoader().getResourceAsStream("hotrod-client.properties"));
        this.remoteCacheManager = remoteCacheManager;
        cache = remoteCacheManager.getCache("HotRodcache");
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

        List<NotifyingFuture<?>> futures = new ArrayList<NotifyingFuture<?>>();
        
        final long startTime = System.currentTimeMillis();
        for (int i = 0; i < entryCount; i++) {
        	// Depending on start parameter 6 we will use async put or sync put
        	if(async) {
        		 futures.add(cache.putAsync(key++, value));
        	} else {
        		cache.put(key++, value);
        	}

        	// We will sleep the value of start parameter 4 every X message, where X is start parameter 5
            if (i % sleepInterval == 0) {
                Thread.sleep(sleepTime);
            }
        }
        
        //If async we need to wait async calls to finish
        if(async) {
        	for(NotifyingFuture<?> future : futures) {
    			future.get();
    		}
        }
        
        final long endTime = System.currentTimeMillis();
        
        double totalExecTime = (Double.valueOf(endTime) - Double.valueOf(startTime)) / 1000.0;
        //remoteCacheManager.stop();

        System.out.println("Task '" + name + "' took " + totalExecTime + " seconds to write " + entryCount
                + " entries " + " of total size " + entryCount * valueSize + " with ");
    }
}
