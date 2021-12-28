//
//  main+transform.swift
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

import ArgumentParser
import Foundation

import FINporter

import AllocData
import SwiftCSV

extension Finporter {
    struct Transform: ParsableCommand {
        init() {}

        static var configuration = CommandConfiguration(
            commandName: "transform",
            abstract: "Transform data in file."
        )
        @Argument(help: "input file")
        var inputFilePath: String
        @Option(help: "importer (e.g. \"fido_history\") (default: auto detect)")
        var importer: String?
        @Option(help: "the target schema (e.g. \"openalloc/history\") (default: auto detect)")
        var outputSchema: String?
        @Option(help: "default time of day, in 24 hour format, for parsing naked dates (e.g. \"13:00\")")
        var defTimeOfDay: String?
        @Option(help: "geopolitical time zone identifier, for parsing naked dates (e.g. \"America/New_York\")")
        var timeZoneID: String?
        @Flag(help: "show rejected rows (default: false)")
        var showRejectedRows: Bool = false
        func run() {
            do {
                let _outputSchema = outputSchema != nil ? AllocSchema(rawValue: outputSchema!) : nil

                var rejectedRows: [AllocRowed.RawRow] = []
                let timeZone = TimeZone(identifier: timeZoneID ?? "") ?? TimeZone.current
                let str = try handleTransform(inputFilePath: inputFilePath,
                                              rejectedRows: &rejectedRows,
                                              finPorterID: importer,
                                              outputSchema: _outputSchema,
                                              defTimeOfDay: defTimeOfDay,
                                              timeZone: timeZone)
                if showRejectedRows {
//                    for row in rejectedRows {
//                        print(row)
//                    }
                    for (n, row) in rejectedRows.enumerated() {
                        print("Rejected Row #\(n + 1):")
                        for key in row.map(\.key).sorted() {
                            guard let value = row[key],
                                  value.count > 0
                            else { continue }
                            print("  \(key): \(value)")
                        }
                    }
                } else {
                    print(str)
                }
            } catch let CSVParseError.generic(message) {
                fputs("CSV generic: \(message)", stderr)
            } catch let CSVParseError.quotation(message) {
                fputs("CSV quotation: \(message)", stderr)
            } catch let error as FINporterError {
                fputs(error.description, stderr)
            } catch {
                fputs(error.localizedDescription, stderr)
            }
        }
    }
}
