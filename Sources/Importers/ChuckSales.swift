//
//  ChuckSales.swift
//
//
//  Input: for use with XXXX0000_GainLoss_Realized_YYYYMMDD-HHMMSS.CSV from Schwab Brokerage Services
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

class ChuckSales: FINporter {
    override var name: String { "Chuck Sales" }
    override var id: String { "chuck_sales" }
    override var description: String { "Detect and decode realized sale export files from Schwab." }
    override var sourceFormats: [AllocFormat] { [.CSV] }
    override var outputSchemas: [AllocSchema] { [.allocTransaction] }
    
    internal static let headerRE = #"""
    Realized Gain/Loss for .+? as of .+
    "Symbol","Name","Closed Date","Quantity","Proceeds","CostBasis","Total Gain/Loss \(\$\)","Total Gain/Loss \(%\)","Long Term Gain/Loss \(\$\)","Long Term Gain/Loss \(%\)","Short Term Gain/Loss \(\$\)","Short Term Gain/Loss \(%\)",.+
    """#
    
    internal static let accountBlockRE = #"""
    (?:Realized Gain/Loss for .+? as of .+)
    "Symbol","Name","Closed Date","Quantity","Proceeds","CostBasis","Total Gain/Loss \(\$\)","Total Gain/Loss \(%\)","Long Term Gain/Loss \(\$\)","Long Term Gain/Loss \(%\)","Short Term Gain/Loss \(\$\)","Short Term Gain/Loss \(%\)",.+
    (?:.+(\n|\Z))+
    """#
    
    internal static let csvRE = #"""
    "Symbol","Name","Closed Date","Quantity","Proceeds","CostBasis","Total Gain/Loss \(\$\)","Total Gain/Loss \(%\)","Long Term Gain/Loss \(\$\)","Long Term Gain/Loss \(%\)","Short Term Gain/Loss \(\$\)","Short Term Gain/Loss \(%\)",.+
    (?:.+(\n|\Z))+
    """#
    
    override func detect(dataPrefix: Data) throws -> DetectResult {
        guard let str = FINporter.normalizeDecode(dataPrefix),
              str.range(of: ChuckSales.headerRE,
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
                                            defTimeZone: String? = nil,
                                            timestamp: Date? = nil) throws -> [T.DecodedRow] {
        guard var str = FINporter.normalizeDecode(data) else {
            throw FINporterError.decodingError("unable to parse data")
        }
        
        var items = [T.DecodedRow]()
        
        // one block per account expected
        while let range = str.range(of: ChuckSales.accountBlockRE,
                                    options: .regularExpression) {
            let block = str[range]
            
            // first line has the account ID
            let accountID: String? = {
                let _range = block.lineRange(for: ..<block.startIndex)
                let rawStr = block[_range].trimmingCharacters(in: .whitespacesAndNewlines)
                return ChuckSales.parseAccountID(rawStr)
            }()
            
            if let _accountID = accountID,
               let csvRange = block.range(of: ChuckSales.csvRE,
                                          options: .regularExpression) {
                let csvStr = block[csvRange]
                let delimitedRows = try CSV(string: String(csvStr)).namedRows
                let nuItems = try decodeDelimitedRows(delimitedRows: delimitedRows,
                                                      accountID: _accountID,
                                                      defTimeOfDay: defTimeOfDay,
                                                      defTimeZone: defTimeZone,
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
                                      defTimeZone: String? = nil,
                                      rejectedRows: inout [AllocRowed.RawRow]) throws -> [AllocRowed.DecodedRow] {
        
        delimitedRows.reduce(into: []) { decodedRows, delimitedRow in
            
            guard let symbol = MTransaction.parseString(delimitedRow["Symbol"]),
                  symbol.count > 0,
                  let shareCount = MTransaction.parseDouble(delimitedRow["Quantity"]),
                  let proceeds = MTransaction.parseDouble(delimitedRow["Proceeds"]),
                  let dateSold = delimitedRow["Closed Date"],
                  let transactedAt = parseChuckMMDDYYYY(dateSold, defTimeOfDay: defTimeOfDay, defTimeZone: defTimeZone)
            else {
                rejectedRows.append(delimitedRow)
                return
            }
            
            // calculated values
            let sharePrice = (shareCount != 0) ? (proceeds / shareCount) : nil
            
            // optional values
            let realizedShort = MTransaction.parseDouble(delimitedRow["Short Term Gain/Loss ($)"])
            let realizedLong = MTransaction.parseDouble(delimitedRow["Long Term Gain/Loss ($)"])
            
            let securityID = String(symbol)
            let shareCount_ = -1 * shareCount // negative because it's a sale (reduction in shares)
            
            let lotID = ""
            
            decodedRows.append([
                MTransaction.CodingKeys.action.rawValue: MTransaction.Action.buysell,
                MTransaction.CodingKeys.transactedAt.rawValue: transactedAt,
                MTransaction.CodingKeys.accountID.rawValue: accountID,
                MTransaction.CodingKeys.securityID.rawValue: securityID,
                MTransaction.CodingKeys.lotID.rawValue: lotID,
                MTransaction.CodingKeys.shareCount.rawValue: shareCount_,
                MTransaction.CodingKeys.sharePrice.rawValue: sharePrice,
                MTransaction.CodingKeys.realizedGainShort.rawValue: realizedShort,
                MTransaction.CodingKeys.realizedGainLong.rawValue: realizedLong,
            ])
        }
    }
    
    // parse "Realized Gain/Loss for XXXX-1234 for 08/29/2021 to 09/28/2021 as of Tue Sep 28  23:17:11 EDT 2021" to extract "XXXX-1234"
    internal static func parseAccountID(_ rawStr: String) -> String? {
        let pattern = #"Realized Gain/Loss for ([A-Z0-9-_]+) for.+"#
        guard let captured = rawStr.captureGroups(for: pattern, options: .caseInsensitive),
              captured.count == 1
        else { return nil }
        return captured[0]
    }
}
