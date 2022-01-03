//
//  ChuckPositionsIndiv.swift
//
//
//  Input: for use with Individual-Positions-2021-09-26-000000.CSV from Schwab Brokerage Services
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

class ChuckPositionsIndiv: FINporter {
    override var name: String { "Chuck Positions (Individual)" }
    override var id: String { "chuck_positions_indiv" }
    override var description: String { "Detect and decode 'individual' position export files from Schwab." }
    override var sourceFormats: [AllocFormat] { [.CSV] }
    override var outputSchemas: [AllocSchema] { [.allocMetaSource, .allocAccount, .allocHolding, .allocSecurity] }
    
    private let trimFromTicker = CharacterSet(charactersIn: "*")
    
    internal static let headerRE = #"""
    "Positions for account .+? as of .+"
    
    "Symbol","Description","Quantity","Price","Price Change \$","Price Change %","Market Value","Day Change \$","Day Change %","Cost Basis",.+
    """#
    
    internal static let csvRE = #"""
    "Symbol","Description",.+
    (?:.+(\n|\Z))+
    """#
    
    internal static let accountTitleRE = #""Positions for account (.+?)\s+([A-Z0-9-_]+) as of .+""# // lazy greedy non-space
    
    override func detect(dataPrefix: Data) throws -> DetectResult {
        guard let str = FINporter.normalizeDecode(dataPrefix),
              str.range(of: ChuckPositionsIndiv.headerRE,
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
        guard let str = FINporter.normalizeDecode(data) else {
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
        
        try ChuckPositions.parseBlock(str: str,
                                      outputSchema: outputSchema_,
                                      items: &items,
                                      rejectedRows: &rejectedRows,
                                      timestamp: timestamp,
                                      accountTitleRE: ChuckPositionsIndiv.accountTitleRE,
                                      csvRE: ChuckPositionsIndiv.csvRE)
        
        return items
    }
    
    
    
    
}
