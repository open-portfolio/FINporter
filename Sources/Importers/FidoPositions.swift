//
//  FidoPositions.swift
//
//
//  Input: for use with Portfolio_Positions_Mmm-DD-YYYY.csv from Fidelity Brokerage Services
//
//  Output: supports openalloc/holding and openalloc/security schemas
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

class FidoPositions: FINporter {
    override var name: String { "Fido Positions" }
    override var id: String { "fido_positions" }
    override var description: String { "Detect and decode position export files from Fidelity." }
    override var sourceFormats: [AllocFormat] { [.CSV] }
    override var outputSchemas: [AllocSchema] { [.allocAccount, .allocHolding, .allocSecurity] }

    private let trimFromTicker = CharacterSet(charactersIn: "*")

    override func detect(dataPrefix: Data) throws -> DetectResult {
        let headerRE = #"""
        Account Number,Account Name,Symbol,Description,Quantity,Last Price,Last Price Change,Current Value,Today's Gain/Loss Dollar,Today's Gain/Loss Percent,Total Gain/Loss Dollar,Total Gain/Loss Percent,Percent Of Account,Cost Basis,Cost Basis Per Share,Type
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
                                            outputSchema: AllocSchema? = nil,
                                            url _: URL? = nil,
                                            timestamp: Date = Date()) throws -> [T.Row] {
        guard let str = String(data: data, encoding: .utf8) else {
            throw FINporterError.decodingError("unable to parse data")
        }

        guard let outputSchema_ = outputSchema else {
            throw FINporterError.needExplicitOutputSchema(outputSchemas)
        }

        var items = [T.Row]()

        // should match all lines, until a blank line or end of block/file
        let csvRE = #"Account Number,Account Name,Symbol,Description,Quantity,(?:.+(\r?\n|\Z))+"#

        if let csvRange = str.range(of: csvRE, options: .regularExpression) {
            let csvStr = str[csvRange]
            let csv = try CSV(string: String(csvStr))
            for row in csv.namedRows {
                var item: T.Row?

                switch outputSchema_ {
                case .allocAccount:
                    item = account(row, rejectedRows: &rejectedRows)
                case .allocHolding:
                    item = holding(row, rejectedRows: &rejectedRows)
                case .allocSecurity:
                    item = security(row, rejectedRows: &rejectedRows, timestamp: timestamp)
                default:
                    throw FINporterError.targetSchemaNotSupported(outputSchemas)
                }

                if let item_ = item {
                    items.append(item_)
                }
            }
        }

        return items
    }

    private func holding(_ row: [String: String], rejectedRows: inout [AllocBase.Row]) -> AllocBase.Row? {
        // required values
        guard let accountID = MHolding.parseString(row["Account Number"]),
              accountID.count > 0,
              let securityID = MHolding.parseString(row["Symbol"], trimCharacters: trimFromTicker),
              securityID.count > 0,
              securityID != "Pending Activity",
              let shareCount = MHolding.parseDouble(row["Quantity"])
        else {
            rejectedRows.append(row)
            return nil
        }

        // optional values
        let shareBasis = MHolding.parseDouble(row["Cost Basis Per Share"])

        // because it appears that lots are averaged, assume only one per securityID
        let lotID = AllocNilKey

        return [
            MHolding.CodingKeys.accountID.rawValue: accountID,
            MHolding.CodingKeys.securityID.rawValue: securityID,
            MHolding.CodingKeys.lotID.rawValue: lotID,
            MHolding.CodingKeys.shareCount.rawValue: shareCount,
            MHolding.CodingKeys.shareBasis.rawValue: shareBasis
        ]
    }

    private func security(_ row: [String: String], rejectedRows: inout [AllocBase.Row], timestamp: Date = Date()) -> AllocBase.Row? {
        guard let securityID = MHolding.parseString(row["Symbol"], trimCharacters: trimFromTicker),
              securityID.count > 0,
              securityID != "Pending Activity",
              let sharePrice = MHolding.parseDouble(row["Last Price"])
        else {
            rejectedRows.append(row)
            return nil
        }

        return [
            MSecurity.CodingKeys.securityID.rawValue: securityID,
            MSecurity.CodingKeys.sharePrice.rawValue: sharePrice,
            MSecurity.CodingKeys.updatedAt.rawValue: timestamp
        ]
    }
    
    private func account(_ row: [String: String], rejectedRows: inout [AllocBase.Row]) -> AllocBase.Row? {
        guard let accountID = MHolding.parseString(row["Account Number"]),
              accountID.count > 0,
              let title = MHolding.parseString(row["Account Name"])
        else {
            rejectedRows.append(row)
            return nil
        }

        return [
            MAccount.CodingKeys.accountID.rawValue: accountID,
            MAccount.CodingKeys.title.rawValue: title
        ]
    }
}
