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

import SwiftCSV
import AllocData

final class ChuckHistoryActionTests: XCTestCase {
    var imp: ChuckHistory!
    let df = ISO8601DateFormatter()
    var rr: [AllocRowed.RawRow]!
    let tzNewYork = TimeZone(identifier: "America/New_York")!

    override func setUpWithError() throws {
        imp = ChuckHistory()
        rr = []
    }

    func testBuy() throws {
        let csvStr = """
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        "07/02/2021","Buy","SCHB","SCHWAB US BROAD MARKET ETF","961","$105.0736","","-$100975.73",
        """
        
        let timestamp1 = df.date(from: "2021-07-02T16:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  accountID: "1",
                                                 timeZone: tzNewYork,
                                                 rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "SCHB", "txnShareCount": 961.0, "txnAccountID": "1", "txnAction": MTransaction.Action.buysell, "txnTransactedAt": timestamp1, "txnSharePrice": 105.0736]]
        XCTAssertEqual(expected, actual)
    }
    
    func testSell() throws {
        let csvStr = """
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        "09/27/2021","Sell","VOO","VANGUARD S&P 500","10","$137.1222","","$1370.12",
        """
        
        let timestamp1 = df.date(from: "2021-09-27T16:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  accountID: "1",
                                                 timeZone: tzNewYork,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "VOO", "txnShareCount": -10.0, "txnAccountID": "1", "txnAction": MTransaction.Action.buysell, "txnTransactedAt": timestamp1, "txnSharePrice": 137.1222]]
        XCTAssertEqual(expected, actual)
    }

    func testTransferCashIn() throws {
        let csvStr = """
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        "06/06/2021","Security Transfer","NO NUMBER","TOA ACAT 0001","","","","$101000.00",
        """
        
        let timestamp1 = df.date(from: "2021-06-06T16:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  accountID: "1",
                                                 timeZone: tzNewYork,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnShareCount": 101000.00, "txnAccountID": "1", "txnAction": MTransaction.Action.transfer, "txnTransactedAt": timestamp1, "txnSharePrice": 1.0]]
        XCTAssertEqual(expected, actual)
    }

    // NOTE speculative!
    func testTransferSecurityOut() throws {
        let csvStr = """
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        "06/06/2021","Security Transfer","EEM","ACAT 0001","100.0","120.0010","","-$12000.10",
        """
        
        let timestamp1 = df.date(from: "2021-06-06T16:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  accountID: "1",
                                                 timeZone: tzNewYork,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "EEM", "txnShareCount": 100.0, "txnAccountID": "1", "txnAction": MTransaction.Action.transfer, "txnTransactedAt": timestamp1, "txnSharePrice": -120.0010]]
        XCTAssertEqual(expected, actual)
    }

    // NOTE speculative!
    func testTransferSecurityIn() throws {
        let csvStr = """
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        "06/06/2021","Security Transfer","EEM","ACAT 0001","100.0","120.0010","","$12000.10",
        """
        
        let timestamp1 = df.date(from: "2021-06-06T16:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  accountID: "1",
                                                 timeZone: tzNewYork,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "EEM", "txnShareCount": 100.0, "txnAccountID": "1", "txnAction": MTransaction.Action.transfer, "txnTransactedAt": timestamp1, "txnSharePrice": 120.0010]]
        XCTAssertEqual(expected, actual)
    }

    func testDividend() throws {
        let csvStr = """
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        "06/06/2021","Cash Dividend","SCHB","SCHWAB US BROAD MARKET ETF","","","","$122.13",
        """
        
        let timestamp1 = df.date(from: "2021-06-06T16:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  accountID: "1",
                                                 timeZone: tzNewYork,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "SCHB", "txnShareCount": 122.13, "txnAccountID": "1", "txnAction": MTransaction.Action.income, "txnTransactedAt": timestamp1, "txnSharePrice": 1.0]]
        XCTAssertEqual(expected, actual)
    }

    func testInterest() throws {
        let csvStr = """
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        "06/06/2021 as of 06/05/2021","Bank Interest","","BANK INT SCHWAB BANK","","","","$0.51",

        """
        
        let timestamp1 = df.date(from: "2021-06-06T16:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  accountID: "1",
                                                 timeZone: tzNewYork,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnShareCount": 0.51, "txnAccountID": "1", "txnAction": MTransaction.Action.income, "txnTransactedAt": timestamp1, "txnSharePrice": 1.0]]
        XCTAssertEqual(expected, actual)
    }

    func testMiscCredit() throws {
        let csvStr = """
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        "06/06/2021","Promotional Award","","PROMOTIONAL AWARD","","","","$100.00",

        """
        
        let timestamp1 = df.date(from: "2021-06-06T16:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  accountID: "1",
                                                 timeZone: tzNewYork,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnShareCount": 100.00, "txnAccountID": "1", "txnAction": MTransaction.Action.miscflow, "txnTransactedAt": timestamp1, "txnSharePrice": 1.0]]
        XCTAssertEqual(expected, actual)
    }

    func testMiscDebit() throws {
        let csvStr = """
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        "06/06/2021","CHECK PAID","","CHECK PAID","","","","-$100.00",

        """
        
        let timestamp1 = df.date(from: "2021-06-06T16:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  accountID: "1",
                                                 timeZone: tzNewYork,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnShareCount": -100.00, "txnAccountID": "1", "txnAction": MTransaction.Action.miscflow, "txnTransactedAt": timestamp1, "txnSharePrice": 1.0]]
        XCTAssertEqual(expected, actual)
    }

    func testIgnoreTotalRow() throws {
        let csvStr = """
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        Transactions Total,"","","","","","",$520.82
        """
        
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = try imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  accountID: "1",
                                                 timeZone: tzNewYork,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = []
        XCTAssertEqual(expected, actual)
    }
    
    func testVarious() throws {
        
        let YYYYMMDDts = parseFidoMMDDYYYY("03/01/2021", timeZone: tzNewYork)!
        let miscflow = AllocData.MTransaction.Action.miscflow
        let income = AllocData.MTransaction.Action.income
        let buysell = AllocData.MTransaction.Action.buysell
        let transfer = AllocData.MTransaction.Action.transfer
        let accountID = "XXXX-5678"
        
        let rows: [(csvRow: String, expected: AllocRowed.DecodedRow, rejectedRows: Int)] = [

            (
            """
            "03/01/2021","MoneyLink Transfer","","My Bank","","","","-$17.00",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": miscflow, "txnShareCount": -17.0, "txnAccountID": accountID, "txnSharePrice": 1.0],
            0),

            (
            """
            "03/01/2021","Sell","VOO","VANGUARD S&P 500","10","$17.00","$0.04","$170.12",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": buysell, "txnShareCount": -10.0, "txnAccountID": accountID, "txnSharePrice": 17.0, "txnSecurityID": "VOO"],
            0),

            (
            """
            "03/01/2021","Buy","VOO","VANGUARD S&P 500","10","$17.0","","-$1370.12",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": buysell, "txnShareCount": 10.0, "txnAccountID": accountID, "txnSharePrice": 17.0, "txnSecurityID": "VOO"],
            0),

            (
            """
            "03/01/2021","Reinvest Shares","VOO","VANGUARD S&P 500","0.10","$17.00","","-$3.71",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": buysell, "txnShareCount": 0.1, "txnAccountID": accountID, "txnSharePrice": 17.0, "txnSecurityID": "VOO"],
            0),

            // with OUTGOING transfer of securities, there's no indication of cash value
            (
            """
            "03/01/2021","Security Transfer","VOO","VANGUARD S&P 500","-50","","","",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": transfer, "txnShareCount": -50.0, "txnAccountID": accountID, "txnSecurityID": "VOO"],
            0),

            // with INCOMING transfer of securities, there's no indication of cash value
            (
            """
            "03/01/2021","Security Transfer","VOO","VANGUARD S&P 500","200","","","",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": transfer, "txnShareCount": 200.0, "txnAccountID": accountID, "txnSecurityID": "VOO"],
            0),

            (
            """
            "03/01/2021","Security Transfer","NO NUMBER","TOA ACAT 0123","","","","$200.00",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": transfer, "txnShareCount": 200.0, "txnAccountID": accountID, "txnSharePrice": 1.0],
            0),

            (
            """
            "03/01/2021","Security Transfer","NO NUMBER","TOA ACAT 0123","","","","-$200.00",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": transfer, "txnShareCount": -200.0, "txnAccountID": accountID, "txnSharePrice": 1.0],
            0),

            (
            """
            "03/01/2021","Reinvest Dividend","VOO","VANGUARD S&P 500","","","","$17.00",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": income, "txnShareCount": 17.0, "txnAccountID": accountID, "txnSharePrice": 1.0, "txnSecurityID": "VOO"],
            0),

            (
            """
            "03/01/2021","Cash Dividend","VOO","VANGUARD S&P 500","","","","$17.00",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": income, "txnShareCount": 17.0, "txnAccountID": accountID, "txnSharePrice": 1.0, "txnSecurityID": "VOO"],
            0),

            (
            """
            "03/01/2021 as of 09/26/2021","Bank Interest","","BANK INT 123456-789123 SCHWAB BANK","","","","$17.00",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": income, "txnShareCount": 17.0, "txnAccountID": accountID, "txnSharePrice": 1.0],
            0),
            
            (
            """
            "03/01/2021","Promotional Award","","PROMOTIONAL AWARD","","","","$100.00",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": miscflow, "txnShareCount": 100.0, "txnAccountID": accountID, "txnSharePrice": 1.0],
            0),

            (
            """
            "03/01/2021","Random thing that cannot be anticipated","","RANDOM THING","","","","$100.00",
            """,
            ["txnTransactedAt": YYYYMMDDts, "txnAction": miscflow, "txnShareCount": 100.0, "txnAccountID": accountID, "txnSharePrice": 1.0],
            0),
        ]
        
        let body = """
        "Transactions  for account XXXX-5678 as of 03/01/2021 22:00:26 ET"
        "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
        ##ROW##
        """
        
        for row in rows {
            var rr = [AllocRowed.RawRow]()
            let dataStr = body.replacingOccurrences(of: "##ROW##", with: row.csvRow).data(using: .utf8)!
            let actual: [AllocRowed.DecodedRow] = try imp.decode(MTransaction.self, dataStr, rejectedRows: &rr, timeZone: tzNewYork)

            XCTAssertEqual([row.expected], actual, "ROW: \(row.csvRow)")
            XCTAssertEqual(row.rejectedRows, rr.count, "ROW: \(row.csvRow)")
        }
    }
}
