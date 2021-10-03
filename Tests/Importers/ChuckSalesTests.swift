//
//  ChuckSalesTests.swift
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

final class ChuckSalesTests: XCTestCase {
    var imp: ChuckSales!

    override func setUpWithError() throws {
        imp = ChuckSales()
    }

    func testSourceFormats() {
        let expected = Set([AllocFormat.CSV])
        let actual = Set(imp.sourceFormats)
        XCTAssertEqual(expected, actual)
    }

    func testTargetSchema() {
        let expected: [AllocSchema] = [.allocTransaction]
        let actual = imp.outputSchemas
        XCTAssertEqual(expected, actual)
    }

    func testDetectFailsDueToHeaderMismatch() throws {
        let badHeader = """
        Realized Gain/Loss for XXXX-1234 for 08/29/2021 to 09/28/2021 as of Tue Sep 28  23:17:11 EDT 2021
        "Xymbol","Name","Closed Date","Quantity","Proceeds","CostBasis","Total Gain/Loss ($)","Total Gain/Loss (%)","Long Term Gain/Loss ($)","Long Term Gain/Loss (%)","Short Term Gain/Loss ($)","Short Term Gain/Loss (%)","Wash Sale?","Disallowed Loss","Transaction Closed Date","Transaction Cost Basis","Total Transaction Gain/Loss ($)","Total Transaction Gain/Loss (%)","LT Transaction Gain/Loss ($)","LT Transaction Gain/Loss (%)","ST Transaction Gain/Loss ($)","ST Transaction Gain/Loss (%)"
        """
        let expected: FINporter.DetectResult = [:]
        let actual = try imp.detect(dataPrefix: badHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceeds() throws {
        let header = """
        Realized Gain/Loss for XXXX-1234 for 08/29/2021 to 09/28/2021 as of Tue Sep 28  23:17:11 EDT 2021
        "Symbol","Name","Closed Date","Quantity","Proceeds","CostBasis","Total Gain/Loss ($)","Total Gain/Loss (%)","Long Term Gain/Loss ($)","Long Term Gain/Loss (%)","Short Term Gain/Loss ($)","Short Term Gain/Loss (%)","Wash Sale?","Disallowed Loss","Transaction Closed Date","Transaction Cost Basis","Total Transaction Gain/Loss ($)","Total Transaction Gain/Loss (%)","LT Transaction Gain/Loss ($)","LT Transaction Gain/Loss (%)","ST Transaction Gain/Loss ($)","ST Transaction Gain/Loss (%)"
        """
        let expected: FINporter.DetectResult = [.allocTransaction: [.CSV]]
        let actual = try imp.detect(dataPrefix: header.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectViaMain() throws {
        let header = """
        Realized Gain/Loss for XXXX-1234 for 08/29/2021 to 09/28/2021 as of Tue Sep 28  23:17:11 EDT 2021
        "Symbol","Name","Closed Date","Quantity","Proceeds","CostBasis","Total Gain/Loss ($)","Total Gain/Loss (%)","Long Term Gain/Loss ($)","Long Term Gain/Loss (%)","Short Term Gain/Loss ($)","Short Term Gain/Loss (%)","Wash Sale?","Disallowed Loss","Transaction Closed Date","Transaction Cost Basis","Total Transaction Gain/Loss ($)","Total Transaction Gain/Loss (%)","LT Transaction Gain/Loss ($)","LT Transaction Gain/Loss (%)","ST Transaction Gain/Loss ($)","ST Transaction Gain/Loss (%)"
        """
        let expected: FINporter.DetectResult = [.allocTransaction: [.CSV]]
        let main = FINprospector()
        let data = header.data(using: .utf8)!
        let actual = try main.prospect(sourceFormats: [.CSV], dataPrefix: data)
        XCTAssertEqual(1, actual.count)
        _ = actual.map { key, value in
            XCTAssertNotNil(key as? ChuckSales)
            XCTAssertEqual(expected, value)
        }
    }

    func testParse() throws {
        let str = """
        Realized Gain/Loss for XXXX-1234 for 08/29/2021 to 09/28/2021 as of Tue Sep 28  23:17:11 EDT 2021
        "Symbol","Name","Closed Date","Quantity","Proceeds","CostBasis","Total Gain/Loss ($)","Total Gain/Loss (%)","Long Term Gain/Loss ($)","Long Term Gain/Loss (%)","Short Term Gain/Loss ($)","Short Term Gain/Loss (%)","Wash Sale?","Disallowed Loss","Transaction Closed Date","Transaction Cost Basis","Total Transaction Gain/Loss ($)","Total Transaction Gain/Loss (%)","LT Transaction Gain/Loss ($)","LT Transaction Gain/Loss (%)","ST Transaction Gain/Loss ($)","ST Transaction Gain/Loss (%)"
        "VEA","VANGUARD TAX-MANAGEDINTL FD FTSE DEV MKTETF","09/27/2021","3","$12.00","$10.00","$2.00","1.95%","0.50","--","$1.50","1.95%","No","","","","","","","","",""
        """

        var rejectedRows = [AllocRowed.RawRow]()
        let dataStr = str.data(using: .utf8)!
        let actual: [AllocRowed.DecodedRow] = try imp.decode(MTransaction.self, dataStr, rejectedRows: &rejectedRows)

        let YYYYMMDDts = parseChuckMMDDYYYY("09/27/2021")!
        let expected: AllocRowed.DecodedRow = [
            "txnAction": MTransaction.Action.buysell,
            "txnTransactedAt": YYYYMMDDts,
            "txnAccountID": "XXXX-1234",
            "txnSecurityID": "VEA",
            "txnLotID": "",
            "txnShareCount": -3.000,
            "txnSharePrice": 4.000,
            "realizedGainShort": 1.50,
            "realizedGainLong": 0.50,
        ]

        XCTAssertTrue(areEqual([expected], actual))
        XCTAssertEqual(0, rejectedRows.count)
    }
}
