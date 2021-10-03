//
//  AccountAllocTests.swift
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

final class AccountAllocTests: XCTestCase {
    var imp: Tabular!
    var rejectedRows: [AllocRowed.RawRow]!

    override func setUpWithError() throws {
        imp = Tabular()
        rejectedRows = [AllocRowed.RawRow]()
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
        accountIDX
        """
        let expected: FINporter.DetectResult = [:]
        let actual = try imp.detect(dataPrefix: badHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceeds() throws {
        let header = """
        accountID
        """
        let expected: FINporter.DetectResult = [.allocAccount: [.CSV, .TSV]]
        let actual = try imp.detect(dataPrefix: header.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceedsWithOptionals() throws {
        let header = """
        accountID,title,isActive,isTaxable
        """
        let expected: FINporter.DetectResult = [.allocAccount: [.CSV]]
        let actual = try imp.detect(dataPrefix: header.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectViaMain() throws {
        let header = """
        accountID,title,isActive,isTaxable
        """
        let expected: FINporter.DetectResult = [.allocAccount: [.CSV]]
        let main = FINprospector()
        let data = header.data(using: .utf8)!
        let actual = try main.prospect(sourceFormats: [.CSV], dataPrefix: data)
        XCTAssertEqual(1, actual.count)
        _ = actual.map { key, value in
            XCTAssertNotNil(key as? Tabular)
            XCTAssertEqual(expected, value)
        }
    }

    func testParseRejectedBadAccountNumber() throws {
        let csv = """
        title,accountID,isActive,isTaxable
        theTitle,   ,true,true
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [AllocRowed.DecodedRow] = try imp.decode(MAccount.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(1, rejectedRows.count)
    }

    func testParseAcceptedBlankTitle() throws {
        let csv = """
        accountID,title,isActive,isTaxable
        1,   ,true,true
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [AllocRowed.DecodedRow] = try imp.decode(MAccount.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
    }

    func testParseAcceptBadIsActive() throws {
        let csv = """
        accountID,title,isActive,isTaxable
        1,X,  ,true
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [AllocRowed.DecodedRow] = try imp.decode(MAccount.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
    }

    func testParseAcceptBadIsTaxable() throws {
        let csv = """
        accountID,title,isTaxable,isActive
        1,X,  ,true
        """
        let dataStr = csv.data(using: .utf8)!
        let _: [AllocRowed.DecodedRow] = try imp.decode(MAccount.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
    }

    func testParseAccepted() throws {
        let csv = """
        accountID,title,isTaxable,isActive,order,canTrade,willBeIgnored
        1,X,true,true,3,true,xxx
        """
        let dataStr = csv.data(using: .utf8)!
        let actual: [AllocRowed.DecodedRow] = try imp.decode(MAccount.self, dataStr, rejectedRows: &rejectedRows, inputFormat: .CSV)
        XCTAssertEqual(0, rejectedRows.count)
        let expected: AllocRowed.DecodedRow = ["accountID": "1",
                                      "title": "X",
                                      "isActive": true,
                                      "isTaxable": true,
                                      "canTrade": true]
        XCTAssertEqual([expected], actual)
    }
}
