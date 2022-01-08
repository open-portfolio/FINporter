//
//  ChuckPositions.swift
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

struct ChuckPositions {
    private static let trimFromTicker = CharacterSet(charactersIn: "*")
    
    static func meta(_ id: String, _ str: String, _ url: URL?) -> AllocRowed.DecodedRow {
        var decodedRow: AllocRowed.DecodedRow = [
            MSourceMeta.CodingKeys.sourceMetaID.rawValue: UUID().uuidString,
            MSourceMeta.CodingKeys.importerID.rawValue: id,
        ]
        
        if let _url = url {
            decodedRow[MSourceMeta.CodingKeys.url.rawValue] = _url
        }
        
        // extract exportedAt from "Positions for All-Accounts as of 09:59 PM ET, 09/26/2021" (with quotes)
        let ddRE = #"(?<= as of ).+(?=\")"#
        if let dd = str.range(of: ddRE, options: .regularExpression),
           let exportedAt = chuckDateFormatter.date(from: String(str[dd])) {
            decodedRow[MSourceMeta.CodingKeys.exportedAt.rawValue] = exportedAt
        }
        
        return decodedRow
    }
    
    static func holding(_ accountID: String, _ row: AllocRowed.RawRow, rejectedRows: inout [AllocRowed.RawRow]) -> AllocRowed.DecodedRow? {
        // NOTE: 'Symbol' may be "Cash & Cash Investments" or "Account Total"
        guard let rawSymbol = getRawSymbol(row) else { return nil }
        
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
    
    static func security(_ row: AllocRowed.RawRow, rejectedRows: inout [AllocRowed.RawRow], timestamp: Date?) -> AllocRowed.DecodedRow? {
        
        guard let rawSymbol = getRawSymbol(row),
              rawSymbol != "Cash & Cash Investments"    // ignore cash
        else { return nil }
        
        guard let sharePrice = MHolding.parseDouble(row["Price"])
        else {
            rejectedRows.append(row)
            return nil
        }
        
        var decodedRow: AllocRowed.DecodedRow = [
            MSecurity.CodingKeys.securityID.rawValue: rawSymbol,
            MSecurity.CodingKeys.sharePrice.rawValue: sharePrice,
        ]
        
        if let updatedAt = timestamp {
            decodedRow[MSecurity.CodingKeys.updatedAt.rawValue] = updatedAt
        }
        
        return decodedRow
    }
    
    /// obtain the ticker, ignoring (but not rejecting) row if blank/missing (or if "Account Total")
    internal static func getRawSymbol(_ row: AllocRowed.RawRow) -> String? {
        guard let rawSymbol = MHolding.parseString(row["Symbol"], trimCharacters: trimFromTicker),
              rawSymbol.count > 0,
              rawSymbol != "Account Total"
        else { return nil }
        
        return rawSymbol
    }
    
    static func parseBlock(block: String,
                           outputSchema: AllocSchema,
                           rejectedRows: inout [AllocRowed.RawRow],
                           timestamp: Date?,
                           accountTitleRE: String,
                           csvRE: String) throws -> [AllocRowed.DecodedRow] {
        
        // first line has the account ID & title
        let tuple: (id: String, title: String)? = {
            let _range = block.lineRange(for: ..<block.startIndex)
            let rawStr = block[_range].trimmingCharacters(in: .whitespacesAndNewlines)
            return parseAccountTitleID(accountTitleRE, rawStr)
        }()
        
        if let (accountID, accountTitle) = tuple {
            
            if outputSchema == .allocAccount {
                return [[
                    MAccount.CodingKeys.accountID.rawValue: accountID,
                    MAccount.CodingKeys.title.rawValue: accountTitle
                ]]
                
            } else if let csvRange = block.range(of: csvRE,
                                                 options: .regularExpression) {
                let csvStr = block[csvRange]
                let delimitedRows = try CSV(string: String(csvStr)).namedRows
                return decodeDelimitedRows(delimitedRows: delimitedRows,
                                           outputSchema: outputSchema,
                                           accountID: accountID,
                                           rejectedRows: &rejectedRows,
                                           timestamp: timestamp)
            }
        }
        
        return []
    }
    
    // parse ""Individual Something                       XXXX-1234"" to ["Individual Something", "XXXX-1234"]
    internal static func parseAccountTitleID(_ pattern: String, _ rawStr: String) -> (id: String, title: String)? {
        guard let captured = rawStr.captureGroups(for: pattern, options: .caseInsensitive),
              captured.count == 2
        else { return nil }
        return (captured[1], captured[0])
    }
    
    internal static func decodeDelimitedRows(delimitedRows: [AllocRowed.RawRow],
                                             outputSchema: AllocSchema,
                                             accountID: String,
                                             rejectedRows: inout [AllocRowed.RawRow],
                                             timestamp: Date?) -> [AllocRowed.DecodedRow] {
        delimitedRows.reduce(into: []) { decodedRows, delimitedRow in
            switch outputSchema {
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
}
