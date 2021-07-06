//
//  FINprospector.swift
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

import SwiftCSV
import AllocData

public struct FINprospector {
    public typealias ProspectResult = [FINporter: FINporter.DetectResult]

    public var importers = [FINporter]()
    private var sourceMap = [AllocFormat: [FINporter]]()

    public init() {
        // specialized
        importers.append(AllocSmart())
        importers.append(FidoPurchases())
        importers.append(FidoPositions())
        importers.append(FidoSales())

        // consolidated importer for delimited tables with recognized schema
        importers.append(Tabular())

        // others here

        sourceMap = importers.reduce(into: [:]) { map, importer in
            importer.sourceFormats.forEach {
                map[$0, default: []].append(importer)
            }
        }
    }

    public func get(_ finPorterID: String) -> FINporter? {
        importers.first(where: { $0.id == finPorterID })
    }

    /// find candidate parsers
    public func prospect(sourceFormats: [AllocFormat] = AllocFormat.allCases, dataPrefix: Data) throws -> ProspectResult {
        let sourceImporters = Set(sourceFormats.compactMap { sourceMap[$0] }.flatMap { $0 })

        return try sourceImporters.reduce(into: [:]) { map, importer in
            do {
                let detectResult = try importer.detect(dataPrefix: dataPrefix)
                if detectResult.count > 0 {
                    map[importer] = detectResult
                }
            } catch let CSVParseError.generic(message) {
                fputs("[FINprospector.prospect] CSV generic \(message)", stderr)
            } catch let CSVParseError.quotation(message) {
                fputs("[FINprospector.prospect] CSV quotation \(message)", stderr)
            }
        }
    }
}
