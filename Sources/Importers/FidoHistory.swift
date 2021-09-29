//
//  FidoPurchases.swift
//
//  Input: for use with Accounts_History.csv from Fidelity Brokerage Services
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

class FidoHistory: FINporter {
    override var name: String { "Fido History" }
    override var id: String { "fido_history" }
    override var description: String { "Detect and decode account history export files from Fidelity, for sale and purchase info." }
    override var sourceFormats: [AllocFormat] { [.CSV] }
    override var outputSchemas: [AllocSchema] { [.allocTransaction] }

    internal static let headerRE = #"""
    Brokerage

    Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,Price \(\$\),Commission \(\$\),Fees \(\$\),Accrued Interest \(\$\),Amount \(\$\),Settlement Date
    """#
    
    // should match all lines, until a blank line or end of block/file
    internal static let csvRE = #"Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,(?:.+(\n|\Z))+"#

    override func detect(dataPrefix: Data) throws -> DetectResult {
        guard let str = FINporter.normalizeDecode(dataPrefix),
              str.range(of: FidoHistory.headerRE,
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
                                            defTimeOfDay: String? = nil,
                                            defTimeZone: String? = nil,
                                            timestamp _: Date? = nil) throws -> [T.Row] {
        guard let str = FINporter.normalizeDecode(data) else {
            throw FINporterError.decodingError("unable to parse data")
        }

        var items = [T.Row]()

        if let csvRange = str.range(of: FidoHistory.csvRE, options: .regularExpression) {
            let csvStr = String(str[csvRange])
            let csv = try CSV(string: csvStr)

            let trimFromTicker = CharacterSet(charactersIn: "*")

            for row in csv.namedRows {
                // required values
                guard let accountNameNumber = T.parseString(row["Account"]),
                      let accountID = accountNameNumber.split(separator: " ").last,
                      accountID.count > 0,
                      let securityID = T.parseString(row["Symbol"], trimCharacters: trimFromTicker),
                      securityID.count > 0,
                      let shareCount = T.parseDouble(row["Quantity"]),
                      let sharePrice = T.parseDouble(row["Price ($)"]),
                      let runDate = row["Run Date"],
                      let transactedAt = parseFidoMMDDYYYY(runDate, defTimeOfDay: defTimeOfDay, defTimeZone: defTimeZone)
                else {
                    rejectedRows.append(row)
                    continue
                }

                // optional values

                // unfortunately, no realized gain/loss info available in this export
                // see the fido_sales report for that

                let lotID = ""

                items.append([
                    MTransaction.CodingKeys.transactedAt.rawValue: transactedAt,
                    MTransaction.CodingKeys.accountID.rawValue: accountID,
                    MTransaction.CodingKeys.securityID.rawValue: securityID,
                    MTransaction.CodingKeys.lotID.rawValue: lotID,
                    MTransaction.CodingKeys.shareCount.rawValue: shareCount,
                    MTransaction.CodingKeys.sharePrice.rawValue: sharePrice,
                    //MTransaction.CodingKeys.realizedGainShort.rawValue: nil,
                    //MTransaction.CodingKeys.realizedGainLong.rawValue: nil,
                ])
            }
        }

        return items
    }
}
