//
//  Tabular.swift
//
//  Importer supporting detection and decoding of schema-supported tabular documents (e.g., history.csv to [MTransaction])
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
import SwiftCSV

public class Tabular: FINporter {
    override public var name: String { "Tabular" }
    override public var id: String { "tabular" }
    override public var description: String { "Detect and decode schema-supported tabular documents." }
    override public var sourceFormats: [AllocFormat] { [.CSV, .TSV] }
    override public var outputSchemas: [AllocSchema] {[
        .allocAccount,
        .allocAllocation,
        .allocAsset,
        .allocCap,
        .allocTransaction,
        .allocHolding,
        .allocSecurity,
        .allocStrategy,
        .allocTracker,
    ]}

    override public func detect(dataPrefix: Data) throws -> DetectResult {
        guard let str = FINporter.normalizeDecode(dataPrefix) else {
            return [:]
        }

        return sourceFormats.reduce(into: [:]) { map, sourceFormat in
            guard let delimiter = sourceFormat.delimiter else { return }
            do {
                let table = try CSV(string: str, delimiter: delimiter)

                let documentSignature = AllocSchema.generateSignature(table.header)

                for (allocSchema, tableSignature) in AllocSchema.tableSignatureMap {
                    if documentSignature.isSuperset(of: tableSignature) {
                        map[allocSchema, default: []].append(sourceFormat)
                    }
                }
            } catch let error as FINporterError {
                fputs("[FINporter.Tabular.detect] \(error.description)", stderr)
            } catch {
                fputs("[FINporter.Tabular.detect] \(error)", stderr)
            }
        }
    }

    override open func decode<T: AllocRowed>(_ type: T.Type,
                                            _ data: Data,
                                            rejectedRows: inout [T.RawRow],
                                            inputFormat: AllocFormat? = nil,
                                            outputSchema _: AllocSchema? = nil,
                                            url: URL? = nil,
                                            defTimeOfDay _: String? = nil,
                                            timeZoneID _: String? = nil,
                                            timestamp _: Date? = nil) throws -> [T.DecodedRow] {
        guard let str = FINporter.normalizeDecode(data) else {
            throw FINporterError.decodingError("Unable to parse data.")
        }

        guard let format: AllocFormat = inputFormat ?? AllocFormat.guess(fromFileExtension: url?.pathExtension),
              let delimiter = format.delimiter
        else {
            throw FINporterError.decodingError("Unable to infer format (and delimiter) from url.")
        }

        let rows = try CSV(string: str, delimiter: delimiter)

        return try T.decode(rows.namedRows, rejectedRows: &rejectedRows)
    }
}
