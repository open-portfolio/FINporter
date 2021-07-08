//
//  TransformHandler.swift
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

/// Used in CLI
public func handleTransform(inputFilePath: String,
                            rejectedRows: inout [AllocBase.Row],
                            finPorterID: String? = nil,
                            outputSchema: AllocSchema? = nil) throws -> String {
    let fileURL = URL(fileURLWithPath: inputFilePath)
    let data = try Data(contentsOf: fileURL)

    let pair = try getPair(data: data, finPorterID: finPorterID, outputSchema: outputSchema)

    switch pair.schema {
    case .allocAccount:
        return try decodeAndExport(MAccount.self, pair.finPorter, data, &rejectedRows, pair.schema, fileURL)
    case .allocAllocation:
        return try decodeAndExport(MAllocation.self, pair.finPorter, data, &rejectedRows, pair.schema, fileURL)
    case .allocAsset:
        return try decodeAndExport(MAsset.self, pair.finPorter, data, &rejectedRows, pair.schema, fileURL)
    case .allocHolding:
        return try decodeAndExport(MHolding.self, pair.finPorter, data, &rejectedRows, pair.schema, fileURL)
    case .allocSecurity:
        return try decodeAndExport(MSecurity.self, pair.finPorter, data, &rejectedRows, pair.schema, fileURL)
    case .allocStrategy:
        return try decodeAndExport(MStrategy.self, pair.finPorter, data, &rejectedRows, pair.schema, fileURL)
    case .allocHistory:
        return try decodeAndExport(MHistory.self, pair.finPorter, data, &rejectedRows, pair.schema, fileURL)
    default:
        throw FINporterError.notImplementedError
    }
}

internal func getPair(data: Data,
                      finPorterID: String? = nil,
                      outputSchema: AllocSchema? = nil) throws -> (finPorter: FINporter, schema: AllocSchema) {
    let FINprospector = FINprospector()

    var importer: FINporter!
    var detectedSchemas = [AllocSchema]()

    // if user explicitly specified an importer
    if let fID = finPorterID {
        importer = FINprospector.get(fID)

        guard importer != nil else {
            throw FINporterError.importerNotRecognized(fID)
        }

        detectedSchemas = importer.outputSchemas

    } else {
        // attempt to find an importer than can handle the input
        let detected: FINprospector.ProspectResult = try FINprospector.prospect(dataPrefix: data)
        let importers = detected.map(\.key)

        switch importers.count {
        case 0:
            throw FINporterError.sourceFormatNotRecognized
        case 2...:
            throw FINporterError.multipleImportersMatch(importers)
        default: break
        }

        importer = importers.first!
        let detectResult = detected[importer] ?? [:]
        detectedSchemas = detectResult.map(\.key)
    }

    // if user explicitly specified an output schema, ensure it's supported by the remaining importer
    if let schema = outputSchema {
        guard detectedSchemas.contains(schema)
        else { throw FINporterError.targetSchemaNotSupported(detectedSchemas) }
        return (importer, schema)
    }

    switch importer.outputSchemas.count {
    case 0:
        throw FINporterError.targetSchemaNotSupported([])
    case 2...:
        throw FINporterError.multipleOutputSchemasMatch(importer.outputSchemas)
    default: break
    }

    return (importer, importer.outputSchemas.first!)
}

internal func decodeAndExport<T: AllocBase>(_: T.Type,
                                            _ finPorter: FINporter,
                                            _ data: Data,
                                            _ rejectedRows: inout [T.Row],
                                            _ outputSchema: AllocSchema,
                                            _ url: URL) throws -> String {
    let finRows: [T.Row] = try finPorter.decode(T.self,
                                                data,
                                                rejectedRows: &rejectedRows,
                                                outputSchema: outputSchema,
                                                url: url)
    let items: [T] = try finRows.map { try T(from: $0) }
    let data = try finPorter.export(elements: items, format: .CSV)
    return String(data: data, encoding: .utf8) ?? ""
}
