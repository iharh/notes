/dso/trunk/code/base/common/src.resources/com/tc/properties/tc.properties



at sun.management.ThreadImpl.dumpThreads0(Native Method)
at sun.management.ThreadImpl.dumpAllThreads(ThreadImpl.java:374)
at com.tc.util.runtime.ThreadDumpUtilJdk16.getThreadDump(ThreadDumpUtilJdk16.java:30)

at com.tc.util.runtime.ThreadDumpUtil.getThreadDump(ThreadDumpUtil.java:121)
at com.tc.util.runtime.ThreadDumpUtil.getCompressedThreadDump(ThreadDumpUtil.java:72)
at com.tc.management.L1Info.takeCompressedThreadDump(L1Info.java:200)




at com.tc.util.concurrent.ThreadUtil.reallySleep(ThreadUtil.java:24)
at com.tc.util.concurrent.ThreadUtil.reallySleep(ThreadUtil.java:16)
at com.tc.net.protocol.transport.ConnectionHealthCheckerImpl$HealthCheckerMonitorThreadEngine.run(ConnectionHealthCheckerImpl.java:197)




at com.tc.runtime.TCMemoryManagerImpl$MemoryMonitor.run(TCMemoryManagerImpl.java:142)



at com.tc.management.remote.protocol.terracotta.TunnelingEventHandler.accept(TunnelingEventHandler.java:103)
at com.tc.management.remote.protocol.terracotta.TunnelingMessageConnectionServer.accept(TunnelingMessageConnectionServer.java:32)
