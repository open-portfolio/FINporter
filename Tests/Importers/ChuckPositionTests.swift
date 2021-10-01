//
//  ChuckPositionsTests.swift
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

final class ChuckPositionsTests: XCTestCase {
    var imp: ChuckPositions!
    let df = ISO8601DateFormatter()

    let goodHeader1 = """
    "Positions for All-Accounts as of 09:59 PM ET, 09/26/2021"

    "Individual                        XXXX-1234"
    "Symbol","Description","Quantity","Price","Price Change $","Price Change %","Market Value","Day Change $","Day Change %","Cost Basis","Gain/Loss $",...
    """
    
    let goodHeader2 = "\"Positions for All-Accounts as of 09:59 PM ET, 09/26/2021\"\r\n\r\n\"Individual                        XXXX-1234\"\r\n\"Symbol\",\"Description\",\"Quantity\",\"Price\",\"Price Change $\",\"Price Change %\",\"Market Value\",\"Day Change $\",\"Day Change %\",\"Cost Basis\",\"Gain/Loss $\",\"Gain/Loss %\",\"Reinvest Dividends?\",\"Capital Gains?\",\"% Of Account\",\"Dividend Yield\",\"Last Dividend\",\"Ex-Dividend Date\",\"P/E Ratio\",\"52 Week Low\",\"52 Week High\",\"Volume\",\"Intrinsic Value\",\"In The Money\",\"Security Type\",\r\n"
    
    let goodBody = """
    "Positions for All-Accounts as of 09:59 PM ET, 09/26/2021"

    "Individual                        XXXX-1234"
    "Symbol","Description","Quantity","Price","Price Change $","Price Change %","Market Value","Day Change $","Day Change %","Cost Basis","Gain/Loss $","Gain/Loss %","Reinvest Dividends?","Capital Gains?","% Of Account","Dividend Yield","Last Dividend","Ex-Dividend Date","P/E Ratio","52 Week Low","52 Week High","Volume","Intrinsic Value","In The Money","Security Type",
    "SCHB","SCHWAB US BROAD MARKET ETF","961","$117.42","$0.10","+0.09%","$23,230.62","$96.10","+0.09%","$100,975.73","$2,254.89","+2.23%","No","--","99.49%","+1.2%","$0.34","9/22/2021","--","$76.51","$109.81","432,087","--","--","ETFs & Closed End Funds",
    "Cash & Cash Investments","--","--","--","--","--","$42.82","$0.00","0%","--","--","--","--","--","0.51%","--","--","--","--","--","--","--","--","--","Cash and Money Market",
    "Account Total","--","--","--","--","--","$23,755.44","$96.10","+0.09%","$23,975.73","$1,254.89","+2.23%","--","--","--","--","--","--","--","--","--","--",

    "Roth IRA                        XXXX-5678"
    "Symbol","Description","Quantity","Price","Price Change $","Price Change %","Market Value","Day Change $","Day Change %","Cost Basis","Gain/Loss $","Gain/Loss %","Reinvest Dividends?","Capital Gains?","% Of Account","Dividend Yield","Last Dividend","Ex-Dividend Date","P/E Ratio","52 Week Low","52 Week High","Volume","Intrinsic Value","In The Money","Security Type",
    "VOO","VANGUARD S&P","10","$211.00","$0.10","+0.09%","$2,010.00","$96.10","+0.09%","$2,010.00","$2,254.89","+2.23%","No","--","99.49%","+1.2%","$0.34","9/22/2021","--","$76.51","$109.81","432,087","--","--","ETFs & Closed End Funds",
    "IAU","STATE STREET GOLD","50","$111.00","$0.10","+0.09%","$5,050.00","$96.10","+0.09%","$5,050.00","$2,254.89","+2.23%","No","--","99.49%","+1.2%","$0.34","9/22/2021","--","$76.51","$109.81","432,087","--","--","ETFs & Closed End Funds",
    "Cash & Cash Investments","--","--","--","--","--","$42.82","$0.00","0%","--","--","--","--","--","0.51%","--","--","--","--","--","--","--","--","--","Cash and Money Market",
    "Account Total","--","--","--","--","--","$23,755.44","$96.10","+0.09%","$23,975.73","$1,254.89","+2.23%","--","--","--","--","--","--","--","--","--","--",

    
    """

    override func setUpWithError() throws {
        imp = ChuckPositions()
    }

    func testSourceFormats() {
        let expected = Set([AllocFormat.CSV])
        let actual = Set(imp.sourceFormats)
        XCTAssertEqual(expected, actual)
    }

    func testTargetSchema() {
        let expected: [AllocSchema] = [.allocMetaSource, .allocAccount, .allocHolding, .allocSecurity]
        let actual = imp.outputSchemas
        XCTAssertEqual(expected, actual)
    }

    func testDetectFailsDueToHeaderMismatch() throws {
        let badHeader = goodHeader1.replacingOccurrences(of: "Symbol", with: "Symbal")
        let expected: FINporter.DetectResult = [:]
        let actual = try imp.detect(dataPrefix: badHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceeds1() throws {
        let expected: FINporter.DetectResult = [.allocMetaSource: [.CSV], .allocAccount: [.CSV], .allocHolding: [.CSV], .allocSecurity: [.CSV]]
        let actual = try imp.detect(dataPrefix: goodHeader1.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }
    
    func testDetectSucceeds2() throws {
        let expected: FINporter.DetectResult = [.allocMetaSource: [.CSV], .allocAccount: [.CSV], .allocHolding: [.CSV], .allocSecurity: [.CSV]]
        let actual = try imp.detect(dataPrefix: goodHeader2.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectViaMain() throws {
        let expected: FINporter.DetectResult = [.allocMetaSource: [.CSV], .allocAccount: [.CSV], .allocHolding: [.CSV], .allocSecurity: [.CSV]]
        let main = FINprospector()
        let data = goodHeader1.data(using: .utf8)!
        let actual = try main.prospect(sourceFormats: [.CSV], dataPrefix: data)
        XCTAssertEqual(1, actual.count)
        _ = actual.map { key, value in
            XCTAssertNotNil(key as? ChuckPositions)
            XCTAssertEqual(expected, value)
        }
    }
    
    func testAccountBlockRE() throws {
        //let dataStr = goodBody.data(using: .utf8)!
        var str = goodBody
        var count = 0
        while let range = str.range(of: ChuckPositions.accountBlockRE, options: .regularExpression) {
            str.removeSubrange(range)
            count += 1
        }
        XCTAssertEqual(2, count)
    }
    
    func testMetaOutput() throws {
        let dataStr = goodBody.data(using: .utf8)!
        let ts = Date()
        var rr = [AllocRowed.RawRow]()

        let actual: [MSourceMeta.DecodedRow] = try imp.decode(MSourceMeta.self,
                                                        dataStr,
                                                        rejectedRows: &rr,
                                                        outputSchema: .allocMetaSource,
                                                        url: URL(string: "http://blah.com"),
                                                        timestamp: ts)
        XCTAssertNotNil(actual[0]["sourceMetaID"]!)
        XCTAssertEqual(URL(string: "http://blah.com"), actual[0]["url"])
        XCTAssertEqual("chuck_positions", actual[0]["importerID"])
        let exportedAt: Date? = actual[0]["exportedAt"] as? Date
        let expectedExportedAt = df.date(from: "2021-09-27T01:59:00+0000")!
        XCTAssertEqual(expectedExportedAt, exportedAt)
    }
    
    func testAccountOutput() throws {
        let dataStr = goodBody.data(using: .utf8)!
        var rr = [AllocRowed.RawRow]()
        
        let actual: [AllocRowed.DecodedRow] = try imp.decode(MAccount.self, dataStr, rejectedRows: &rr, outputSchema: .allocAccount)
        let expected: [AllocRowed.DecodedRow] = [
            ["accountID": "XXXX-1234", "title": "Individual"],
            ["accountID": "XXXX-5678", "title": "Roth IRA"],
        ]
        XCTAssertEqual(expected, actual)
    }
    
    func testHoldingOutput() throws {
        let dataStr = goodBody.data(using: .utf8)!
        var rr = [AllocRowed.RawRow]()
        
        let actual: [AllocRowed.DecodedRow] = try imp.decode(MHolding.self, dataStr, rejectedRows: &rr, outputSchema: .allocHolding)
        let expected: [AllocRowed.DecodedRow] = [
            ["holdingAccountID": "XXXX-1234", "holdingSecurityID": "SCHB", "shareBasis": 105.07360041623309, "shareCount": 961.0],
            ["holdingAccountID": "XXXX-1234", "holdingSecurityID": "CORE", "shareBasis": 1.0, "shareCount": 42.82],
            ["holdingAccountID": "XXXX-5678", "holdingSecurityID": "VOO", "shareBasis": 201.0, "shareCount": 10.0],
            ["holdingAccountID": "XXXX-5678", "holdingSecurityID": "IAU", "shareBasis": 101.0, "shareCount": 50.0],
            ["holdingAccountID": "XXXX-5678", "holdingSecurityID": "CORE", "shareBasis": 1.0, "shareCount": 42.82],
        ]
        XCTAssertEqual(expected, actual)
    }
    
    func testSecurityOutput() throws {
        let dataStr = goodBody.data(using: .utf8)!
        let ts = Date()
        var rr = [AllocRowed.RawRow]()
        
        let actual: [AllocRowed.DecodedRow] = try imp.decode(MSecurity.self, dataStr, rejectedRows: &rr, outputSchema: .allocSecurity, timestamp: ts)
        let expected: [AllocRowed.DecodedRow] = [
            ["securityID": "SCHB", "sharePrice": 117.42, "updatedAt": ts],
            ["securityID": "VOO","sharePrice": 211.0, "updatedAt": ts],
            ["securityID": "IAU","sharePrice": 111.0, "updatedAt": ts]
        ]
        XCTAssertEqual(expected, actual)
    }
            
    func testParseSourceMeta() throws {
        
        let str = """
        "Positions for All-Accounts as of 09:59 PM ET, 09/26/2021"

        "First block starts here...
        """
        
        let timestamp = Date()
        var rejectedRows = [AllocRowed.RawRow]()
        let dataStr = str.data(using: .utf8)!
        
        let actual: [MSourceMeta.DecodedRow] = try imp.decode(MSourceMeta.self,
                                                       dataStr,
                                                       rejectedRows: &rejectedRows,
                                                       outputSchema: .allocMetaSource,
                                                       url: URL(string: "http://blah.com"),
                                                       timestamp: timestamp)
        
        XCTAssertEqual(1, actual.count)
        XCTAssertNotNil(actual[0]["sourceMetaID"]!)
        XCTAssertEqual(URL(string: "http://blah.com"), actual[0]["url"])
        XCTAssertEqual("chuck_positions", actual[0]["importerID"])
        let exportedAt: Date? = actual[0]["exportedAt"] as? Date
        let expectedExportedAt = df.date(from: "2021-09-27T01:59:00+0000")!
        XCTAssertEqual(expectedExportedAt, exportedAt)
    }
    
    func testParseAccountTitleID() throws {
        let str = "\"Individual Something                       Xxxx-1234\""
        let actual = ChuckPositions.parseAccountTitleID(str)
        XCTAssertEqual("Individual Something", actual!.title)
        XCTAssertEqual("Xxxx-1234", actual!.id)
    }
}
