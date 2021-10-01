//
//  ChuckPositions.swift
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

class ChuckPositions: FINporter {
    override var name: String { "Chuck Positions" }
    override var id: String { "chuck_positions" }
    override var description: String { "Detect and decode position export files from Schwab." }
    override var sourceFormats: [AllocFormat] { [.CSV] }
    override var outputSchemas: [AllocSchema] { [.allocMetaSource, .allocAccount, .allocHolding, .allocSecurity] }
    
    private let trimFromTicker = CharacterSet(charactersIn: "*")
    
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
    
    override func detect(dataPrefix: Data) throws -> DetectResult {
        guard let str = FINporter.normalizeDecode(dataPrefix),
              str.range(of: ChuckPositions.headerRE,
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
                                            defTimeZone _: String? = nil,
                                            timestamp: Date? = nil) throws -> [T.DecodedRow] {
        guard var str = FINporter.normalizeDecode(data) else {
            throw FINporterError.decodingError("unable to parse data")
        }
        
        guard let outputSchema_ = outputSchema else {
            throw FINporterError.needExplicitOutputSchema(outputSchemas)
        }
        
        var items = [T.DecodedRow]()
        
        if outputSchema_ == .allocMetaSource {
            let item = meta(str, url)
            items.append(item)
            return items
        }
        
        // one block per account expected
        while let range = str.range(of: ChuckPositions.accountBlockRE,
                                    options: .regularExpression) {
            let block = str[range]
            
            // first line has the account ID & title
            let tuple: (id: String, title: String)? = {
                let _range = block.lineRange(for: ..<block.startIndex)
                let rawStr = block[_range].trimmingCharacters(in: .whitespacesAndNewlines)
                return ChuckPositions.parseAccountTitleID(rawStr)
            }()
            
            if let (accountID, accountTitle) = tuple {
                
                if outputSchema_ == .allocAccount {
                    items.append([
                        MAccount.CodingKeys.accountID.rawValue: accountID,
                        MAccount.CodingKeys.title.rawValue: accountTitle
                    ])
                    
                } else if let csvRange = block.range(of: ChuckPositions.csvRE,
                                                     options: .regularExpression) {
                    let csvStr = block[csvRange]
                    let delimitedRows = try CSV(string: String(csvStr)).namedRows
                    let nuItems = decodeDelimitedRows(delimitedRows: delimitedRows,
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
    
    internal func decodeDelimitedRows(delimitedRows: [AllocRowed.RawRow],
                                      outputSchema_: AllocSchema,
                                      accountID: String,
                                      rejectedRows: inout [AllocRowed.RawRow],
                                      timestamp: Date?) -> [AllocRowed.DecodedRow] {
        delimitedRows.reduce(into: []) { decodedRows, delimitedRow in
            switch outputSchema_ {
            case .allocHolding:
                guard let item = holding(accountID, delimitedRow, rejectedRows: &rejectedRows) else { return }
                decodedRows.append(item)
            case .allocSecurity:
                guard let item = security(delimitedRow, rejectedRows: &rejectedRows, timestamp: timestamp) else { return }
                decodedRows.append(item)
            default:
                //throw FINporterError.targetSchemaNotSupported(outputSchemas)
                rejectedRows.append(delimitedRow)
                return
            }
        }
    }
    
    internal func meta(_ str: String, _ url: URL?) -> AllocRowed.DecodedRow {        
        var decodedRow: AllocRowed.DecodedRow = [
            MSourceMeta.CodingKeys.sourceMetaID.rawValue: UUID().uuidString,
            MSourceMeta.CodingKeys.importerID.rawValue: self.id,
        ]
        
        if let _url = url {
            decodedRow[MSourceMeta.CodingKeys.url.rawValue] = _url
        }
        
        // extract exportedAt from "Positions for All-Accounts as of 09:59 PM ET, 09/26/2021" (with quotes)
        let ddRE = #"(?<=\"Positions for All-Accounts as of ).+(?=\")"#
        if let dd = str.range(of: ddRE, options: .regularExpression),
           let exportedAt = chuckDateFormatter.date(from: String(str[dd])) {
            decodedRow[MSourceMeta.CodingKeys.exportedAt.rawValue] = exportedAt
        }
        
        return decodedRow
    }
    
    internal func holding(_ accountID: String, _ row: AllocRowed.RawRow, rejectedRows: inout [AllocRowed.RawRow]) -> AllocRowed.DecodedRow? {
        // NOTE: 'Symbol' may be "Cash & Cash Investments" or "Account Total"
        guard let rawSymbol = MHolding.parseString(row["Symbol"], trimCharacters: trimFromTicker),
              rawSymbol.count > 0,
              rawSymbol != "Account Total"
        else {
            rejectedRows.append(row)
            return nil
        }
        
        var netSymbol: String? = nil
        var shareBasis: Double? = nil
        var netShareCount: Double? = nil
        
        if rawSymbol == "Cash & Cash Investments" {
            netSymbol = "CORE"
            shareBasis = 1.0
            netShareCount = MHolding.parseDouble(row["Market Value"])
        } else if let shareCount = MHolding.parseDouble(row["Quantity"]),
                  let rawCostBasis = MHolding.parseDouble(row["Cost Basis"]),
                  shareCount != 0 {
            netSymbol = rawSymbol
            shareBasis = rawCostBasis / shareCount
            netShareCount = shareCount
        }

        var decodedRow: AllocRowed.DecodedRow = [
            MHolding.CodingKeys.accountID.rawValue: accountID,
        ]

        if let _netSymbol = netSymbol {
            decodedRow[MHolding.CodingKeys.securityID.rawValue] = _netSymbol
        }
        if let _netShareCount = netShareCount {
            decodedRow[MHolding.CodingKeys.shareCount.rawValue] = _netShareCount
        }
        if let _shareBasis = shareBasis {
            decodedRow[MHolding.CodingKeys.shareBasis.rawValue] = _shareBasis
        }
        
        return decodedRow
    }
    
    internal func security(_ row: AllocRowed.RawRow, rejectedRows: inout [AllocRowed.RawRow], timestamp: Date?) -> AllocRowed.DecodedRow? {
        guard let securityID = MHolding.parseString(row["Symbol"], trimCharacters: trimFromTicker),
              securityID.count > 0,
              let sharePrice = MHolding.parseDouble(row["Price"])
        else {
            rejectedRows.append(row)
            return nil
        }
        
        var decodedRow: AllocRowed.DecodedRow = [
            MSecurity.CodingKeys.securityID.rawValue: securityID,
            MSecurity.CodingKeys.sharePrice.rawValue: sharePrice,
        ]
        
        if let updatedAt = timestamp {
            decodedRow[MSecurity.CodingKeys.updatedAt.rawValue] = updatedAt
        }
        
        return decodedRow
    }
    
    // parse ""Individual Something                       XXXX-1234"" to ["Individual Something", "XXXX-1234"]
    internal static func parseAccountTitleID(_ rawStr: String) -> (id: String, title: String)? {
        let pattern = #""(.+?)\s+([A-Z0-9-_]+)""# // lazy greedy non-space
        guard let captured = rawStr.captureGroups(for: pattern, options: .caseInsensitive),
              captured.count == 2
        else { return nil }
        return (captured[1], captured[0])
    }
}
