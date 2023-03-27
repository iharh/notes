??? oooSendStage, oooReceiveStage

DistributedObjectClient:

dsoClientBuilder // StandardDSOClientBuilder

start
	// create NetworkStackHarnessFactory
	final ReconnectConfig l1ReconnectConfig = this.config.getL1ReconnectProperties();
	final boolean useOOOLayer = l1ReconnectConfig.getReconnectEnabled();
	final NetworkStackHarnessFactory networkStackHarnessFactory;
	if (useOOOLayer) {
		final Stage oooSendStage = stageManager.createStage(ClientConfigurationContext.OOO_NET_SEND_STAGE,
                                                          new OOOEventHandler(), 1, maxSize);
		final Stage oooReceiveStage = stageManager.createStage(ClientConfigurationContext.OOO_NET_RECEIVE_STAGE,
                                                             new OOOEventHandler(), 1, maxSize);
		networkStackHarnessFactory = new OOONetworkStackHarnessFactory(
                                                                     new OnceAndOnlyOnceProtocolNetworkLayerFactoryImpl(),
                                                                     oooSendStage.getSink(), oooReceiveStage.getSink(),
                                                                     l1ReconnectConfig);
	} else {
		networkStackHarnessFactory = new PlainNetworkStackHarnessFactory();
	}


	this.communicationsManager = this.dsoClientBuilder.createCommunicationsManager(
		mm,
		networkStackHarnessFactory,
		new NullConnectionPolicy(),
		this.connectionComponents.createConnectionInfoConfigItemByGroup().length,
		new HealthCheckerConfigClientImpl(this.l1Properties.getPropertiesFor("healthcheck.l2"), "DSO Client")
	);



 -     this.channel = this.dsoClientBuilder.createDSOClientMessageChannel(
		this.communicationsManager,
		this.connectionComponents,
		sessionProvider,
		maxConnectRetries,
		socketConnectTimeout,
		this
	);




StandardDSOClientBuilder:

	public CommunicationsManager createCommunicationsManager(
		final MessageMonitor monitor,
		final NetworkStackHarnessFactory stackHarnessFactory,
		final ConnectionPolicy connectionPolicy,
		final int commThread,
		final HealthCheckerConfig aConfig
	) {
		return new CommunicationsManagerImpl(
			CommunicationsManager.COMMSMGR_CLIENT,
			monitor,
			stackHarnessFactory,
			connectionPolicy,
			aConfig
		);
	}

	public DSOClientMessageChannel createDSOClientMessageChannel(
		final CommunicationsManager commMgr,
		final PreparedComponentsFromL2Connection connComp,
		final SessionProvider sessionProvider,
		final int maxReconnectTries,
		final int socketConnectTimeout,
		final TCClient client
	) {
		final ConnectionAddressProvider cap = createConnectionAddressProvider(connComp);
		final ClientMessageChannel cmc = commMgr.createClientChannel(
			sessionProvider,
			maxReconnectTries,
			null,
			0,
			socketConnectTimeout,
			cap
		);
		return new DSOClientMessageChannelImpl(cmc, new GroupID[] { new GroupID(cap.getGroupId()) });
	}

	protected ConnectionAddressProvider createConnectionAddressProvider(final PreparedComponentsFromL2Connection connComp) {
		final ConfigItem connectionInfoItem = connComp.createConnectionInfoConfigItem();
		final ConnectionInfo[] connectionInfo = (ConnectionInfo[]) connectionInfoItem.getObject();
		final ConnectionAddressProvider cap = new ConnectionAddressProvider(connectionInfo);
		return cap;
	}




CommunicationsManagerImpl

	public ClientMessageChannel createClientChannel(final SessionProvider sessionProvider, final int maxReconnectTries,
                                                  String hostname, int port, final int timeout,
                                                  ConnectionAddressProvider addressProvider,
                                                  MessageTransportFactory transportFactory,
                                                  TCMessageFactory messageFactory, TCMessageRouter router
	) {
		TCMessageFactory msgFactory = (messageFactory != null) ?
			messageFactory : new TCMessageFactoryImpl(sessionProvider, monitor);

		TCMessageRouter msgRouter = (router != null) ? router : new TCMessageRouterImpl();

		ClientMessageChannelImpl rv = new ClientMessageChannelImpl(
			msgFactory, msgRouter, sessionProvider,
			new GroupID(addressProvider.getGroupId())
		);
		if (transportFactory == null)
			transportFactory = new MessageTransportFactoryImpl(transportMessageFactory,
				connectionHealthChecker,
				connectionManager,
				addressProvider,
				maxReconnectTries, timeout,
				callbackPort, handshakeErrHandler
			);

		NetworkStackHarness stackHarness = this.stackHarnessFactory.createClientHarness(
			transportFactory, rv, new MessageTransportListener[0]
		);
		stackHarness.finalizeStack();

		return rv;
	}


OOONetworkStackHarness

public class OOONetworkStackHarness extends AbstractNetworkStackHarness {
	private final OnceAndOnlyOnceProtocolNetworkLayerFactory factory;
	private Sink                                             sendSink;
	private Sink                                             receiveSink;
	private OnceAndOnlyOnceProtocolNetworkLayer              oooLayer;
	private final boolean                                    isClient;
	private final ReconnectConfig                            reconnectConfig;

	OOONetworkStackHarness(ServerMessageChannelFactory channelFactory, MessageTransport transport,
		OnceAndOnlyOnceProtocolNetworkLayerFactory factory, Sink sendSink, Sink receiveSink,
		ReconnectConfig reconnectConfig
	) {
		super(channelFactory, transport);
		this.isClient = false;
		this.factory = factory;
		this.sendSink = sendSink;
		this.receiveSink = receiveSink;
		this.reconnectConfig = reconnectConfig;
	}

	OOONetworkStackHarness(MessageTransportFactory transportFactory, MessageChannelInternal channel,
		OnceAndOnlyOnceProtocolNetworkLayerFactory factory, Sink sendSink, Sink receiveSink,
		ReconnectConfig reconnectConfig
	) {
		super(transportFactory, channel);
		this.isClient = true;
		this.factory = factory;
		this.sendSink = sendSink;
		this.receiveSink = receiveSink;
		this.reconnectConfig = reconnectConfig;
	}

	protected void connectStack() {
		channel.setSendLayer(oooLayer); // !!!
		oooLayer.setReceiveLayer(channel);
		oooLayer.addTransportListener(channel);

		transport.setAllowConnectionReplace(true);

		oooLayer.setSendLayer(transport);
		transport.setReceiveLayer(oooLayer);

		long timeout = 0;
		if (reconnectConfig.getReconnectEnabled()) timeout = reconnectConfig.getReconnectTimeout();
		// XXX: this is super ugly, but...
		if (transport instanceof ClientMessageTransport) {
			ClientMessageTransport cmt = (ClientMessageTransport) transport;
			ClientConnectionEstablisher cce = cmt.getConnectionEstablisher();
			OOOConnectionWatcher cw = new OOOConnectionWatcher(cmt, cce, oooLayer, timeout);
			cmt.addTransportListener(cw);
		} else {
			OOOReconnectionTimeout ort = new OOOReconnectionTimeout(oooLayer, timeout);
			transport.addTransportListener(ort);
		}
	}

	protected void createIntermediateLayers() {
		oooLayer = (isClient) ? factory.createNewClientInstance(sendSink, receiveSink, reconnectConfig) : factory
			.createNewServerInstance(sendSink, receiveSink, reconnectConfig);
	}
}


AbstractNetworkStackHarness

	private final MessageTransportFactory     transportFactory;

	/**
	 * Creates and connects a new stack.
	 */
	public final void finalizeStack() {
		if (finalized.attemptSet()) {
			if (isClientStack) {
				Assert.assertNotNull(this.channel);
				Assert.assertNotNull(this.transportFactory);
				this.transport = transportFactory.createNewTransport();
			}
			else {
				Assert.assertNotNull(this.transport);
				Assert.assertNotNull(this.channelFactory);
				this.channel = channelFactory.createNewChannel(new ChannelID(this.transport.getConnectionId().getChannelID()));
			}
			createIntermediateLayers();
			connectStack();
		}
		else {
			throw Assert.failure("Attempt to finalize an already finalized stack");
		}
	}



OOONetworkStackHarnessFactory

public class OOONetworkStackHarnessFactory implements NetworkStackHarnessFactory {

  private final Sink                                       sendSink;
  private final Sink                                       receiveSink;
  private final OnceAndOnlyOnceProtocolNetworkLayerFactory factory;
  private final ReconnectConfig                            reconnectConfig;

  public OOONetworkStackHarnessFactory(OnceAndOnlyOnceProtocolNetworkLayerFactory factory, Sink sendSink,
                                       Sink receiveSink, ReconnectConfig reconnectConfig) {
    this.factory = factory;
    this.sendSink = sendSink;
    this.receiveSink = receiveSink;
    this.reconnectConfig = reconnectConfig;
  }

  public NetworkStackHarness createClientHarness(MessageTransportFactory transportFactory,
                                                 MessageChannelInternal channel,
                                                 MessageTransportListener[] transportListeners) {
    return new OOONetworkStackHarness(transportFactory, channel, factory, sendSink, receiveSink, reconnectConfig);
  }

  public NetworkStackHarness createServerHarness(ServerMessageChannelFactory channelFactory,
                                                 MessageTransport transport,
                                                 MessageTransportListener[] transportListeners) {
    return new OOONetworkStackHarness(channelFactory, transport, factory, sendSink, receiveSink, reconnectConfig);
  }

}
