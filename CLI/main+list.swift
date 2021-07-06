//
//  main+list.swift
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
    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(
            // Command names are automatically generated from the type name
            // by default; you can specify an override here.
            commandName: "list",
            abstract: "List things available.",
            subcommands: [Schema.self, Format.self, Importer.self]
        )
        // defaultSubcommand: Format.self)
    }
}

extension Finporter.List {
    struct Format: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "formats",
            abstract: "List formats available."
        )
        func run() {
            print("Formats available:")
            AllocFormat.allCases.map(\.rawValue).forEach {
                print($0)
            }
        }
    }
}

extension Finporter.List {
    struct Importer: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "importers",
            abstract: "List importers available."
        )
        func run() {
            print("Importers available:")
            FINprospector().importers.forEach {
                print("\($0.name) (\($0.id)): \($0.description)")
            }
        }
    }
}
