import NIO
import Foundation

public struct OracleDataEncoder {
    public init() { }

    public func encode(_ value: Encodable) throws -> OracleData {
        if let custom = value as? OracleDataConvertible, let data = custom.oracleData {
            return data
        } else {
            let encoder = _Encoder()
            try value.encode(to: encoder)
            switch encoder.result {
            case .data(let data):
                return data
            case .unkeyed, .keyed:
                let json = try JSONEncoder().encode(AnyEncodable(value))
                var buffer = ByteBufferAllocator().buffer(capacity: json.count)
                buffer.writeBytes(json)
                return OracleData.blob(buffer)
            }
        }
    }

    private enum Result {
        case keyed
        case unkeyed
        case data(OracleData)
    }

    private final class _Encoder: Encoder {
        var codingPath: [CodingKey] { [] }

        var userInfo: [CodingUserInfoKey : Any] { [:] }

        var result: Result
        init() {
            result = .data(.null)
        }

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            result = .keyed
            return .init(_KeyedEncoder())
        }

        func unkeyedContainer() -> UnkeyedEncodingContainer {
            result = .unkeyed
            return _UnkeyedEncoder()
        }

        func singleValueContainer() -> SingleValueEncodingContainer {
            _SingleValueEncoder(encoder: self)
        }
    }

    private struct _KeyedEncoder<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var codingPath: [CodingKey] { [] }

        mutating func encodeNil(forKey key: Key) throws { }
        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws { }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            .init(_KeyedEncoder<NestedKey>())
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            _UnkeyedEncoder()
        }

        mutating func superEncoder() -> Encoder {
            _Encoder()
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            _Encoder()
        }
    }

    private struct _UnkeyedEncoder: UnkeyedEncodingContainer {
        var codingPath: [CodingKey] { [] }
        var count: Int = 0

        mutating func encodeNil() throws { }
        mutating func encode<T: Encodable>(_ value: T) throws { }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            .init(_KeyedEncoder<NestedKey>())
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            _UnkeyedEncoder()
        }

        func superEncoder() -> Encoder {
            _Encoder()
        }
    }

    private struct _SingleValueEncoder: SingleValueEncodingContainer {
        var codingPath: [CodingKey] { [] }
        let encoder: _Encoder

        mutating func encodeNil() throws {
            encoder.result = .data(.null)
        }

        mutating func encode<T: Encodable>(_ value: T) throws {
            let data = try OracleDataEncoder().encode(value)
            encoder.result = .data(data)
        }
    }
}

private struct AnyEncodable: Encodable {
    let encodable: Encodable
    init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
