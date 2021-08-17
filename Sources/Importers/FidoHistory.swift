//
//  FidoPurchases.swift
//
//  Input: for use with Accounts_History.csv from Fidelity Brokerage Services
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
    override var description: String { "Detect and decode accounts history export files from Fidelity, for sale and purchase info." }
    override var sourceFormats: [AllocFormat] { [.CSV] }
    override var outputSchemas: [AllocSchema] { [.allocHistory] }

    override func detect(dataPrefix: Data) throws -> DetectResult {
        let headerRE = #"""
        Brokerage

        Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,Price \(\$\),Commission \(\$\),Fees \(\$\),Accrued Interest \(\$\),Amount \(\$\),Settlement Date
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
        guard let str = String(data: data, encoding: .utf8) else {
            throw FINporterError.decodingError("unable to parse data")
        }

        var items = [T.Row]()

        // should match all lines, until a blank line or end of block/file
        let csvRE = #"Run Date,Account,Action,Symbol,Security Description,Security Type,Quantity,(?:.+(\r?\n|\Z))+"#

        if let csvRange = str.range(of: csvRE, options: .regularExpression) {
            let csvStr = String(str[csvRange])
            let csv = try CSV(string: csvStr)

            let trimFromTicker = CharacterSet(charactersIn: "*")

            var transactionNo = 1

            for row in csv.namedRows {
                // required values
                guard let accountNameNumber = T.parseString(row["Account"]),
                      let accountID = accountNameNumber.split(separator: " ").last,
                      accountID.count > 0,
                      let securityID = T.parseString(row["Symbol"], trimCharacters: trimFromTicker),
                      securityID.count > 0,
                      let shareCount = T.parseDouble(row["Quantity"]),
                      let sharePrice = T.parseDouble(row["Price ($)"]),
                      let transactedAt = T.parseMMDDYYYY(row["Run Date"], separator: "/")
                else {
                    rejectedRows.append(row)
                    continue
                }

                // optional values

                // unfortunately, no realized gain/loss info available in this export
                // see the fido_sales report for that

                items.append([
                    MHistory.CodingKeys.transactionID.rawValue: String(transactionNo),
                    MHistory.CodingKeys.accountID.rawValue: accountID,
                    MHistory.CodingKeys.securityID.rawValue: securityID,
                    MHistory.CodingKeys.shareCount.rawValue: shareCount,
                    MHistory.CodingKeys.sharePrice.rawValue: sharePrice,
                    MHistory.CodingKeys.realizedGainShort.rawValue: nil,
                    MHistory.CodingKeys.realizedGainLong.rawValue: nil,
                    MHistory.CodingKeys.transactedAt.rawValue: transactedAt
                ])

                transactionNo += 1
            }
        }

        return items
    }
}
