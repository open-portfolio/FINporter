//
//  StringCaptureGroupTests.swift
//
// Copyright 2021, 2022 OpenAlloc LLC
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

final class StringCaptureGroupTests: XCTestCase {

    func testBasic() throws {
        let pattern = #"^Price: ([€\$])(\d\d\.\d\d)$"#
        let str = "Price: €19.00"
        let actual = str.captureGroups(for: pattern)
        let expected = ["€", "19.00"]
        XCTAssertEqual(expected, actual)
    }

    func testNested() throws {
        let pattern = #"^Price: (([€\$])(\d\d\.\d\d))$"#
        let str = "Price: €19.00"
        let actual = str.captureGroups(for: pattern)
        let expected = ["€19.00", "€", "19.00"]
        XCTAssertEqual(expected, actual)
    }
    
    func testNoMatch() throws {
        let pattern = #"^Price: ([€\$])(\d\d\.\d\d)$"#
        let str = "Price: ฿19.00"
        let actual = str.captureGroups(for: pattern)
        XCTAssertNil(actual)
    }
    
    func testEmptyPattern() throws {
        let pattern = #""#
        let str = "Price: €19.00"
        let actual = str.captureGroups(for: pattern)
        XCTAssertNil(actual)
    }
    
    func testEmptySource() throws {
        let pattern = #"^Price: ([€\$])(\d\d\.\d\d)$"#
        let str = ""
        let actual = str.captureGroups(for: pattern)
        XCTAssertNil(actual)
    }

    func testCaseInsensitive() throws {
        let pattern = #""(.+?)\s+([A-Z0-9-_]+)""#
        let str = "\"Individual Something                       abcd-1234\""
        let actual = str.captureGroups(for: pattern, options: .caseInsensitive)
        let expected = ["Individual Something", "abcd-1234"]
        XCTAssertEqual(expected, actual)
    }
}
