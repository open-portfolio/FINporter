//
//  MAsset+StandardID.swift
//
// Copyright 2021, 2022 OpenAlloc LLC
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

import AllocData

public extension MAsset {
    enum StandardID: String, CaseIterable {
        case bond = "Bond"
        case cash = "Cash"
        case cmdty = "Cmdty"
        case corpbond = "CorpBond"
        case em = "EM"
        case embond = "EMBond"
        case europe = "Europe"
        case globre = "GlobRE"
        case gold = "Gold"
        case hybond = "HYBond"
        case intl = "Intl"
        case intlbond = "IntlBond"
        case intlgov = "IntlGov"
        case intlre = "IntlRE"
        case intlsc = "IntlSC"
        case intlval = "IntlVal"
        case itgov = "ITGov"
        case japan = "Japan"
        case lc = "LC"
        case lcgrow = "LCGrow"
        case lcval = "LCVal"
        case ltgov = "LTGov"
        case mc = "MC"
        case mcgrow = "MCGrow"
        case mcval = "MCVal"
        case momentum = "Momentum"
        case pacific = "Pacific"
        case re = "RE"
        case remort = "REMort"
        case sc = "SC"
        case scgrow = "SCGrow"
        case scval = "SCVal"
        case stgov = "STGov"
        case tech = "Tech"
        case tips = "TIPS"
        case total = "Total"

        // TODO: not used yet. Need to be handled with locale
//        public var description: String {
//            switch self {
//            case .bond:
//                return "US Aggregate Bonds"
//            case .cash:
//                return "Cash"
//            case .cmdty:
//                return "Commodities"
//            case .corpbond:
//                return "US Corporate Bonds"
//            case .em:
//                return "Emerging Market Equities"
//            case .embond:
//                return "Emerging Market Bonds"
//            case .europe:
//                return "Europe Equities"
//            case .globre:
//                return "Global Real Estate"
//            case .gold:
//                return "Gold"
//            case .hybond:
//                return "High Yield Bonds"
//            case .intl:
//                return "International Equities"
//            case .intlbond:
//                return "International Bonds"
//            case .intlgov:
//                return "International Treasuries"
//            case .intlre:
//                return "International Real Estate"
//            case .intlsc:
//                return "International Small Cap Equities"
//            case .intlval:
//                return "International Value Equities"
//            case .itgov:
//                return "Intermediate Term US Treasuries"
//            case .japan:
//                return "Japan Equities"
//            case .lc:
//                return "US Large Cap Equities"
//            case .lcgrow:
//                return "US Large Cap Growth Equities"
//            case .lcval:
//                return "US Large Cap Value Equities"
//            case .ltgov:
//                return "Long-Term US Treasuries"
//            case .momentum:
//                return "US Momentum Equities"
//            case .pacific:
//                return "Pacific Equities"
//            case .re:
//                return "US Real Estate"
//            case .remort:
//                return "US Mortgage REITs"
//            case .sc:
//                return "US Small Cap Equities"
//            case .scgrow:
//                return "US Small Cap Growth Equities"
//            case .scval:
//                return "US Small Cap Value Equities"
//            case .stgov:
//                return "Short-Term US Treasuries"
//            case .tech:
//                return "US Technology Equities"
//            case .tips:
//                return "US Inflation Protected Treasuries"
//            case .total:
//                return "US Total Market"
//            }
//        }
    }
}
