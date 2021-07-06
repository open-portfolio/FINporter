//
//  DetectHandler.swift
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

public func handleDetect(inputFilePath: String) throws -> [String] {
    let fileURL = URL(fileURLWithPath: inputFilePath)
    let data = try Data(contentsOf: fileURL)
    let prospector = FINprospector()
    let sourceFormats: [AllocFormat] = [.CSV]
    let prospectResult = try prospector.prospect(sourceFormats: sourceFormats, dataPrefix: data)
    return prospectResult.reduce(into: []) { array, entry in
        let (_, detectResult) = entry
        let detectedPairs: [(String, String)] = detectResult.map { ($0.key.rawValue, $0.value.map { $0.rawValue }.joined(separator: ",")) }
        array.append(contentsOf: detectedPairs.map { "\($0.0): \($0.1)" })
    }
}
