//
//  TransactionAllocTests.swift
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

final class TxnAllocTests: XCTestCase {
    var imp: Tabular!
    var rejectedRows: [MTransaction.Row]!
    
    override func setUpWithError() throws {
        imp = Tabular()
        rejectedRows = [MTransaction.Row]()
    }
    
    func testSourceFormats() {
        let expected = Set([AllocFormat.CSV, AllocFormat.TSV])
        let actual = Set(imp.sourceFormats)
        XCTAssertEqual(expected, actual)
    }
    
    func testTargetSchema() {
        let expected: [AllocSchema] = [
            .allocAccount,
            .allocAllocation,
            .allocAsset,
            .allocCap,
            .allocTransaction,
            .allocHolding,
            .allocSecurity,
            .allocStrategy,
            .allocTracker,
        ]
        let actual = imp.outputSchemas
        XCTAssertEqual(Set(expected), Set(actual))
    }
    
    func testDetectFailsDueToHeaderMismatch() throws {
        let badHeader = """
        lesterstoryAccountID,txnSecurityID
        """
        let expected: FINporter.DetectResult = [:]
        let actual = try imp.detect(dataPrefix: badHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }
    
    func testDetectSucceeds() throws {
        let header = """
        txnTransactedAt,txnAccountID,txnSecurityID,txnLotID,txnSharePrice,txnShareCount
        """
        let expected: FINporter.DetectResult = [.allocTransaction: [.CSV]]
        let actual = try imp.detect(dataPrefix: header.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }
    
    func testDetectSucceedsWithoutOptionals() throws {
        let header = """
        txnTransactedAt,txnAccountID,txnSecurityID,txnLotID,txnSharePrice,txnShareCount
        """
        let expected: FINporter.DetectResult = [.allocTransaction: [.CSV]]
        let actual = try imp.detect(dataPrefix: header.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }
    
    func testDetectViaMain() throws {
        let header = """
        txnTransactedAt,txnAccountID,txnSecurityID,txnLotID,txnSharePrice,txnShareCount
        """
        let expected: FINporter.DetectResult = [.allocTransaction: [.CSV]]
        let main = FINprospector()
        let data = header.data(using: .utf8)!
        let actual = try main.prospect(sourceFormats: [.CSV], dataPrefix: data)
        XCTAssertEqual(1, actual.count)
        _ = actual.map { key, value in
            XCTAssertNotNil(key as? Tabular)
            XCTAssertEqual(expected, value)
        }
    }
    
    func testParseNoRejectBadAccountNumber() throws {
        let csv = """
        txnTransactedAt,txnAccountID,txnSecurityID,txnLotID,txnSharePrice,txnShareCount
        2020-12-31,   ,SPY,,1,1
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [MTransaction.Row] = try imp.decode(MTransaction.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(1, rejectedRows.count)
    }
    
    func testParseNoRejectedBadSecurityID() throws {
        let csv = """
        txnTransactedAt,txnAccountID,txnSecurityID,txnLotID,txnSharePrice,txnShareCount
        2020-12-31,1,  ,,1,1
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [MTransaction.Row] = try imp.decode(MTransaction.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(1, rejectedRows.count)
    }
    
    func testParseAcceptedDespiteBadSharePrice() throws {
        let csv = """
        txnTransactedAt,txnAccountID,txnSecurityID,txnLotID,txnSharePrice,txnShareCount
        2020-12-31,1,SPY,,xxx,1
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [MTransaction.Row] = try imp.decode(MTransaction.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
    }
    
    func testParseAcceptedDespiteBadShareCount() throws {
        let csv = """
        txnTransactedAt,txnAccountID,txnSecurityID,txnLotID,txnSharePrice,txnShareCount
        2020-12-31,1,SPY,,1,xxx
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [MTransaction.Row] = try imp.decode(MTransaction.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
    }
    
    func testParseRejectedWithBadTransactedAt() throws {
        let csv = """
        txnTransactedAt,txnAccountID,txnSecurityID,txnLotID,txnSharePrice,txnShareCount
        ,1,SPY,,1,1
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [MTransaction.Row] = try imp.decode(MTransaction.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(1, rejectedRows.count)
    }
    
    func testParseAccepted() throws {
        let csv = """
        txnTransactedAt,txnAccountID,txnSecurityID,txnLotID,txnSharePrice,txnShareCount,realizedGainLong,realizedGainShort,isTransfer
        2020-12-31,1,SPY,X,1,3,5,7,TRUE
        """
        let dataStr = csv.data(using: .utf8)!
        let actual: [MTransaction.Row] = try imp.decode(MTransaction.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
        
        let timestamp = MTransaction.parseDate("2020-12-31T00:00:00Z")!
        
        let expected: MTransaction.Row = ["realizedGainShort": 7.0,
                                          "realizedGainLong": 5.0,
                                          "txnAccountID": "1",
                                          "txnSecurityID": "SPY",
                                          "txnLotID": "X",
                                          "txnShareCount": 3.0,
                                          "txnSharePrice": 1.0,
                                          "txnTransactedAt": timestamp,
                                          "isTransfer": true]
        XCTAssertEqual([expected], actual)
    }
}
