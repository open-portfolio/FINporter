//
//  TabularTests.swift
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

final class TabularTests: XCTestCase {
    var imp: Tabular!
    var rejectedRows: [MCap.RawRow]!
    let df = ISO8601DateFormatter()

    override func setUpWithError() throws {
        imp = Tabular()
        rejectedRows = [MCap.RawRow]()
    }

    func testUnableToDetermineInputFormat() {
        let dataStr = "foo,bar".data(using: .utf8)!
        XCTAssertThrowsError(try imp.decode(MAccount.self, dataStr, rejectedRows: &rejectedRows)) { error in
            XCTAssertEqual(error as! FINporterError, FINporterError.decodingError("Unable to infer format (and delimiter) from url."))
        }
    }

    // ensure the missing gains show as blank ('') in output and not 'nil'
    func testExportedMissingGainsAreBlank() throws {
        let datetime1 = df.date(from: "2021-03-01T17:00:00Z")!
        let txn = MTransaction(action: .buysell, transactedAt: datetime1, accountID: "1", securityID: "SPY", lotID: "", shareCount: 3, sharePrice: 4, realizedGainShort: nil, realizedGainLong: nil)
        let data = try imp.export(elements: [txn], format: .CSV)
        let actual = String(data: data, encoding: .utf8)
        let expected = "txnAction,txnTransactedAt,txnAccountID,txnSecurityID,txnLotID,txnShareCount,txnSharePrice,realizedGainShort,realizedGainLong\nbuysell,2021-03-01T17:00:00Z,1,SPY,,3.0,4.0,,\n"
        XCTAssertEqual(expected, actual)
    }
}
