//
//  ChuckDateFormatter.swift
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

let chuckDateFormatter: DateFormatter = {
    let df = DateFormatter()
    // hh: Hour [01-12] (2 for zero padding)
    // mm: minute (2 for zero padding)
    // a: AM or PM
    // v: Use one letter for short wall (generic) time (e.g., PT)
    df.dateFormat = "h:mm a v, MM/dd/yyyy"
    return df
}()

/// Parse a 'naked' MM/dd/yyyy date into a fully resolved date.
/// Assume noon of current time zone for any Chuck date.
/// If "08/16/2021 as of 08/15/2021" just parse the first date and ignore the second.
func parseChuckMMDDYYYY(_ rawDateStr: String?,
                       defTimeOfDay: String? = nil,
                       timeZoneID: String? = nil) -> Date? {
    let pattern = #"^(\d\d/\d\d/\d\d\d\d)( as of.+)?"#
    
    let timeOfDay: String = defTimeOfDay ?? "12:00"
    guard let _rawDateStr = rawDateStr,
          let captureGroups = _rawDateStr.captureGroups(for: pattern),
          let foundDateStr = captureGroups.first,
          timeOfDay.count == 5
    else { return nil }
    
    let df = DateFormatter()
    df.dateFormat = "MM/dd/yyyy HH:mm"
    df.timeZone = TimeZone(identifier: timeZoneID ?? "") ?? TimeZone.current
    
    let dateStr = "\(foundDateStr) \(timeOfDay)"
    let result = df.date(from: dateStr)
    return result
}
