//
//  DelimitedEncoder.swift
//
//  A simple declarative encoder for use in environments lacking DateFormatters, Streams, etc.
//
// Copyright 2021, 2022 OpenAlloc LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

public class DelimitedEncoder: Encoder {
    public var delimiter: String
    public var lineSeparator: String
    public var codingPath: [CodingKey] = []
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    private var data = Data()

    private static let isoDateFormatter = ISO8601DateFormatter()

    public init(delimiter: String = ",",
                lineSeparator: String = "\n")
    {
        self.delimiter = delimiter
        self.lineSeparator = lineSeparator
    }

    @discardableResult public func encode(headers: [String]) throws -> Data {
        write(headers.joined(separator: delimiter))
        write(lineSeparator)
        return data
    }

    public func encode(rows: some Encodable) throws -> Data {
        try rows.encode(to: self)
        return data
    }

    fileprivate func write(_ string: String) {
        data.append(string.data(using: .utf8)!)
    }

    public func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        KeyedEncodingContainer(KeyedContainer<Key>(encoder: self))
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        UnkeyedContainer(encoder: self)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        self as! SingleValueEncodingContainer
    }

    private struct KeyedContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
        typealias Key = K

        var codingPath: [CodingKey] = []
        var isFirstColumn = true

        private let encoder: DelimitedEncoder

        public init(encoder: DelimitedEncoder) {
            self.encoder = encoder
        }

        mutating func encodeNil(forKey key: K) throws {
            try encode("", forKey: key)
        }

        mutating func encodeIfPresent(_ value: String?, forKey key: Self.Key) throws {
            if let value_ = value {
                try encode(value_, forKey: key)
            } else {
                try encodeNil(forKey: key)
            }
        }

        mutating func encodeIfPresent(_ value: Double?, forKey key: Self.Key) throws {
            if let value_ = value {
                try encode(value_, forKey: key)
            } else {
                try encodeNil(forKey: key)
            }
        }

        mutating func encodeIfPresent(_ value: Date?, forKey key: Self.Key) throws {
            if let value_ = value {
                try encode(value_, forKey: key)
            } else {
                try encodeNil(forKey: key)
            }
        }

        mutating func encodeIfPresent(_ value: Int?, forKey key: Self.Key) throws {
            if let value_ = value {
                try encode(value_, forKey: key)
            } else {
                try encodeNil(forKey: key)
            }
        }

        mutating func encodeIfPresent(_ value: Bool?, forKey key: Self.Key) throws {
            if let value_ = value {
                try encode(value_, forKey: key)
            } else {
                try encodeNil(forKey: key)
            }
        }

        mutating func encode(_ value: some Encodable, forKey _: K) throws {
            if isFirstColumn {
                isFirstColumn = false
            } else {
                encoder.write(encoder.delimiter)
            }

            let value_: String = {
                if let date = value as? Date {
                    return DelimitedEncoder.isoDateFormatter.string(from: date)
                } else if let value_ = value as? CustomStringConvertible {
                    let rawValue = value_.description
                    let hasDelim = rawValue.contains(encoder.delimiter)
                    let escapedValue = rawValue.replacingOccurrences(of: "\"", with: "\\\"")
                    return hasDelim ? "\"\(escapedValue)\"" : escapedValue
                }
                return "" // assume nil and render as blank
            }()

            encoder.write(value_)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey _: K) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            encoder.container(keyedBy: keyType)
        }

        mutating func nestedUnkeyedContainer(forKey _: K) -> UnkeyedEncodingContainer {
            encoder.unkeyedContainer()
        }

        mutating func superEncoder() -> Encoder {
            encoder
        }

        mutating func superEncoder(forKey _: K) -> Encoder {
            encoder
        }
    }

    private struct UnkeyedContainer: UnkeyedEncodingContainer {
        var codingPath: [CodingKey] = []
        var count: Int = 0

        private let encoder: DelimitedEncoder

        init(encoder: DelimitedEncoder) {
            self.encoder = encoder
        }

        mutating func encode(_ value: some Encodable) throws {
            try value.encode(to: encoder)
            encoder.write(encoder.lineSeparator)
            count += 1
        }

        mutating func encodeNil() throws {}

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            encoder.container(keyedBy: keyType)
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            self
        }

        mutating func superEncoder() -> Encoder {
            encoder
        }
    }
}
