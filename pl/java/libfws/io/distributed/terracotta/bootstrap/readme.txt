

l1.classloader.trace.output=stdout/stderr

1. ClassProcessorHelper.java
-  public static byte[] defineClass0Pre(ClassLoader caller, String name, byte[] b, int off, int len, ProtectionDomain pd) {
   {
     initialize()
     ManagerUtil.enable();
   }
-- initialize()
--- createGlobalContext // !!! manager.init doesn't called here
   (DSOContext globalContext = DSOContextImpl.createGlobalContext) !!!

- setContext(ClassLoader loader, DSOContext context)


2. DSOContextImpl
- public static DSOContext createGlobalContext() throws ConfigurationSetupException {
    DSOClientConfigHelper configHelper = getGlobalConfigHelper();
    Manager manager = new ManagerImpl(configHelper, preparedComponentsFromL2Connection);
    return new DSOContextImpl(configHelper, manager.getClassProvider(), manager, Collections.EMPTY_LIST);
  }
- createContext !!!
- createStandaloneContext !!!


3. ManagerImpl
  public ManagerImpl(final DSOClientConfigHelper config, final PreparedComponentsFromL2Connection connectionComponents) {
    this(true, null, null, null, config, connectionComponents, true, null, null, false);
  }

- StandardClassProvider classProvider

- private void startClient(final boolean forTests) {
    final TCThreadGroup group = new TCThreadGroup(new ThrowableHandler(TCLogging
        .getLogger(DistributedObjectClient.class)));

    final StartupAction action = new StartupHelper.StartupAction() {
      public void execute() throws Throwable {
        final AbstractClientFactory clientFactory = AbstractClientFactory.getFactory(); // StandardClientFactory in fact
        ManagerImpl.this.dso = clientFactory.createClient(ManagerImpl.this.config, group,
    ...
  }

- private void init(final boolean forTests) {
/// !!! need to get a stack-trace here !!!
    resolveClasses(); // call this before starting any threads (SEDA, DistributedMethod call stuff, etc)

    if (this.startClient) {
      if (this.clientStarted.attemptSet()) {
        startClient(forTests);
      }
    }
  }


IsolationClassLoader
- public void init() {
    DSOContext context = DSOContextImpl.createContext(config, manager); !!!
    manager.initForTests();
    ClassProcessorHelper.setContext(this, context);
  }

- c-tor
--  private Manager createManager(boolean startClient, ClientObjectManager objectManager,
                                  ClientTransactionManager txManager, ClientLockManager lockManager,
                                  DSOClientConfigHelper theConfig, PreparedComponentsFromL2Connection connectionComponents) {
!!!   Manager rv = new ManagerImpl(startClient, objectManager, txManager, lockManager, theConfig, connectionComponents,
                                   false, null, null, false);
      rv.registerNamedLoader(this, null);
      return rv;
    }


StandardClassProvider
- registerNamedLoader() // Cand create IsolationClassLoader !!!
- lookupLoaderWithAppGroup (
	<-lookupLoader, 
		<- getClassLoader
		<- getClassFor
  )


