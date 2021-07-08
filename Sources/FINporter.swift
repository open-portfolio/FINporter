//
//  FINporter.swift
//
// Copyright 2021 FlowAllocator LLC
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

import AllocData

open class FINporter: Identifiable, Hashable {
    public typealias DetectResult = [AllocSchema: [AllocFormat]]

    open var name: String { "" }
    open var id: String { "" }
    open var description: String { "" }
    open var sourceFormats: [AllocFormat] { [] }
    open var outputSchemas: [AllocSchema] { [] }

    public init() {}

    // returns a list of target schema available, if any ([] if unrecognized/none)
    // may be taken from first N bytes of data
    open func detect(dataPrefix _: Data) throws -> DetectResult {
        throw FINporterError.notImplementedError
    }

    open func decode<T: AllocBase>(_: T.Type,
                                   _: Data,
                                   rejectedRows _: inout [T.Row],
                                   inputFormat _: AllocFormat? = nil,
                                   outputSchema _: AllocSchema? = nil,
                                   url _: URL? = nil,
                                   timestamp _: Date = Date()) throws -> [T.Row] {
        throw FINporterError.notImplementedError
    }

    open func export<T: AllocBase>(elements: [T], format: AllocFormat) throws -> Data {
        switch format {
        case .JSON:
            let encoder = JSONEncoder()
            do {
                return try encoder.encode(elements)
            } catch {
                throw FINporterError.encodingError("Invalid for '\(T.self)' (\(error))")
            }
        case .CSV:
            let encoder = DelimitedEncoder(delimiter: ",")
            _ = try encoder.encode(headers: AllocAttribute.getHeaders(T.attributes))
            return try encoder.encode(rows: elements)
        case .TSV:
            let encoder = DelimitedEncoder(delimiter: "\t")
            _ = try encoder.encode(headers: AllocAttribute.getHeaders(T.attributes))
            return try encoder.encode(rows: elements)
        }
    }

    public static func == (lhs: FINporter, rhs: FINporter) -> Bool {
        lhs.id == rhs.id &&
            lhs.sourceFormats == rhs.sourceFormats &&
            lhs.outputSchemas == rhs.outputSchemas
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(sourceFormats)
        hasher.combine(outputSchemas)
//        super.hash(into: &hasher)
    }
}
