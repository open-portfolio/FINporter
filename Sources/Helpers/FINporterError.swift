//
//  FINporterError.swift
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

public enum FINporterError: Error, Equatable, CustomStringConvertible {
    case notImplementedError
    case encodingError(_ msg: String)
    case decodingError(_ msg: String)
    case decodingKeyError(key: String, classType: String, _ msg: String)
    case needExplicitOutputSchema(_ supported: [AllocSchema])
    case targetSchemaNotSupported(_ supported: [AllocSchema])
    case multipleImportersMatch(_ importers: [FINporter])
    case multipleDetectedSchemasMatch(_ schemas: [AllocSchema])
    case multipleOutputSchemasMatch(_ schemas: [AllocSchema])
    case sourceFormatNotRecognized
    case importerNotRecognized(_ msg: String)

    public var localizedDescription: String { description }

    public var description: String {
        switch self {
        case .notImplementedError:
            return String("Not implemented.")
        case let .encodingError(msg):
            return String("Failure to encode. \(msg)")
        case let .decodingError(msg):
            return String("Failure to decode. \(msg)")
        case let .decodingKeyError(key, classType, msg):
            return String("Failure to decode '\(key)' in \(classType). \(msg)")
        case let .needExplicitOutputSchema(supported):
            return String("Requires explicit target schema: '\(supported.map(\.rawValue))'.")
        case let .targetSchemaNotSupported(supported):
            return String("Supported target schema: '\(supported.map(\.rawValue))'.")
        case let .multipleImportersMatch(importers):
            return String("Multiple importers match. Need to disambiguate. Importers: [\(importers.map { $0.id }.joined(separator: ", "))]")
        case let .multipleDetectedSchemasMatch(schemas):
            return String("Multiple detected schemas match. Need to disambiguate. Schemas: [\(schemas.map { $0.rawValue }.joined(separator: ", "))]")
        case let .multipleOutputSchemasMatch(schemas):
            return String("Multiple output schemas match. Need to disambiguate. Schemas: [\(schemas.map { $0.rawValue }.joined(separator: ", "))]")
        case .sourceFormatNotRecognized:
            return String("Source format not recognized.")
        case let .importerNotRecognized(msg):
            return String("Importer not recognized. \(msg)")
        }
    }
}
