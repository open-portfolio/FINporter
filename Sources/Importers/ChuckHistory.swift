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
    
    override open func decode<T: AllocRowed>(_ type: T.Type,
                                            _ data: Data,
                                            rejectedRows: inout [T.RawRow],
                                            inputFormat _: AllocFormat? = nil,
                                            outputSchema: AllocSchema? = nil,
                                            url: URL? = nil,
                                            defTimeOfDay: String? = nil,
                                            timeZone: TimeZone = TimeZone.current,
                                            timestamp: Date? = nil) throws -> [T.DecodedRow] {
        guard var str = FINporter.normalizeDecode(data) else {
            throw FINporterError.decodingError("unable to parse data")
        }
        
        var items = [T.DecodedRow]()
        
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
                let delimitedRows = try CSV(string: String(csvStr)).namedRows
                let nuItems = try decodeDelimitedRows(delimitedRows: delimitedRows,
                                                      accountID: _accountID,
                                                      defTimeOfDay: defTimeOfDay,
                                                      timeZone: timeZone,
                                                      rejectedRows: &rejectedRows)
                items.append(contentsOf: nuItems)
            }
            
            str.removeSubrange(range) // discard blocks as they are consumed
        }
        
        return items
    }
    
    internal func decodeDelimitedRows(delimitedRows: [AllocRowed.RawRow],
                                      accountID: String,
                                      defTimeOfDay: String? = nil,
                                      timeZone: TimeZone = TimeZone.current,
                                      rejectedRows: inout [AllocRowed.RawRow]) throws -> [AllocRowed.DecodedRow] {
        
        delimitedRows.reduce(into: []) { decodedRows, delimitedRow in
            
            // ignore totals row
            let rawDate = delimitedRow["Date"]
            guard rawDate != "Transactions Total" else { return }
            
            guard let rawAction = MTransaction.parseString(delimitedRow["Action"]),
                  let transactedAt = parseChuckMMDDYYYY(rawDate, defTimeOfDay: defTimeOfDay, timeZone: timeZone)
            else {
                rejectedRows.append(delimitedRow)
                return
            }
            
            guard let decodedRow = decodeRow(delimitedRow: delimitedRow,
                                             transactedAt: transactedAt,
                                             rawAction: rawAction,
                                             accountID: accountID)
            else {
                rejectedRows.append(delimitedRow)
                return
            }
            
            decodedRows.append(decodedRow)
        }
    }
    
    internal func decodeRow(delimitedRow: AllocRowed.RawRow,
                            transactedAt: Date,
                            rawAction: String,
                            accountID: String) -> AllocRowed.DecodedRow? {
        
        var isSale = false
        
        let netAction: MTransaction.Action = {
            switch rawAction {
            case "Buy", "Reinvest Shares":
                return .buysell
            case "Sell":
                isSale = true
                return .buysell
            case "Security Transfer":
                return .transfer
            case "Reinvest Dividend", "Cash Dividend", "Bank Interest":
                return .income
            default:
                // includes "Promotional Award" and anything else not captured above
                return .miscflow
            }
        }()
        
        var decodedRow: AllocRowed.DecodedRow = [
            MTransaction.CodingKeys.action.rawValue: netAction,
            MTransaction.CodingKeys.transactedAt.rawValue: transactedAt,
            MTransaction.CodingKeys.accountID.rawValue: accountID,
        ]
        
        // 'Amount' may be nil on "Security Transfer"
        let rawAmount = MTransaction.parseDouble(delimitedRow["Amount"])
        let rawSymbol = MTransaction.parseString(delimitedRow["Symbol"])
        let rawQuantity = MTransaction.parseDouble(delimitedRow["Quantity"])
        let rawSharePrice = MTransaction.parseDouble(delimitedRow["Price"])
        
        switch netAction {
        case .buysell:
            guard let symbol = rawSymbol,
                  let sharePrice = rawSharePrice,
                  let quantity = rawQuantity
            else {
                return nil
            }
            
            decodedRow[MTransaction.CodingKeys.securityID.rawValue] = symbol
            decodedRow[MTransaction.CodingKeys.sharePrice.rawValue] = sharePrice
            
            // AllocData uses sign on shareCount to determine whether sale or purchase
            let shareCount: Double = quantity * (isSale ? -1 : 1)

            decodedRow[MTransaction.CodingKeys.shareCount.rawValue] = shareCount
            
        case .transfer:
            guard let symbol = rawSymbol,
                  symbol.count > 0
            else {
                return nil
            }
            
            if rawSymbol == "NO NUMBER" {
                // assume that it's a cash transfer, where amount is required
                guard let amount = rawAmount else { return nil }
                decodedRow[MTransaction.CodingKeys.shareCount.rawValue] = amount
                decodedRow[MTransaction.CodingKeys.sharePrice.rawValue] = 1.0
            } else {
                guard let quantity = rawQuantity else { return nil }
                decodedRow[MTransaction.CodingKeys.shareCount.rawValue] = quantity
                
                if let symbol = rawSymbol {
                    decodedRow[MTransaction.CodingKeys.securityID.rawValue] = symbol
                }
                
                // amount may be nil on "Security Transfer", in which case we'll omit sharePrice
                if let amount = rawAmount {
                    let sharePrice = amount / quantity
                    decodedRow[MTransaction.CodingKeys.sharePrice.rawValue] = sharePrice
                }
            }
            
        case .income:
            guard let amount = rawAmount else { return nil }
            decodedRow[MTransaction.CodingKeys.shareCount.rawValue] = amount
            decodedRow[MTransaction.CodingKeys.sharePrice.rawValue] = 1.0
            
            // accept the income even if no symbol specified
            if let symbol = rawSymbol {
                decodedRow[MTransaction.CodingKeys.securityID.rawValue] = symbol
            }

        default:
            guard let amount = rawAmount else { return nil }
            decodedRow[MTransaction.CodingKeys.shareCount.rawValue] = amount
            decodedRow[MTransaction.CodingKeys.sharePrice.rawValue] = 1.0
        }
        
        return decodedRow
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
