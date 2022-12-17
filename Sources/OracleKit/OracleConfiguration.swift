public struct OracleConfiguration {
    public var authorizationMode: OracleConnection.AuthorizationMode
    public var username: String
    public var password: String
    public var connectionString: String
    public var clientLibraryDirectory: String?

    init(
        authorizationMode: OracleConnection.AuthorizationMode = .default,
        username: String,
        password: String,
        connectionString: String,
        clientLibraryDirectory: String? = nil
    ) {
        self.authorizationMode = authorizationMode
        self.username = username
        self.password = password
        self.connectionString = connectionString
        self.clientLibraryDirectory = clientLibraryDirectory
    }
}
