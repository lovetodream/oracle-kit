import SQLKit

public struct OracleDialect: SQLDialect {
    public var varcharLength: Int

    public var name: String { "oracle" }

    public var identifierQuote: SQLExpression { SQLRaw("\"") }
    public var literalStringQuote: SQLExpression { SQLRaw("'") }
    public func bindPlaceholder(at position: Int) -> SQLExpression { SQLRaw(":\(position)") }
    public func literalBoolean(_ value: Bool) -> SQLExpression { SQLRaw(value ? "TRUE" : "FALSE") }
    public var literalDefault: SQLExpression { SQLLiteral.null }

    public var supportsAutoIncrement: Bool { false }
    public var autoIncrementClause: SQLExpression { SQLRaw("AUTO_INCREMENT") }

    public var enumSyntax: SQLEnumSyntax { .unsupported }
    public var triggerSyntax: SQLTriggerSyntax {
        .init(create: [
            .supportsBody,
            .supportsCondition,
            .supportsDefiner,
            .supportsForEach,
            .supportsUpdateColumns
        ])
    }
    public var alterTableSyntax: SQLAlterTableSyntax { .init(alterColumnDefinitionClause: SQLRaw("MODIFY"), allowsBatch: true) }
    public var upsertSyntax: SQLUpsertSyntax { .unsupported }
    public var supportsReturning: Bool { true }
    public var supportsIfExists: Bool { false }
    public var unionFeatures: SQLUnionFeatures { [.union, .unionAll, .intersect, .explicitDistinct, .parenthesizedSubqueries] }
    public var supportsMultiRowInsert: Bool { false }

    public func customDataType(for dataType: SQLDataType) -> SQLExpression? {
        // ref: https://docs.oracle.com/en/database/oracle/oracle-database/19/odbcu/database-gateway-odbc-data-type-conversion.html
        switch dataType {
        case .smallint: return SQLRaw("NUMBER(5)")
        case .int:      return SQLRaw("NUMBER(10)")
        case .bigint:   return SQLRaw("NUMBER(19,0)")
        case .text:     return SQLRaw("VARCHAR(\(varcharLength))")
        case .real:     return SQLRaw("FLOAT(24)")
        default:        return nil
        }
    }

    public init(varcharLength: Int = 4000) {
        self.varcharLength = varcharLength
    }
}
