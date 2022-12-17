extension OracleDatabase {
    public func sql() -> SQLDatabase {
        _OracleSQLDatabase(database: self)
    }
}

internal struct _OracleDatabaseVersion: SQLDatabaseReportedVersion {
    let majorVersion: Int
    let minorVersion: Int
    let patchVersion: Int

    let intValue: Int

    let stringValue: String

    static var runtimeVersion: _OracleDatabaseVersion {
        .init(
            majorVersion: Int(OracleConnection.libraryMajorVersion()),
            minorVersion: Int(OracleConnection.libraryMinorVersion()),
            patchVersion: Int(OracleConnection.libraryPatchVersion())
        )
    }

    init(majorVersion: Int, minorVersion: Int, patchVersion: Int) {
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.patchVersion = patchVersion
        self.intValue = majorVersion * 1_000_000 + minorVersion * 1_000 + patchVersion
        self.stringValue = "\(majorVersion).\(minorVersion).\(patchVersion)"
    }

    func isEqual(to otherVersion: SQLKit.SQLDatabaseReportedVersion) -> Bool {
        (otherVersion as? _OracleDatabaseVersion).map { $0.intValue == self.intValue } ?? false
    }

    func isOlder(than otherVersion: SQLKit.SQLDatabaseReportedVersion) -> Bool {
        (otherVersion as? _OracleDatabaseVersion).map {
            (self.majorVersion < $0.majorVersion ? true :
            (self.majorVersion > $0.majorVersion ? false :
            (self.minorVersion < $0.minorVersion ? true :
            (self.minorVersion > $0.minorVersion ? false :
            (self.patchVersion < $0.patchVersion ? true : false)))))
        } ?? false
    }


}

private struct _OracleSQLDatabase: SQLDatabase {
    let database: OracleDatabase

    var eventLoop: EventLoop {
        database.eventLoop
    }

    var version: SQLDatabaseReportedVersion? {
        _OracleDatabaseVersion.runtimeVersion
    }

    var logger: Logger {
        database.logger
    }

    var dialect: SQLDialect {
        OracleDialect()
    }

    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) -> ()) -> EventLoopFuture<Void> {
        var serializer = SQLSerializer(database: self)
        query.serialize(to: &serializer)
        let binds: [OracleData]
        do {
            binds = try serializer.binds.map { encodable in
                return try OracleDataEncoder().encode(encodable)
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.database.query(serializer.sql, binds, logger: self.logger, onRow)
    }
}

extension OracleConnection: ConnectionPoolItem { }
