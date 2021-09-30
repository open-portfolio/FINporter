//
//  FidoHistoryTests.swift
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

import SwiftCSV
import AllocData

final class FidoHistoryActionTests: XCTestCase {
    var imp: FidoHistory!
    let df = ISO8601DateFormatter()
    var rr: [AllocBase.RawRow]!

    override func setUpWithError() throws {
        imp = FidoHistory()
        rr = []
    }

//    func testBuy() throws {
//        let csvStr = """
//        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
//        "07/02/2021","Buy","SCHB","SCHWAB US BROAD MARKET ETF","961","$105.0736","","-$100975.73",
//        """
//        
//        let timestamp1 = df.date(from: "2021-07-02T17:00:00Z")!
//        let delimitedRows = try CSV(string: String(csvStr)).namedRows
//        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
//                                                  accountID: "1",
//                                                  rejectedRows: &rr)
//        let expected: [AllocBase.DecodedRow] = [["txnSecurityID": "SCHB", "txnShareCount": 961.0, "txnAccountID": "1", "txnAction": AllocData.MTransaction.Action.buy, "txnTransactedAt": timestamp1, "txnLotID": "", "txnSharePrice": 105.0736]]
//        XCTAssertEqual(expected, actual)
//    }
}
