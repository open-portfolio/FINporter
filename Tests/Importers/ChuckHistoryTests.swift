//
//  ChuckHistoryTests.swift
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

import AllocData

final class ChuckHistoryTests: XCTestCase {
    var imp: ChuckHistory!
    let df = ISO8601DateFormatter()

    let goodHeader = """
    "Transactions  for account XXXX-1234 as of 09/26/2021 22:00:26 ET"
    "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
    """
    
    let goodBody = """
    "Transactions  for account XXXX-1234 as of 09/27/2021 22:00:26 ET"
    "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
    "08/03/2021","Promotional Award","","PROMOTIONAL AWARD","","","","$100.00",
    "07/02/2021","Buy","SCHB","SCHWAB US BROAD MARKET ETF","961","$105.0736","","-$100975.73",
    "06/16/2021","Security Transfer","NO NUMBER","TOA ACAT 0226","","","","$101000.00",
    Transactions Total,"","","","","","",$524.82

    "Transactions  for account XXXX-5678 as of 09/27/2021 22:00:26 ET"
    "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
    "09/27/2021","Sell","VOO","VANGUARD S&P 500","10","$137.1222","","$1370.12",
    "07/16/2021 as of 07/15/2021","Bank Interest","","BANK INT 061621-071521 SCHWAB BANK","","","","$0.55",
    Transactions Total,"","","","","","",$524.82
    """

    override func setUpWithError() throws {
        imp = ChuckHistory()
    }

    func testSourceFormats() {
        let expected = Set([AllocFormat.CSV])
        let actual = Set(imp.sourceFormats)
        XCTAssertEqual(expected, actual)
    }

    func testTargetSchema() {
        let expected: [AllocSchema] = [.allocHistory]
        let actual = imp.outputSchemas
        XCTAssertEqual(expected, actual)
    }

    func testDetectFailsDueToHeaderMismatch() throws {
        let badHeader = goodHeader.replacingOccurrences(of: "Symbol", with: "Symbal")
        let expected: FINporter.DetectResult = [:]
        let actual = try imp.detect(dataPrefix: badHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceeds() throws {
        let expected: FINporter.DetectResult = [.allocHistory: [.CSV]]
        let actual = try imp.detect(dataPrefix: goodHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectViaMain() throws {
        let expected: FINporter.DetectResult = [.allocHistory: [.CSV]]
        let main = FINprospector()
        let data = goodHeader.data(using: .utf8)!
        let actual = try main.prospect(sourceFormats: [.CSV], dataPrefix: data)
        XCTAssertEqual(1, actual.count)
        _ = actual.map { key, value in
            XCTAssertNotNil(key as? ChuckHistory)
            XCTAssertEqual(expected, value)
        }
    }
    
    func testAccountBlockRE() throws {
        var str = goodBody
        var count = 0
        while let range = str.range(of: ChuckHistory.accountBlockRE, options: .regularExpression) {
            str.removeSubrange(range)
            count += 1
        }
        XCTAssertEqual(2, count)
    }

    func testRows() throws {
        let dataStr = goodBody.data(using: .utf8)!
        var rr = [MHistory.Row]()
        
        let timestamp1 = df.date(from: "2021-07-02T17:00:00Z")
        let timestamp2 = df.date(from: "2021-09-27T17:00:00Z")

        let actual: [MHistory.Row] = try imp.decode(MHistory.self, dataStr, rejectedRows: &rr, outputSchema: .allocHistory)
        let expected: [MHistory.Row] = [
            ["historyAccountID": "XXXX-1234", "historySecurityID": "SCHB", "sharePrice": 105.0736, "shareCount": 961.0, "transactedAt": timestamp1, "transactionID": "H2021070200001"],
            ["historyAccountID": "XXXX-5678", "historySecurityID": "VOO", "sharePrice": 137.1222, "shareCount": -10.0, "transactedAt": timestamp2, "transactionID": "H2021092700001"],
        ]
        XCTAssertEqual(expected, actual)
    }
    
    func testParseAccountTitleID() throws {
        let str = "\"Transactions  for account Xxxx-1234 as of 09/26/2021 22:00:26 ET\""
        let actual = ChuckHistory.parseAccountID(str)
        XCTAssertEqual("Xxxx-1234", actual)
    }
}
