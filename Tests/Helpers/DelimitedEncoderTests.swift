//
//  DelimitedEncoderTests.swift
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

@testable import FINporter
import XCTest

final class DelimitedEncoderTests: XCTestCase {
    // TODO: ensure string values with commas are escaped if they contain delimiter

    func parseYYYYMMDD(_ dateStr: String?, separator: Character = "-") -> Date? {
        guard let components = dateStr?.trimmingCharacters(in: .whitespaces).split(separator: separator),
              components.count == 3,
              components[0].count == 4,
              components[1].count == 2,
              components[2].count == 2,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]),
              let date = DateComponents(calendar: .current, year: year, month: month, day: day).date
        else { return nil }

        return date
    }

    func testOneRow() throws {
        struct Foo: Encodable { var bar: String; var baz: String }
        let row = Foo(bar: "blah", baz: "bleep")
        let encoder = DelimitedEncoder()
        let rows = try encoder.encode(rows: row)
        let actual = String(data: rows, encoding: .utf8)
        XCTAssertEqual("blah,bleep", actual)
    }

    func testTwoRows() throws {
        struct Foo: Encodable { var bar: String; var baz: String }
        let row0 = Foo(bar: "blah0", baz: "bleep0")
        let row1 = Foo(bar: "blah1", baz: "bleep1")
        let encoder = DelimitedEncoder()
        let rows = try encoder.encode(rows: [row0, row1])
        let actual = String(data: rows, encoding: .utf8)
        XCTAssertEqual("blah0,bleep0\nblah1,bleep1\n", actual)
    }

    func testTwoRowsTabDelimited() throws {
        struct Foo: Encodable { var bar: String; var baz: String }
        let row0 = Foo(bar: "blah0", baz: "bleep0")
        let row1 = Foo(bar: "blah1", baz: "bleep1")
        let encoder = DelimitedEncoder(delimiter: "\t")
        let rows = try encoder.encode(rows: [row0, row1])
        let actual = String(data: rows, encoding: .utf8)
        XCTAssertEqual("blah0\tbleep0\nblah1\tbleep1\n", actual)
    }

    func testDate() throws {
        let halloween = parseYYYYMMDD("2020-10-31", separator: "-")!
        let christmas = parseYYYYMMDD("2020-12-25", separator: "-")!
        struct Foo: Encodable { var bar: Date; var baz: Date }
        let row = Foo(bar: halloween, baz: christmas)
        let encoder = DelimitedEncoder()
        let rows = try encoder.encode(rows: row)
        let actual = String(data: rows, encoding: .utf8)!
        XCTAssertEqual("2020-10-31,2020-12-25", actual)
    }

    func testDouble() throws {
        let onePercent = 0.01
        let negTiny = -0.00033
        struct Foo: Encodable { var bar: Double; var baz: String; var floo: Double }
        let row = Foo(bar: onePercent, baz: String(onePercent), floo: negTiny)
        let encoder = DelimitedEncoder()
        let rows = try encoder.encode(rows: row)
        let actual = String(data: rows, encoding: .utf8)!
        XCTAssertEqual("0.01,0.01,-0.00033", actual)
    }

    func testEmbeddedDelimiter() throws {
        struct Foo: Encodable { var bar: String; var baz: String }
        let row = Foo(bar: "bl,ah", baz: "bleep")
        let encoder = DelimitedEncoder()
        let rows = try encoder.encode(rows: row)
        let actual = String(data: rows, encoding: .utf8)
        XCTAssertEqual("\"bl,ah\",bleep", actual)
    }

    func testEmbeddedDoubleQuote() throws {
        struct Foo: Encodable { var bar: String; var baz: String }
        let row = Foo(bar: "bl\"ah", baz: "bleep")
        let encoder = DelimitedEncoder()
        let rows = try encoder.encode(rows: row)
        let actual = String(data: rows, encoding: .utf8)
        XCTAssertEqual("bl\\\"ah,bleep", actual)
    }

    func testEmbeddedDelimiterAndDoubleQuote() throws {
        struct Foo: Encodable { var bar: String; var baz: String }
        let row = Foo(bar: "bl\"a,h", baz: "bleep")
        let encoder = DelimitedEncoder()
        let rows = try encoder.encode(rows: row)
        let actual = String(data: rows, encoding: .utf8)
        XCTAssertEqual("\"bl\\\"a,h\",bleep", actual)
    }
}
