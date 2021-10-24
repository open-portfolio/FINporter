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
        @Option(help: "importer (e.g. \"fido_history\")")
        var importer: String?
        @Option(help: "the target schema (e.g. \"openalloc/history\")")
        var outputSchema: String?
        @Option(help: "default time of day, in 24 hour format, for parsing naked dates (e.g. \"13:00\")")
        var defTimeOfDay: String?
        @Option(help: "geopolitical time zone identifier, for parsing naked dates (e.g. \"America/New_York\")")
        var timeZoneID: String?
        func run() {
            do {
                let outputSchema_ = outputSchema != nil ? AllocSchema(rawValue: outputSchema!) : nil

                var rejectedRows: [AllocRowed.RawRow] = []
                let str = try handleTransform(inputFilePath: inputFilePath,
                                              rejectedRows: &rejectedRows,
                                              finPorterID: importer,
                                              outputSchema: outputSchema_,
                                              defTimeOfDay: defTimeOfDay,
                                              timeZoneID: timeZoneID)
                print(str)
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
