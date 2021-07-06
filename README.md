# FINporter

An open source data transformation tool for financial data.

Supports investing apps like [FlowAllocator](https://flowallocator.app), a rebalancing tool for macOS.

Available both as a command line executable and as a Swift library to be incorporated in other apps.

## Disclaimer

The developers of this project (presently FlowAllocator LLC) are not financial advisers and do not offer tax or investing advice. 

Where explicit support is provided for the transformation of data format associated with a service (brokerage, etc.), it is not a recommendation or endorsement of that service.

Software will have defects. Input data can have errors or become outdated. Carefully examine the output from _FINporter_ for accuracy to ensure it is consistent with your investment goals.

For additional disclaiming, read the LICENSE, which is Apache 2.0.

## Command Line

_FINporter_ includes a powerful command-line tool to detect and transform financial data, such as exports from your brokerage account.

```bash
$ swift build
$ .build/debug/finporter

OVERVIEW: A utility for transforming financial data.

USAGE: finporter <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  list                    List things available.
  schema                  Describe schema details.
  detect                  Detect schema of file.
  transform               Transform data in file.

  See 'finporter help <subcommand>' for detailed help.
```

If your favorite product (e.g., _FlowAllocator_) hasn't yet incorporated the latest FINporter library supporting your brokerage or service, you can still convert files using the command line.

```bash
$ swift build
$ .build/debug/finporter transform ~/Downloads/Accounts_History.csv

... CSV conforming to the 'openalloc/history' schema here, which can be imported into app

```

## License

Copyright 2021 FlowAllocator LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Contributing

You can fork this project to further its development. Submit pull requests for inclusion. Your contribution must be under the same license.

Please ensure your contribution has adequate test coverage and command-line support. See tests for current importers to see what coverage is expected.

Contributions are at will. Project owner(s) may reject for any reason. Accepted contributions may be later withdrawn, such as due to legal threats.







