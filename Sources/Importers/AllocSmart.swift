//
//  AllocSmart.swift
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

import Foundation

import SwiftCSV

import AllocData

class AllocSmart: FINporter {
    // extract up to three different strategies from data

    // map to allocat names
    private static let assetClassMap = [
        "US Aggregate Bonds": "Bond",
        "Cash": "Cash",
        "Commodities": "Cmdty",
        "US Corporate Bonds": "CorpBond",
        "Emerging Market Equities": "EM",
        "Emerging Market Bonds": "EMBond",
        "Europe Equities": "Europe",
        "Global Real Estate": "GlobRE",
        "Gold": "Gold",
        "High Yield Bonds": "HYBond",
        "Int-Term US Treasuries": "ITGov",
        "International Equities": "Intl",
        "Intl Aggregate Bonds": "IntlBond",
        "International Treasuries": "IntlGov",
        "International Real Estate": "IntlRE",
        "Intl Small Cap Equities": "IntlSC",
        "International Value": "IntlVal",
        "Japan Equities": "Japan",
        "S&P 500": "LC",
        "US Large Cap Growth": "LCGrow",
        "US Large Cap Value": "LCVal",
        "Long-Term US Treasuries": "LTGov",
        "US Momentum": "Momentum",
        "Pacific Equities": "Pacific",
        "US Real Estate": "RE",
        "US Mortgage REITs": "REMort",
        "US Small Cap Equities": "SC",
        "US Small Cap Growth": "SCGrow",
        "US Small Cap Value": "SCVal",
        "Short-Term US Treasuries": "STGov",
        "TIPS": "TIPS",
        "Nasdaq 100": "Tech",
        "US Total Market": "Total"
    ]

    override var name: String { "AssetValue Smart" }
    override var id: String { "alloc_smart" }
    override var description: String { "Detect and decode export files from Allocate Smartly." }
    override var sourceFormats: [AllocFormat] { [.CSV] }
    override var outputSchemas: [AllocSchema] { [.allocAllocation] }

    override func detect(dataPrefix: Data) throws -> DetectResult {
        let headerRE = #"""
        AllocateSmart.*
        Model Portfolio.*
        Export time:.*

        """#

        guard let str = String(data: dataPrefix, encoding: .utf8),
              str.range(of: headerRE,
                        options: .regularExpression) != nil
        else {
            return [:]
        }

        return outputSchemas.reduce(into: [:]) { map, schema in
            map[schema, default: []].append(.CSV)
        }
    }

    override open func decode<T: AllocBase>(_: T.Type,
                                            _ data: Data,
                                            rejectedRows: inout [T.Row],
                                            inputFormat _: AllocFormat? = nil,
                                            outputSchema _: AllocSchema? = nil,
                                            url _: URL? = nil,
                                            timestamp _: Date = Date()) throws -> [T.Row] {
        guard var str = String(data: data, encoding: .utf8) else {
            throw FINporterError.decodingError("unable to parse data")
        }

        var items = [T.Row]()

        let blockRE = #"""
        .+
        Account Size, \d+.*
        Asset,Description,.+
        (?:.+[\n\r])+
        """#

        // returns first match to RE as Range<String.Index (nil if none)
        while let range = str.range(of: blockRE, options: .regularExpression) {
            let block = str[range]

            // first line is the title
            let titleRange = block.lineRange(for: ..<block.startIndex)
            let strategyID = block[titleRange].trimmingCharacters(in: .whitespacesAndNewlines)

            let csvRE = #"Asset,Description,(?:.+(\r?\n|\Z))+"#

            if let csvRange = block.range(of: csvRE, options: .regularExpression) {
                let csvStr = block[csvRange]
                let csv = try CSV(string: String(csvStr))

                var order = 0

                for row in csv.namedRows {
                    // required values
                    guard let rawDescript = T.parseString(row["Description"]),
                          rawDescript.count > 0,
                          let assetID = AllocSmart.assetClassMap[rawDescript],
                          let targetPct = T.parsePercent(row["Optimal Allocation"]),
                          targetPct >= 0
                    else {
                        rejectedRows.append(row)
                        continue
                    }

                    // optional values

                    items.append([
                        MAllocation.CodingKeys.strategyID.rawValue: strategyID,
                        MAllocation.CodingKeys.assetID.rawValue: assetID,
                        MAllocation.CodingKeys.targetPct.rawValue: targetPct,
                        MAllocation.CodingKeys.isLocked.rawValue: false
                    ])

                    order += 1
                }
            }

            str.removeSubrange(range)
        }

        return items // as! [T]
    }
}
