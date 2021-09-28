//
//  FidoSales.swift
//
//  Input: For use with Realized_Gain_Loss_Account_XXXXXXXX.csv from 'Closed Positions' of taxable accounts
//          from Fidelity Brokerage Services
//
//  Note that accountID is extracted from file URL.
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

class FidoSales: FINporter {
    override var name: String { "Fido Sales" }
    override var id: String { "fido_sales" }
    override var description: String { "Detect and decode realized sale export files from Fidelity." }
    override var sourceFormats: [AllocFormat] { [.CSV] }
    override var outputSchemas: [AllocSchema] { [.allocTransaction] }

    internal static let headerRE = #"Symbol\(CUSIP\),Security Description,Quantity,Date Acquired,Date Sold,Proceeds,Cost Basis,Short Term Gain/Loss,Long Term Gain/Loss"#

    internal static let csvRE = #"[A-Za-z0-9]+(?=\.)"#

    override func detect(dataPrefix: Data) throws -> DetectResult {
        guard let str = FINporter.normalizeDecode(dataPrefix),
              str.range(of: FidoSales.headerRE,
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
                                            url: URL? = nil,
                                            defTimeOfDay: String? = nil,
                                            defTimeZone: String? = nil,
                                            timestamp _: Date? = nil) throws -> [T.Row] {
        guard let str = FINporter.normalizeDecode(data) else {
            throw FINporterError.decodingError("unable to parse data")
        }

        // Extract X12345678 from "...Realized_Gain_Loss_Account_X12345678.csv"
        let accountID: String? = {
            if let urlStr = url?.absoluteString,
               let accountIDRange = urlStr.range(of: FidoSales.csvRE, options: .regularExpression) {
                return String(urlStr[accountIDRange])
            }
            return nil
        }()

        var items = [T.Row]()

        let csv = try CSV(string: str)

        for row in csv.namedRows {
            // required values
            guard let symbolCusip = T.parseString(row["Symbol(CUSIP)"]),
                  let symbol = symbolCusip.split(separator: "(").first,
                  symbol.count > 0,
                  let shareCount = T.parseDouble(row["Quantity"]),
                  let proceeds = T.parseDouble(row["Proceeds"]),
                  let dateSold = row["Date Sold"],
                  let transactedAt = parseFidoMMDDYYYY(dateSold, defTimeOfDay: defTimeOfDay, defTimeZone: defTimeZone)
            else {
                rejectedRows.append(row)
                continue
            }

            // calculated values
            let sharePrice = (shareCount != 0) ? (proceeds / shareCount) : nil

            // optional values
            let realizedShort = T.parseDouble(row["Short Term Gain/Loss"])
            let realizedLong = T.parseDouble(row["Long Term Gain/Loss"])

            let securityID = String(symbol)
            let shareCount_ = -1 * shareCount // negative because it's a sale (reduction in shares)

            let lotID = ""
            
            items.append([
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

        return items
    }
}
