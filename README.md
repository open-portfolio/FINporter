# FINporter

A utility for transforming financial data.

Supports investing apps like [FlowAllocator](https://flowallocator.app), a new rebalancing tool for macOS.

Available both as a `finport` command line executable and as a Swift library to be incorporated in other apps.

## Disclaimer

The developers of this project (presently FlowAllocator LLC) are not financial advisers and do not offer tax or investing advice. 

Where explicit support is provided for the transformation of data format associated with a service (brokerage, etc.), it is not a recommendation or endorsement of that service.

Software will have defects. Input data can have errors or become outdated. Carefully examine the output from _FINporter_ for accuracy to ensure it is consistent with your investment goals.

For additional disclaiming, read the LICENSE, which is Apache 2.0.

## Supported Schema

At present _FINporter_ supports the schemas of the _OpenAlloc_ project, documented at [openalloc/AllocData](https://github.com/openalloc/AllocData). Applications which support those schemas can make use of _FINporter_'s importers to ingest the specialized formats it supports.

## Supported Data Formats

NOTE: support of a data format for a service is not an endorsement or recommendation of that service.

Applications which have integrated _FINporter_ will typically support imports through a menu item or drag-and-drop. The examples below show how the command-line tool, `finport`, may be used to transform input files to delimited files of standardized schema.

As support for services expands, more examples will be listed below.

### Tabular

To detect a supported schema of a delimited file:

```bash
$ finport detect mystery.txt
=> openalloc/account: text/csv
```

### Fido (Fidelity) Positions

To transform the "Portfolio_Positions_Mmm-dd-yyyy.csv" export requires two commands, as there are two outputs, account holdings and securities:

```bash
$ finport transform Portfolio_Positions_Jun-30-2021.csv --output-schema openalloc/holding
$ finport transform Portfolio_Positions_Jun-30-2021.csv --output-schema openalloc/security
```

Each command above will produce comma-separated value data in the following schemas, respectively.

Output schemas: [openalloc/holding](https://github.com/openalloc/AllocData#mholding) and  [openalloc/security](https://github.com/openalloc/AllocData#msecurity)

### Fido (Fidelity) Purchases

To transform the "Accounts_History.csv" export:

```bash
$ finport transform Accounts_History.csv
```

The command above will produce comma-separated value data in the following schema.

Output schema:  [openalloc/history](https://github.com/openalloc/AllocData#mhistory)

### Fido (Fidelity) Sales

To transform the "Realized_Gain_Loss_Account_00000000.csv" export, available in the 'Closed Positions' view of taxable accounts:

```bash
$ finport transform Realized_Gain_Loss_Account_00000000.csv
```

The command above will produce comma-separated value data in the following schema.

Output schema: [openalloc/history](https://github.com/openalloc/AllocData#mhistory)

### AllocSmart (Allocate Smartly) Export

To transform an export from this service:

```bash
$ finport transform "Allocate Smartly Model Portfolio.csv"
```

The command above will produce comma-separated value data in the following schema.

Output schema: [openalloc/allocation](https://github.com/openalloc/AllocData#mallocation)

## Command Line

_FINporter_ features `finport`, a powerful command-line tool to detect and transform financial data, such as exports from your brokerage account.

```bash
$ swift build
$ .build/debug/finport

OVERVIEW: A utility for transforming financial data.

USAGE: finport <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  list                    List things available.
  schema                  Describe schema details.
  detect                  Detect schema of file.
  transform               Transform data in file.

  See 'finport help <subcommand>' for detailed help.
```

If your favorite product (e.g., _FlowAllocator_) hasn't yet incorporated the latest FINporter library supporting your service, you can still transform exports using `finport`. See examples above.

## License

Copyright 2021 FlowAllocator LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Contributing

You can fork this project to further its development. Submit pull requests for inclusion. Your contribution must be under the same license.

Please ensure your contribution has adequate test coverage and command-line support. See tests for current importers to see what coverage is expected.

Contributions are at will. Project owner(s) may reject for any reason. Accepted contributions may be later withdrawn, such as due to legal threats.







