public struct OracleConnectionSource: ConnectionPoolSource {
    private let configuration: OracleConfiguration
    private let threadPool: NIOThreadPool

    public init(configuration: OracleConfiguration, threadPool: NIOThreadPool) {
        self.configuration = configuration
        self.threadPool = threadPool
    }

    public func makeConnection(logger: Logger, on eventLoop: EventLoop) -> EventLoopFuture<OracleConnection> {
        OracleConnection.connect(
            authorizationMode: configuration.authorizationMode,
            username: configuration.username,
            password: configuration.password,
            connectionString: configuration.connectionString,
            clientLibraryDir: configuration.clientLibraryDirectory,
            threadPool: threadPool,
            logger: logger,
            on: eventLoop
        )
    }
}
