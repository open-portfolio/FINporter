# FINporter

<img align="right" src="https://github.com/openalloc/FINporter/blob/main/Images/logo.png" width="100" height="100"/>A utility for transforming financial data.

Available both as a `finport` command line executable and as a Swift library to be incorporated in other apps.

Used by investing apps like [FlowAllocator](https://flowallocator.app), a new rebalancing tool for macOS.

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

To transform the "Portfolio_Positions_Mmm-dd-yyyy.csv" export requires four separate commands, as there are four outputs: accounts, account holdings, securities, and 'source meta':

```bash
$ finport transform Portfolio_Positions_Jun-30-2021.csv --output-schema openalloc/account
$ finport transform Portfolio_Positions_Jun-30-2021.csv --output-schema openalloc/holding
$ finport transform Portfolio_Positions_Jun-30-2021.csv --output-schema openalloc/security
$ finport transform Portfolio_Positions_Jun-30-2021.csv --output-schema openalloc/meta/source
```

The 'source meta' can extract the export date from the content, if present, as well as other details.

Each command above will produce comma-separated value data in the following schemas, respectively.

Output schemas: 
* [openalloc/account](https://github.com/openalloc/AllocData#maccount)
* [openalloc/holding](https://github.com/openalloc/AllocData#mholding)
* [openalloc/security](https://github.com/openalloc/AllocData#msecurity)
* [openalloc/meta/source](https://github.com/openalloc/AllocData#msourcemeta)

### Fido (Fidelity) History

To transform the "Accounts_History.csv" export, which contains a record of recent sales, purchases, and other transactions:

```bash
$ finport transform Accounts_History.csv
```

The command above will produce comma-separated value data in the following schema.

NOTE: output changed to the new MTransaction from the deprecated MHistory.

Output schema:  [openalloc/transaction](https://github.com/openalloc/AllocData#mtransaction)

### Fido (Fidelity) Sales

To transform the "Realized_Gain_Loss_Account_00000000.csv" export, available in the 'Closed Positions' view of taxable accounts:

```bash
$ finport transform Realized_Gain_Loss_Account_00000000.csv
```

The command above will produce comma-separated value data in the following schema.

NOTE: output changed to the new MTransaction from the deprecated MHistory.

Output schema: 
* [openalloc/transaction](https://github.com/openalloc/AllocData#mtransaction)

### Chuck (Schwab) Positions **BETA**

_This is an early release, and probably has bugs._

To transform the "All-Accounts-Positions-YYYY-MM-DD-000000.CSV" export requires four separate commands, as there are four outputs: accounts, account holdings, securities, and 'source meta':

```bash
$ finport transform All-Accounts-Positions-2021-06-30-012345.CSV --output-schema openalloc/account
$ finport transform All-Accounts-Positions-2021-06-30-012345.CSV --output-schema openalloc/holding
$ finport transform All-Accounts-Positions-2021-06-30-012345.CSV --output-schema openalloc/security
$ finport transform All-Accounts-Positions-2021-06-30-012345.CSV --output-schema openalloc/meta/source
```

Each command above will produce comma-separated value data in the following schemas, respectively.

NOTE: "Cash & Cash Investments" holdings will be assigned a SecurityID of "CORE".

The 'source meta' can extract the export date from the content, if present, as well as other details.

Output schemas: 
* [openalloc/account](https://github.com/openalloc/AllocData#maccount)
* [openalloc/holding](https://github.com/openalloc/AllocData#mholding)
* [openalloc/security](https://github.com/openalloc/AllocData#msecurity)
* [openalloc/meta/source](https://github.com/openalloc/AllocData#msourcemeta)

### Chuck (Schwab) History **BETA**

_This is an early release, and probably has bugs._

To transform the "XXXX1234_Transactions_YYYYMMDD-HHMMSS.CSV" export, which contains a record of recent sales, purchases, and other transactions:

```bash
$ finport transform XXXX1234_Transactions_YYYYMMDD-HHMMSS.CSV
```

The command above will produce comma-separated value data in the following schema.

NOTE: Schwab's transaction export does not contain realized gains and losses of sales, and so they are not in the imported transaction.

Output schema:  [openalloc/transaction](https://github.com/openalloc/AllocData#mtransaction)

### AllocSmart (Allocate Smartly) Export

To transform an export from this service:

```bash
$ finport transform "Allocate Smartly Model Portfolio.csv"
```

The command above will produce comma-separated value data in the following schema.

Output schema: 
* [openalloc/allocation](https://github.com/openalloc/AllocData#mallocation)

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

Contributions are welcome. You are encouraged to submit pull requests to fix bugs, improve documentation, or offer new features. 

The pull request need not be a production-ready feature or fix. It can be a draft of proposed changes, or simply a test to show that expected behavior is buggy. Discussion on the pull request can proceed from there.

Contributions should ultimately have adequate test coverage and command-line support. See tests for current importers to see what coverage is expected.






