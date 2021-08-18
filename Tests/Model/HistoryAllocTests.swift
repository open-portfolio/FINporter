//
//  HistoryAllocTests.swift
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

final class HistoryAllocTests: XCTestCase {
    var imp: Tabular!
    var rejectedRows: [MHistory.Row]!

    override func setUpWithError() throws {
        imp = Tabular()
        rejectedRows = [MHistory.Row]()
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
            .allocHistory,
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
        lesterstoryAccountID,historySecurityID
        """
        let expected: FINporter.DetectResult = [:]
        let actual = try imp.detect(dataPrefix: badHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceeds() throws {
        let header = """
        historyAccountID,historySecurityID,sharePrice,shareCount,transactedAt
        """
        let expected: FINporter.DetectResult = [.allocHistory: [.CSV]]
        let actual = try imp.detect(dataPrefix: header.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceedsWithoutOptionals() throws {
        let header = """
        historyAccountID,historySecurityID
        """
        let expected: FINporter.DetectResult = [.allocHistory: [.CSV]]
        let actual = try imp.detect(dataPrefix: header.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectViaMain() throws {
        let header = """
        historyAccountID,historySecurityID,sharePrice,shareCount,transactedAt
        """
        let expected: FINporter.DetectResult = [.allocHistory: [.CSV]]
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
        securityID,accountID,sharePrice,shareCount,transactedAt
        theTitle,   ,1,1,2020-12-31
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [MHistory.Row] = try imp.decode(MHistory.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
    }

    func testParseNoRejectedBadSecurityID() throws {
        let csv = """
        historyAccountID,historySecurityID,sharePrice,shareCount,transactedAt
        1,   ,1,1,2020-12-31
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [MHistory.Row] = try imp.decode(MHistory.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
    }

    func testParseAcceptedDespiteBadSharePrice() throws {
        let csv = """
        historyAccountID,historySecurityID,sharePrice,shareCount,transactedAt
        1,X,xxx,1,2020-12-31
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [MHistory.Row] = try imp.decode(MHistory.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
    }

    func testParseAcceptedDespiteBadShareCount() throws {
        let csv = """
        historyAccountID,historySecurityID,shareCount,sharePrice,transactedAt
        1,X,  ,1,2020-12-31
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [MHistory.Row] = try imp.decode(MHistory.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
    }

    func testParseAcceptedDespiteBadTransactedAt() throws {
        let csv = """
        historyAccountID,historySecurityID,shareCount,transactedAt,sharePrice
        1,X,1,,1
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [MHistory.Row] = try imp.decode(MHistory.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
    }

    func testParseAccepted() throws {
        let csv = """
        historyAccountID,historySecurityID,historyLotID,shareCount,sharePrice,transactedAt,willBeIgnored
        1,X,,1,1,2020-12-31,xxx
        """
        let dataStr = csv.data(using: .utf8)!
        let actual: [MHistory.Row] = try imp.decode(MHistory.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)

        let timestamp = MHistory.parseYYYYMMDD("2020-12-31")!

        let expected: MHistory.Row = ["transactionID": nil,
                                      "realizedGainShort": nil,
                                      "realizedGainLong": nil,
                                      "historyAccountID": "1",
                                      "historySecurityID": "X",
                                      "historyLotID": nil,
                                      "shareCount": 1.0,
                                      "sharePrice": 1.0,
                                      "transactedAt": timestamp]
        XCTAssertEqual([expected], actual)
    }
}
