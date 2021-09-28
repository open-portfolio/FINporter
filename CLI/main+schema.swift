//
//  main+schema.swift
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
    struct Schema: ParsableCommand {
        static var configuration = CommandConfiguration(
            // command names are automatically generated from the type name
            // by default; you can specify an override here.
            commandName: "schema",
            abstract: "Describe schema details.",
            subcommands: [
                Account.self,
                Allocation.self,
                Asset.self,
                Cap.self,
                Transaction.self,
                Holding.self,
                Security.self,
                Strategy.self,
                Tracker.self
            ]
        )
        // defaultsubcommand: format.self)
    }
}

extension Finporter.Schema {
    struct Account: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "account",
            abstract: "Detail account schema."
        )
        func run() {
            let table = AllocAttribute.dumpTable(attributes: MAccount.attributes)
            print(table)
        }
    }

    struct Allocation: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "allocation",
            abstract: "Detail allocation schema."
        )
        func run() {
            let table = AllocAttribute.dumpTable(attributes: MAllocation.attributes)
            print(table)
        }
    }

    struct Asset: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "asset",
            abstract: "Detail asset schema."
        )
        func run() {
            let table = AllocAttribute.dumpTable(attributes: MAsset.attributes)
            print(table)
        }
    }

    struct Cap: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "cap",
            abstract: "Detail cap schema."
        )
        func run() {
            let table = AllocAttribute.dumpTable(attributes: MCap.attributes)
            print(table)
        }
    }

    struct Transaction: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "transaction",
            abstract: "Detail transaction schema."
        )
        func run() {
            let table = AllocAttribute.dumpTable(attributes: MTransaction.attributes)
            print(table)
        }
    }

    struct Holding: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "holding",
            abstract: "Detail holding schema."
        )
        func run() {
            let table = AllocAttribute.dumpTable(attributes: MHolding.attributes)
            print(table)
        }
    }

    struct Security: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "security",
            abstract: "Detail security schema."
        )
        func run() {
            let table = AllocAttribute.dumpTable(attributes: MSecurity.attributes)
            print(table)
        }
    }

    struct Strategy: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "strategy",
            abstract: "Detail strategy schema."
        )
        func run() {
            let table = AllocAttribute.dumpTable(attributes: MStrategy.attributes)
            print(table)
        }
    }

    struct Tracker: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "tracker",
            abstract: "Detail tracker schema."
        )
        func run() {
            let table = AllocAttribute.dumpTable(attributes: MTracker.attributes)
            print(table)
        }
    }
}

extension Finporter.List {
    struct Schema: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "schemas",
            abstract: "List schemas available."
        )
        func run() {
            print("Schema available:")
            AllocSchema.allCases.map(\.rawValue).forEach {
                print($0)
            }
        }
    }
}
