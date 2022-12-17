extension OracleRow: SQLRow {
    public var allColumns: [String] {
        self.columns.map { $0.name }
    }

    public func decodeNil(column: String) throws -> Bool {
        guard let data = self.column(column) else {
            throw MissingColumn(column: column)
        }
        return data == .null
    }

    public func contains(column: String) -> Bool {
        self.column(column) != nil
    }

    public func decode<D>(column: String, as type: D.Type) throws -> D where D : Decodable {
        guard let data = self.column(column) else {
            throw MissingColumn(column: column)
        }
        return try OracleDataDecoder().decode(D.self, from: data)
    }
}

struct MissingColumn: Error {
    let column: String
}
