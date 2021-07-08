//
//  AllocAttribute+dump.swift
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
import FINporter

public extension AllocAttribute {
    static func dumpTable(attributes: [AllocAttribute]) -> String {
        var header = [String]()
        header.append("Name")
        header.append("Type")
        header.append("IsRequired")
        header.append("IsKey")
        header.append("Descript")

        var rows = [[String]]()

        for attribute in attributes {
            var row = [String]()
            row.append(attribute.codingKey.stringValue)
            row.append("\(attribute.type)")
            row.append("\(attribute.isRequired)")
            row.append("\(attribute.isKey)")
            row.append(attribute.descript)
            rows.append(row)
        }

        return toMarkdown(header: header, rows: rows)
    }

    private static func toMarkdown(header: [String], rows: [[String]]) -> String {
        var buffer = [String]()

        buffer.append("| \(header.joined(separator: " | ")) |")

        let underHeader = header.map { String(repeating: "-", count: $0.count) }

        buffer.append("| \(underHeader.joined(separator: " | ")) |")

        for row in rows {
            buffer.append("| \(row.joined(separator: " | ")) |")
        }

        return buffer.joined(separator: "\n")
    }
}
