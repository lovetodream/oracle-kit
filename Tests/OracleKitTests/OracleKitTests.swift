import XCTest
@testable import OracleKit
import SQLKitBenchmark
import Logging

final class OracleKitTests: XCTestCase {
//    func testSQLKitBenchmark() throws {
//        let benchmark = SQLBenchmarker(on: db)
//        try benchmark.testCodable()
//    } // cannot be tested, because oracle has too many pitfalls

    var currentID = 0

    func nextID() -> SQLBind {
        currentID += 1
        return SQLBind(currentID)
    }

    func nextID() -> Int {
        currentID += 1
        return currentID
    }

    func testPlanets() throws {
        try? self.db.drop(table: "planets")
            .ifExists()
            .run().wait()
        try? self.db.drop(table: "galaxies")
            .ifExists()
            .run().wait()
        // Why `try?`? Oracle doesn't support `if exists`,
        // so it fails if the table does not exist,
        // which is fine for the purpose of the test
        try self.db.create(table: "galaxies")
            .column("id", type: .int, .primaryKey)
            .column("name", type: .text)
            .run().wait()
        try self.db.create(table: "planets")
            .ifNotExists()
            .column("id", type: .int, .primaryKey)
            .column("galaxyID", type: .int, .references("galaxies", "id"))
            .run().wait()
        try self.db.alter(table: "planets")
            .column("name", type: .text, .default(SQLLiteral.string("Unamed Planet")))
            .run().wait()
        do {
            try self.db.create(index: "test_index")
                .on("planets")
                .column("id")
                .unique()
                .run().wait()
        } catch {
            // This always fails for oracle because it indexes its primary keys by default.
        }
        // INSERT INTO "galaxies" ("id", "name") VALUES (DEFAULT, $1)
        try self.db.insert(into: "galaxies")
            .columns("id", "name")
            .values(nextID(), SQLBind("Milky Way"))
            .run().wait()
        try self.db.insert(into: "galaxies")
            .columns("id", "name")
            .values(nextID(), SQLBind("Andromeda"))
            // .value(Galaxy(name: "Milky Way"))
            .run().wait()
        // SELECT * FROM galaxies WHERE name != NULL AND (name == ? OR name == ?)
        _ = try self.db.select()
            .column("*")
            .from("galaxies")
            .where("name", .notEqual, SQLLiteral.null)
            .where {
                $0.where("name", .equal, SQLBind("Milky Way"))
                    .orWhere("name", .equal, SQLBind("Andromeda"))
            }
            .all().wait()

        _ = try self.db.select()
            .column("*")
            .from("galaxies")
            .where(SQLColumn("name"), .equal, SQLBind("Milky Way"))
            .groupBy("id")
            .groupBy("name")
            .orderBy("name", .descending)
            .all().wait()

        try self.db.insert(into: "planets")
            .columns("id", "name")
            .values(nextID(), SQLBind("Earth"))
            .run().wait()

        try [SQLBind("Mercury"), SQLBind("Venus"), SQLBind("Mars"), SQLBind("Jpuiter"), SQLBind("Pluto")].forEach {
            try self.db.insert(into: "planets")
                .columns("id", "name")
                .values(nextID(), $0)
                .run().wait()
        }

        try self.db.select()
            .column(SQLFunction("count", args: "name"))
            .from("planets")
            .where("galaxyID", .equal, SQLBind(5))
            .run().wait()

        try self.db.select()
            .column(SQLFunction("count", args: SQLLiteral.all))
            .from("planets")
            .where("galaxyID", .equal, SQLBind(5))
            .run().wait()
    }

    func testCodable() throws {
        try? db.drop(table: "planets")
            .ifExists()
            .run().wait()
        try? db.drop(table: "galaxies")
            .ifExists()
            .run().wait()
        try db.create(table: "galaxies")
            .column("id", type: .bigint, .primaryKey)
            .column("name", type: .text)
            .run().wait()
        try db.create(table: "planets")
            .column("id", type: .bigint, .primaryKey)
            .column("name", type: .text, [.default(SQLLiteral.string("Unamed Planet")), .notNull])
            .column("is_inhabited", type: .custom(SQLRaw("Number(1)")), .notNull)
            .column("galaxyID", type: .bigint, .references("galaxies", "id"))
            .run().wait()

        // insert
        let galaxy = Galaxy(id: nextID(), name: "milky way")
        try db.insert(into: "galaxies").model(galaxy).run().wait()

        // insert with keyEncodingStrategy
        let earth = Planet(id: nextID(), name: "Earth", isInhabited: true)
        let mars = Planet(id: nextID(), name: "Mars", isInhabited: false)
        try [earth, mars].forEach {
            try db.insert(into: "planets")
                .model($0, keyEncodingStrategy: .convertToSnakeCase)
                .run().wait()
        }
    }

    var db: SQLDatabase {  self.connection.sql() }
    var benchmark: SQLBenchmarker { .init(on: self.db) }

    var eventLoopGroup: EventLoopGroup!
    var threadPool: NIOThreadPool!
    var connection: OracleConnection!

    override func setUp() {
        XCTAssertTrue(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
        self.threadPool = NIOThreadPool(numberOfThreads: 2)
        self.threadPool.start()
        self.connection = try! OracleConnectionSource(
            configuration: .init(
                username: env("ORA_USER")!,
                password: env("ORA_PWD")!,
                connectionString: env("ORA_CONN")!
            ),
            threadPool: self.threadPool
        ).makeConnection(logger: .init(label: "test"), on: self.eventLoopGroup.any()).wait()
    }

    override func tearDown() {
        try! self.connection.close().wait()
        self.connection = nil
        try! self.threadPool.syncShutdownGracefully()
        self.threadPool = nil
        try! self.eventLoopGroup.syncShutdownGracefully()
        self.eventLoopGroup = nil
    }
}

func env(_ name: String) -> String? {
    getenv(name).flatMap { String(cString: $0) }
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .trace
        return handler
    }
    return true
}()

fileprivate struct Planet: Encodable {
    let id: Int
    let name: String
    let isInhabited: Bool
}

fileprivate struct Galaxy: Encodable {
    let id: Int
    let name: String
}
