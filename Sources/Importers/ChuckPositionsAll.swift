//
//  ChuckPositionsAll.swift
//
//
//  Input: for use with All-Accounts-Positions-2021-09-26-000000.CSV from Schwab Brokerage Services
//
//  Output: supports openalloc/holding, /security, /account, and /meta schemas
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

class ChuckPositionsAll: FINporter {
    override var name: String { "Chuck Positions (All Accounts)" }
    override var id: String { "chuck_positions_all" }
    override var description: String { "Detect and decode 'all account' position export files from Schwab." }
    override var sourceFormats: [AllocFormat] { [.CSV] }
    override var outputSchemas: [AllocSchema] { [.allocMetaSource, .allocAccount, .allocHolding, .allocSecurity] }
    
    internal static let headerRE = #"""
    "Positions for All-Accounts as of .+"
    
    ".+"
    "Symbol","Description","Quantity","Price","Price Change \$","Price Change %","Market Value","Day Change \$","Day Change %","Cost Basis",.+
    """#
    
    internal static let accountBlockRE = #"""
    (?:".+")
    "Symbol","Description","Quantity","Price","Price Change \$","Price Change %","Market Value","Day Change \$","Day Change %","Cost Basis",.+
    (?:.+(\n|\Z))+
    """#
    //    "Account Total",.+
    
    internal static let csvRE = #"""
    "Symbol","Description",.+
    (?:.+(\n|\Z))+
    """#
    
    internal static let accountTitleRE = #""(.+?)\s+([A-Z0-9-_]+)""# // lazy greedy non-space

    override func detect(dataPrefix: Data) throws -> DetectResult {
        guard let str = FINporter.normalizeDecode(dataPrefix),
              str.range(of: ChuckPositionsAll.headerRE,
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
                                            defTimeOfDay _: String? = nil,
                                            timeZone _: TimeZone = TimeZone.current,
                                            timestamp: Date? = nil) throws -> [T.DecodedRow] {
        guard var str = FINporter.normalizeDecode(data) else {
            throw FINporterError.decodingError("unable to parse data")
        }
        
        guard let outputSchema_ = outputSchema else {
            throw FINporterError.needExplicitOutputSchema(outputSchemas)
        }
        
        var items = [T.DecodedRow]()
        
        if outputSchema_ == .allocMetaSource {
            let item = ChuckPositions.meta(self.id, str, url)
            items.append(item)
            return items
        }
        
        // one block per account expected
        while let range = str.range(of: ChuckPositionsAll.accountBlockRE,
                                    options: .regularExpression) {
            let block = str[range]
            
            // first line has the account ID & title
            let tuple: (id: String, title: String)? = {
                let _range = block.lineRange(for: ..<block.startIndex)
                let rawStr = block[_range].trimmingCharacters(in: .whitespacesAndNewlines)
                return ChuckPositions.parseAccountTitleID(ChuckPositionsAll.accountTitleRE, rawStr)
            }()
            
            if let (accountID, accountTitle) = tuple {
                
                if outputSchema_ == .allocAccount {
                    items.append([
                        MAccount.CodingKeys.accountID.rawValue: accountID,
                        MAccount.CodingKeys.title.rawValue: accountTitle
                    ])
                    
                } else if let csvRange = block.range(of: ChuckPositionsAll.csvRE,
                                                     options: .regularExpression) {
                    let csvStr = block[csvRange]
                    let delimitedRows = try CSV(string: String(csvStr)).namedRows
                    let nuItems = ChuckPositions.decodeDelimitedRows(delimitedRows: delimitedRows,
                                                                     outputSchema_: outputSchema_,
                                                                     accountID: accountID,
                                                                     rejectedRows: &rejectedRows,
                                                                     timestamp: timestamp)
                    items.append(contentsOf: nuItems)
                }
            }
            
            str.removeSubrange(range) // discard blocks as they are consumed
        }
        
        return items
    }
}
