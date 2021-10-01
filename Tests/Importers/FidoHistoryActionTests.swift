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
    var rr: [AllocRowed.RawRow]!

    override func setUpWithError() throws {
        imp = FidoHistory()
        rr = []
    }

    func testBuy() throws {
        let csvStr = """
        Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,Price ($),Commission ($),Fees ($),Accrued Interest ($),Amount ($),Settlement Date
         07/30/2021,BROKERAGE 200000000, YOU BOUGHT VANGUARD TAX-MANAGED INTL FD FTSE DEV M (VEA) (Cash), VEA, VANGUARD TAX-MANAGED INTL FD FTSE DEV M,Cash,0.446,51.38,,,,-22.92,08/02/2021
        """
        
        let timestamp1 = df.date(from: "2021-07-30T17:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "VEA", "txnShareCount": 0.446, "txnAccountID": "200000000", "txnAction": AllocData.MTransaction.Action.buy, "txnTransactedAt": timestamp1, "txnSharePrice": 51.38]]
        XCTAssertEqual(expected, actual)
    }
    
    func testSell() throws {
        let csvStr = """
        Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,Price ($),Commission ($),Fees ($),Accrued Interest ($),Amount ($),Settlement Date
        07/30/2021,BROKERAGE 200000000, YOU SOLD ISHARES TR 20 YR TR BD ETF (TLT) (Cash), TLT, ISHARES TR 20 YR TR BD ETF,Cash,-86,144.41,,0.07,,12418.76,08/02/2021
        """
        
        let timestamp1 = df.date(from: "2021-07-30T17:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "TLT", "txnShareCount": -86.0, "txnAccountID": "200000000", "txnAction": AllocData.MTransaction.Action.sell, "txnTransactedAt": timestamp1, "txnSharePrice": 144.41]]
        XCTAssertEqual(expected, actual)
    }
    
    func testTransferCashIn() throws {
        let csvStr = """
        Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,Price ($),Commission ($),Fees ($),Accrued Interest ($),Amount ($),Settlement Date
        07/30/2021,CASH MGMT Z00000000, TRANSFER OF ASSETS ACAT DELIVER (Cash), , No Description,Cash,,,,,,1010,
        """
        
        let timestamp1 = df.date(from: "2021-07-30T17:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "", "txnShareCount": 1010.0, "txnAccountID": "Z00000000", "txnAction": AllocData.MTransaction.Action.transfer, "txnTransactedAt": timestamp1, "txnSharePrice": 1.0]]
        XCTAssertEqual(expected, actual)
    }

    // NOTE speculative!
    func testTransferSecurityOut() throws {
        let csvStr = """
        Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,Price ($),Commission ($),Fees ($),Accrued Interest ($),Amount ($),Settlement Date
        07/30/2021,BROKERAGE 20000000, TRANSFER OF ASSETS ACAT DELIVER, TLT, ISHARES TR 20 YR TR BD ETF,Cash,-86,144.41,,0.07,,12418.76,08/02/2021
        """
        
        let timestamp1 = df.date(from: "2021-07-30T17:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "TLT", "txnShareCount": -86, "txnAccountID": "20000000", "txnAction": AllocData.MTransaction.Action.transfer, "txnTransactedAt": timestamp1, "txnSharePrice": 144.41]]
        XCTAssertEqual(expected, actual)
    }

    // NOTE speculative!
    func testTransferSecurityIn() throws {
        let csvStr = """
        Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,Price ($),Commission ($),Fees ($),Accrued Interest ($),Amount ($),Settlement Date
        07/30/2021,BROKERAGE 20000000, TRANSFER OF ASSETS ACAT RECEIVE, TLT, ISHARES TR 20 YR TR BD ETF,Cash,86,144.41,,0.07,,12418.76,08/02/2021
        """
        
        let timestamp1 = df.date(from: "2021-07-30T17:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "TLT", "txnShareCount": 86, "txnAccountID": "20000000", "txnAction": AllocData.MTransaction.Action.transfer, "txnTransactedAt": timestamp1, "txnSharePrice": 144.41]]
        XCTAssertEqual(expected, actual)
    }

    func testDividend() throws {
        let csvStr = """
        Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,Price ($),Commission ($),Fees ($),Accrued Interest ($),Amount ($),Settlement Date
        07/30/2021,BROKERAGE 200000000, DIVIDEND RECEIVED VANGUARD INTL EQUITY INDEX FDS FTSE PAC (VPL) (Cash), VPL, VANGUARD INTL EQUITY INDEX FDS FTSE PAC,Cash,,,,,,297.62,
        """
        
        let timestamp1 = df.date(from: "2021-07-30T17:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnSecurityID": "VPL", "txnShareCount": 297.62, "txnAccountID": "200000000", "txnAction": AllocData.MTransaction.Action.dividend, "txnTransactedAt": timestamp1, "txnSharePrice": 1.0]]
        XCTAssertEqual(expected, actual)
    }
    
    func testInterest() throws {
        let csvStr = """
        Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,Price ($),Commission ($),Fees ($),Accrued Interest ($),Amount ($),Settlement Date
        07/30/2021,CASH MGMT Z00000000, INTEREST EARNED FDIC INSURED DEPOSIT AT JP MORGAN BK NO (QXXXX) (Cash), QXXXX, FDIC INSURED DEPOSIT AT JP MORGAN BK NO,Cash,,,,,,1.56,
        """
        
        let timestamp1 = df.date(from: "2021-07-30T17:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnShareCount": 1.56, "txnAccountID": "Z00000000", "txnAction": AllocData.MTransaction.Action.interest, "txnTransactedAt": timestamp1, "txnSharePrice": 1.0]]
        XCTAssertEqual(expected, actual)
    }

    func testMiscCredit() throws {
        let csvStr = """
        Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,Price ($),Commission ($),Fees ($),Accrued Interest ($),Amount ($),Settlement Date
        07/30/2021,CASH MGMT Z00000000, REDEMPTION FROM CORE ACCOUNT FDIC INSURED DEPOSIT AT JP MORGAN BK NO (QXXXX) (Cash), QXXXX, FDIC INSURED DEPOSIT AT JP MORGAN BK NO,Cash,-1010,1,,,,1010,
        """
        
        let timestamp1 = df.date(from: "2021-07-30T17:00:00Z")!
        let delimitedRows = try CSV(string: String(csvStr)).namedRows
        let actual = imp.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                  rejectedRows: &rr)
        let expected: [AllocRowed.DecodedRow] = [["txnShareCount": 1010, "txnAccountID": "Z00000000", "txnAction": AllocData.MTransaction.Action.misc, "txnTransactedAt": timestamp1, "txnSharePrice": 1.0]]
        XCTAssertEqual(expected, actual)
    }

}
