// swift-tools-version:5.4

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

import PackageDescription

let package = Package(
    name: "FINporter",
    platforms: [.macOS(.v10_12)],
    products: [
        .library(name: "FINporter", targets: ["FINporter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/openalloc/AllocData.git", from: "1.1.0"),
        .package(url: "https://github.com/SwiftCSV/SwiftCSV.git", from: "0.6.1"),
    ],
    targets: [
        .target(
            name: "FINporter",
            dependencies: [
                "AllocData",
                "SwiftCSV",
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "FINporterTests",
            dependencies: [
                "FINporter",
            ],
            path: "Tests"
        ),
    ]
)
