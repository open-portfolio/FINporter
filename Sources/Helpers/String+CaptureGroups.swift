//
//  String+CaptureGroups.swift
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

public extension String {
    
    // adapted from https://stackoverflow.com/a/53652037
    func captureGroups(for pattern: String,
                       options: NSRegularExpression.Options = []) -> [String]? {
        let text = self
        let baseRange = NSRange(text.startIndex..., in: text)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options),
              let firstMatch = regex.matches(in: text, range: baseRange).first,
              case let rangeCount = firstMatch.numberOfRanges,
              rangeCount > 0
        else { return nil }
        return (1..<rangeCount).map {
            let bounds = firstMatch.range(at: $0)
            guard let range = Range(bounds, in: text) else { return "" }
            return String(text[range])
        }
    }
}
