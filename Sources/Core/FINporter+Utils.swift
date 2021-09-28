//
//  FINporter+Utils.swift
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

extension FINporter {
    
    /// Data decoder with line separator normalization.
    ///
    /// Normalizing line separators in input text can simplify the regular expression patterns needed to match.
    public static func decode(data: Data,
                              encoding: String.Encoding = .utf8,
                              fromLineSeparator: String = "\r\n",
                              toLineSeparator: String = "\n") -> String? {
        guard let str = String(data: data, encoding: encoding) else { return nil }
        return str.replacingOccurrences(of: fromLineSeparator, with: toLineSeparator)
    }
}
