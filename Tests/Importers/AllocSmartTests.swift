//
//  AllocSmartTests.swift
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

final class AllocSmartTests: XCTestCase {
    let fullSource = """
    AllocateSmartly.com
    Model Portfolio Export
    Export time: 2021-03-31 10:57:42 EDT

    20M
    Account Size, 00100000
    Asset,Description,"Optimal Allocation",Change,"USD Allocation","USD Change","Optimal Total Shares"
    DBC,Commodities,0.00%,-11.97%,"0","-11,973","0"
    EFA,International Equities,1.91%,-0.54%,"1906","-540","25"
    EWJ,Japan Equities,0.00%,-1.32%,"0","-1,322","0"
    GLD,Gold,1.08%,-0.43%,"1081","-433","6"
    IEF,Int-Term US Treasuries,21.52%,+0.29%,"21520","293","190"
    IWM,US Small Cap Equities,0.00%,-6.67%,"0","-6,667","0"
    SCZ,Intl Small Cap Equities,0.00%,-29.00%,"0","-29,000","0"
    SPY,S&P 500,28.75%,+22.05%,"28748","22,051","72"
    TLT,Long-Term US Treasuries,2.18%,-0.35%,"2179","-348","15"
    VGK,Europe Equities,7.61%,+4.08%,"7607","4,079","120"
    VNQ,US Real Estate,2.39%,+2.39%,"2393","2,393","26"
    CASH,Cash,34.57%,+21.47%,"34567","21,467","n/a"

    40M
    Account Size, 00100000
    Asset,Description,"Optimal Allocation",Change,"USD Allocation","USD Change","Optimal Total Shares"
    DBC,Commodities,0.00%,-11.14%,"0","-11,144","0"
    EFA,International Equities,3.81%,-1.08%,"3812","-1,079","50"
    EWJ,Japan Equities,0.00%,-0.99%,"0","-992","0"
    GLD,Gold,2.16%,-0.87%,"2161","-867","13"
    IEF,Int-Term US Treasuries,18.04%,+0.59%,"18040","587","159"
    IWM,US Small Cap Equities,0.00%,-5.00%,"0","-5,000","0"
    SCZ,Intl Small Cap Equities,0.00%,-24.67%,"0","-24,667","0"
    SPY,S&P 500,32.50%,+21.07%,"32497","21,070","81"
    TLT,Long-Term US Treasuries,4.36%,-0.70%,"4357","-696","31"
    VGK,Europe Equities,5.71%,+3.06%,"5705","3,059","90"
    VNQ,US Real Estate,1.79%,+1.79%,"1795","1,795","19"
    CASH,Cash,31.63%,+17.93%,"31633","17,933","n/a"

    XXX
    """

    var imp: AllocSmart!

    override func setUpWithError() throws {
        imp = AllocSmart()
    }

    func testSourceFormats() {
        let expected = Set([AllocFormat.CSV])
        let actual = Set(imp.sourceFormats)
        XCTAssertEqual(expected, actual)
    }

    func testTargetSchema() {
        let expected: [AllocSchema] = [.allocAllocation]
        let actual = imp.outputSchemas
        XCTAssertEqual(expected, actual)
    }

    func testDetectFailsDueToHeaderMismatch() throws {
        let badHeader = """
        AllocateXmartly.com
        Model Portfolio Export
        Export time: 2021-03-31 10:57:42 EDT

        SOMETHING
        """
        let expected: FINporter.DetectResult = [:]
        let actual = try imp.detect(dataPrefix: badHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceeds() throws {
        let header = """
        AllocateSmartly.com
        Model Portfolio Export
        Export time: 2021-04-30 09:58:42 EDT

        SOMETHING
        """
        let expected: FINporter.DetectResult = [.allocAllocation: [.CSV]]
        let actual = try imp.detect(dataPrefix: header.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectViaMain() throws {
        let header = """
        AllocateSmartly.com
        Model Portfolio Export
        Export time: 2021-04-30 09:59:42 EDT

        SOMETHING
        """
        let expected: FINporter.DetectResult = [.allocAllocation: [.CSV]]
        let main = FINprospector()
        let data = header.data(using: .utf8)!
        let actual = try main.prospect(sourceFormats: [.CSV], dataPrefix: data)
        XCTAssertEqual(1, actual.count)
        _ = actual.map { key, value in
            XCTAssertNotNil(key as? AllocSmart)
            XCTAssertEqual(expected, value)
        }
    }

    func testParseFullToJSON() throws {
        let dataStr = fullSource.data(using: .utf8)!

        var rejectedRows = [AllocRowed.RawRow]()
        let actual: [AllocRowed.DecodedRow] = try imp.decode(MAllocation.self, dataStr, rejectedRows: &rejectedRows)
        let expected: [AllocRowed.DecodedRow] = [
            ["allocationStrategyID": "20M", "allocationAssetID": "Cmdty", "targetPct": 0.0000, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "Intl", "targetPct": 0.0191, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "Japan", "targetPct": 0.0000, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "Gold", "targetPct": 0.0108, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "ITGov", "targetPct": 0.2152, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "SC", "targetPct": 0.0000, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "IntlSC", "targetPct": 0.0000, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "LC", "targetPct": 0.2875, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "LTGov", "targetPct": 0.0218, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "Europe", "targetPct": 0.0761, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "RE", "targetPct": 0.0239, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "Cash", "targetPct": 0.3457, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "Cmdty", "targetPct": 0.0000, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "Intl", "targetPct": 0.0381, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "Japan", "targetPct": 0.0000, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "Gold", "targetPct": 0.0216, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "ITGov", "targetPct": 0.1804, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "SC", "targetPct": 0.0000, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "IntlSC", "targetPct": 0.0000, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "LC", "targetPct": 0.3250, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "LTGov", "targetPct": 0.0436, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "Europe", "targetPct": 0.0571, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "RE", "targetPct": 0.0179, "isLocked": false],
            ["allocationStrategyID": "40M", "allocationAssetID": "Cash", "targetPct": 0.3163, "isLocked": false],
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertEqual(0, rejectedRows.count)
    }

    func testParseWithActual() throws {
        let str = "AllocateSmartly.com \nModel Portfolio Export \nExport time: 2021-03-31 10:57:42 EDT\n\n20M \nAccount Size, 00100000 \nAsset,Description,\"Optimal Allocation\",Change,\"USD Allocation\",\"USD Change\",\"Optimal Total Shares\" \nDBC,Commodities,0.00%,-11.97%,\"0\",\"-11,973\",\"0\" \nEFA,International Equities,1.91%,-0.54%,\"1906\",\"-540\",\"25\" \n"

        let dataStr = str.data(using: .utf8)!

        let detectExpected: FINporter.DetectResult = [.allocAllocation: [.CSV]]
        let detectActual = try imp.detect(dataPrefix: dataStr)
        XCTAssertEqual(detectExpected, detectActual)

        var rejectedRows = [AllocRowed.RawRow]()
        let actual: [AllocRowed.DecodedRow] = try imp.decode(MAllocation.self, dataStr, rejectedRows: &rejectedRows)

        let expected: [AllocRowed.DecodedRow] = [
            ["allocationStrategyID": "20M", "allocationAssetID": "Cmdty", "targetPct": 0.00, "isLocked": false],
            ["allocationStrategyID": "20M", "allocationAssetID": "Intl", "targetPct": 0.0191, "isLocked": false],
        ]

        XCTAssertEqual(expected, actual)
        XCTAssertEqual(0, rejectedRows.count)
    }

//    static var allTests = [
//        ("testExample", testExample),
//    ]
}
