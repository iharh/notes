import com.sun.btrace.Profiler;

import com.sun.btrace.annotations.*;

import static com.sun.btrace.BTraceUtils.*;

@BTrace
public class CCSQ {
    @Property
    static Profiler prof = Profiling.newProfiler();
    
    // collect

    @OnMethod(
        clazz="org.elasticsearch.index.search.child.ChildrenConstantScoreQuery$ParentOrdCollector",
        method="collect"
    )
    public static void onEnterCollect(
        @ProbeMethodName(fqn=false) String probeMethod
    ) {
        Profiling.recordEntry(prof, getKey(probeMethod));
    }

    @OnMethod(
        clazz="org.elasticsearch.index.search.child.ChildrenConstantScoreQuery$ParentOrdCollector",
        method="collect",
        location=@Location(value=Kind.RETURN)
    )
    public static void onReturnCollect(
        @ProbeMethodName(fqn=false) String probeMethod,
        @Duration long duration
    ) {
        Profiling.recordExit(prof, getKey(probeMethod), duration);
    }

    // match

    @OnMethod(
        clazz="org.elasticsearch.index.search.child.ChildrenConstantScoreQuery$ParentOrdIterator",
        method="match"
    )
    public static void onEnterMatch(
        @ProbeMethodName(fqn=false) String probeMethod
    ) {
        Profiling.recordEntry(prof, getKey(probeMethod));
    }

    @OnMethod(
        clazz="org.elasticsearch.index.search.child.ChildrenConstantScoreQuery$ParentOrdIterator",
        method="match",
        location=@Location(value=Kind.RETURN)
    )
    public static void onReturnMatch(
        @ProbeMethodName(fqn=false) String probeMethod,
        @Duration long duration
    ) {
        Profiling.recordExit(prof, getKey(probeMethod), duration);
    }

    // boilerplate

    @OnEvent
    public static void onEvent() {
        Profiling.printSnapshot("current profile", prof);
    }

    private static String getKey(final String methodName) {
        return concat(methodName, concat("-", str(currentThread())));
    }

/*
    @Property
    static long cntCollect;


    // Export   - jvmstat/jstat counter
    // Property - make the field exposed as an attribute of this MBean

    @com.sun.btrace.annotations.Export
    private static long cntWeight;

    @OnMethod(
        clazz="org.elasticsearch.index.search.child.ChildrenConstantScoreQuery",
        method="createWeight"
    )
    public static void onCreateWeight() {
        println(concat("onCreateWeight tid: ", str(currentThread())));
        ++cntWeight;
    }

    @OnEvent(value="v1")
    public static void onEventV1() {
        println("evt v1");
    }

    @OnTimer(10000)
    public static void onTimer() {
        println(perfLong("btrace.com.sun.btrace.samples.CCSQ.cntWeight"));
    }
*/
}
