import Foundation

public struct OracleDataDecoder {
    public init() {}

    public func decode<T: Decodable>(_ type: T.Type, from data: OracleData) throws -> T {
        if let type = type as? OracleDataConvertible.Type {
            guard let value = type.init(oracleData: data) else {
                throw DecodingError.typeMismatch(T.self, .init(codingPath: [], debugDescription: "Could not initialize \(T.self) from \(data)."))
            }
            return value as! T
        } else {
            return try T.init(from: _Decoder(data: data))
        }
    }

    private final class _Decoder: Decoder {
        var codingPath: [CodingKey] { [] }

        var userInfo: [CodingUserInfoKey : Any] { [:] }

        let data: OracleData
        init(data: OracleData) {
            self.data = data
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            try jsonDecoder().unkeyedContainer()
        }

        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            try jsonDecoder().container(keyedBy: Key.self)
        }

        func jsonDecoder() throws -> Decoder {
            let data: Data
            switch self.data {
            case .blob(let buffer):
                data = Data(buffer.readableBytesView)
            case .text(let string):
                data = Data(string.utf8)
            default:
                data = .init()
            }
            return try JSONDecoder()
                .decode(DecoderUnwrapper.self, from: data)
                .decoder
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            _SingleValueDecoder(self)
        }
    }

    private struct _SingleValueDecoder: SingleValueDecodingContainer {
        var codingPath: [CodingKey] { decoder.codingPath }
        let decoder: _Decoder
        init(_ decoder: _Decoder) {
            self.decoder = decoder
        }

        func decodeNil() -> Bool {
            decoder.data == .null
        }

        func decode<T: Decodable>(_ type: T.Type) throws -> T {
            try OracleDataDecoder().decode(T.self, from: decoder.data)
        }
    }
}

private struct DecoderUnwrapper: Decodable {
    let decoder: Decoder
    init(from decoder: Decoder) {
        self.decoder = decoder
    }
}
