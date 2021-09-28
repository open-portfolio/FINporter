//
//  ChuckHistory.swift
//
//
//  Input: for use with XXXX1234_Transactions_YYYYMMDD-HHMMSS.CSV from Schwab Brokerage Services
//
//  Output: supports openalloc/history schema
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

class ChuckHistory: FINporter {
    override var name: String { "Chuck History" }
    override var id: String { "chuck_history" }
    override var description: String { "Detect and decode account history export files from Schwab, for sale and purchase info." }
    override var sourceFormats: [AllocFormat] { [.CSV] }
    override var outputSchemas: [AllocSchema] { [.allocTransaction] }
    
    internal static let headerRE = #"""
    "Transactions\s+for .+? as of .+"
    "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
    """#
    
    internal static let accountBlockRE = #"""
    (?:"Transactions\s+for .+? as of .+")
    "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
    (?:.+(\n|\Z))+
    """#
    
    internal static let csvRE = #"""
    "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount",
    (?:.+(\n|\Z))+
    """#
    
    override func detect(dataPrefix: Data) throws -> DetectResult {
        guard let str = FINporter.normalizeDecode(dataPrefix),
              str.range(of: ChuckHistory.headerRE,
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
                                            outputSchema: AllocSchema? = nil,
                                            url: URL? = nil,
                                            defTimeOfDay: String? = nil,
                                            defTimeZone: String? = nil,
                                            timestamp: Date? = nil) throws -> [T.Row] {
        guard var str = FINporter.normalizeDecode(data) else {
            throw FINporterError.decodingError("unable to parse data")
        }
        
        var items = [T.Row]()
        
        // one block per account expected
        while let range = str.range(of: ChuckHistory.accountBlockRE,
                                    options: .regularExpression) {
            let block = str[range]
            
            // first line has the account ID
            let accountID: String? = {
                let _range = block.lineRange(for: ..<block.startIndex)
                let rawStr = block[_range].trimmingCharacters(in: .whitespacesAndNewlines)
                return ChuckHistory.parseAccountID(rawStr)
            }()
            
            if let _accountID = accountID,
               let csvRange = block.range(of: ChuckHistory.csvRE,
                                          options: .regularExpression) {
                let csvStr = block[csvRange]
                let csv = try CSV(string: String(csvStr))
                for row in csv.namedRows {
                    
                    guard let action = T.parseString(row["Action"]),
                          ["Buy", "Sell"].contains(action),
                          let securityID = T.parseString(row["Symbol"]),
                          securityID.count > 0,
                          let rawQuantity = T.parseDouble(row["Quantity"]),
                          let sharePrice = T.parseDouble(row["Price"]),
                          let rawDate = row["Date"],
                          let transactedAt = parseChuckMMDDYYYY(rawDate, defTimeOfDay: defTimeOfDay, defTimeZone: defTimeZone)
                    else {
                        rejectedRows.append(row)
                        continue
                    }
                    
                    // optional values
                    
                    let shareCount: Double = {
                        switch action {
                        case "Buy":
                            return rawQuantity
                        case "Sell":
                            return -1 * rawQuantity
                        default:
                            return 0
                        }
                    }()
                    
                    let lotID = ""
                    let transactionID = ""
                    
                    items.append([
                        MTransaction.CodingKeys.transactedAt.rawValue: transactedAt,
                        MTransaction.CodingKeys.accountID.rawValue: _accountID,
                        MTransaction.CodingKeys.securityID.rawValue: securityID,
                        MTransaction.CodingKeys.lotID.rawValue: lotID,
                        MTransaction.CodingKeys.shareCount.rawValue: shareCount,
                        MTransaction.CodingKeys.sharePrice.rawValue: sharePrice,
                        MTransaction.CodingKeys.transactionID.rawValue: transactionID,
                        //MTransaction.CodingKeys.realizedGainShort.rawValue: nil,
                        //MTransaction.CodingKeys.realizedGainLong.rawValue: nil,
                    ])
                }
            }
            
            str.removeSubrange(range) // discard blocks as they are consumed
        }
        
        return items
    }
    
    // parse ""Transactions  for account XXXX-1234 as of 09/26/2021 22:00:26 ET"" to extract "XXXX-1234"
    internal static func parseAccountID(_ rawStr: String) -> String? {
        let pattern = #""Transactions\s+for account ([A-Z0-9-_]+) as of.+""#
        guard let captured = rawStr.captureGroups(for: pattern, options: .caseInsensitive),
              captured.count == 1
        else { return nil }
        return captured[0]
    }
}
