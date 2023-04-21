# FINporter

<img align="right" src="https://github.com/openalloc/FINporter/blob/main/Images/logo.png" width="100" height="100"/>A framework for detecting and transforming investing data.

_FINporter_ is part of the [OpenAlloc](https://github.com/openalloc) family of open source Swift software tools.

Used by investing apps like [FlowAllocator](https://openalloc.github.io/FlowAllocator/index.html) and [FlowWorth](https://openalloc.github.io/FlowWorth/index.html).

## Disclaimer

The developers of this project (presently OpenAlloc LLC) are not financial advisers and do not offer tax or investing advice. 

Where explicit support is provided for the transformation of data format associated with a service (brokerage, etc.), it is not a recommendation or endorsement of that service.

Software will have defects. Input data can have errors or become outdated. Carefully examine the output from _FINporter_ for accuracy to ensure it is consistent with your investment goals.

For additional disclaiming, read the LICENSE, which is Apache 2.0.

## Supported Schema

At present _FINporter_ supports the schemas of the _OpenAlloc_ project, documented at [openalloc/AllocData](https://github.com/openalloc/AllocData). Applications which support those schemas can make use of _FINporter_'s importers to ingest the specialized formats it supports.

## Supported Data Formats

NOTE: support of a data format for a service is not an endorsement or recommendation of that service.

Applications which have integrated _FINporter_ will typically support imports through a menu item or drag-and-drop. The examples below show how the command-line tool, `finport`, may be used to transform input files to delimited files of standardized schema.

## See Also

This library is a member of the _OpenAlloc Project_.

* [_OpenAlloc_](https://openalloc.github.io) - product website for all the _OpenAlloc_ apps and libraries
* [_OpenAlloc Project_](https://github.com/openalloc) - Github site for the development project, including full source code

## License

Copyright 2021, 2022 OpenAlloc LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Contributing

Contributions are welcome. You are encouraged to submit pull requests to fix bugs, improve documentation, or offer new features. 

The pull request need not be a production-ready feature or fix. It can be a draft of proposed changes, or simply a test to show that expected behavior is buggy. Discussion on the pull request can proceed from there.

Contributions should ultimately have adequate test coverage and command-line support. See tests for current importers to see what coverage is expected.






