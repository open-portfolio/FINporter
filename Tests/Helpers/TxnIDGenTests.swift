//
//  TxnIDGenTests.swift
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

final class TxnIDGenTests: XCTestCase {
    let df = ISO8601DateFormatter()

    func testBasic() throws {
        let transactionDate = df.date(from: "2021-03-01T17:00:00Z")!
        let actual = generateTransactionID(prefix: "A", transactionDate: transactionDate, transactionNo: 325)
        let expected = "A2021030100325"
        XCTAssertEqual(expected, actual)
    }
}
