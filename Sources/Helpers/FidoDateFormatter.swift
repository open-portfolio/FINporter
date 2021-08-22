//
//  FidoDateFormatter.swift
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

let fidoDateFormatter: DateFormatter = {
    let df = DateFormatter()
    // h: Hour [1-12]
    // mm: minute (2 for zero padding)
    // a: AM or PM
    // v: Use one letter for short wall (generic) time (e.g., PT)
    df.dateFormat = "MM/dd/yyyy h:mm a v"
    return df
}()

/// assume noon ET for any Fido date
func parseFidoMMDDYYYY(_ mmddyyyy: String?) -> Date? {
    guard let _mmddyyyy = mmddyyyy else { return nil }
    let dateStr = "\(_mmddyyyy) 12:00 PM ET"
    return fidoDateFormatter.date(from: dateStr)
}
    
