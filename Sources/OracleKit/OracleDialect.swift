import SQLKit

public struct OracleDialect: SQLDialect {
    public var name: String { "oracle" }

    public var identifierQuote: SQLExpression { SQLRaw("\"") }
    public var literalStringQuote: SQLExpression { SQLRaw("'") }
    public func bindPlaceholder(at position: Int) -> SQLExpression { SQLRaw(":\(position)") }
    public func literalBoolean(_ value: Bool) -> SQLExpression { SQLRaw(value ? "TRUE" : "FALSE") }
    public var literalDefault: SQLExpression { SQLLiteral.null }

    public var supportsAutoIncrement: Bool { true }
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

    public func customDataType(for dataType: SQLDataType) -> SQLExpression? { nil }

    public init() {}
}
