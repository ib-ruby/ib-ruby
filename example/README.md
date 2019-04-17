## IB-RUBY EXAMPLES:

This folder contains sample scripts that demonstrate common ib-ruby use cases.
The scripts show you how to access account info, print real time quotes, retrieve
historic or fundamental data, request options calculations, place, list, and cancel orders.
You may also want to look into `spec/integration` directory for more scenarios,
use cases and examples of handling IB messages.

Normally you run these examples like this:

    $ ruby example/list_orders

The examples are executable.
If you're on Unix-like platform, they can be called directly ( » ./{script} «)

The Examples assume a running Gateway-Application on Localhost. Please use a Demo-Account or run
the API in »read-only-mode«

## EXAMPLE DESCRIPTION:

*account_info* - Request your account info, current positions, portfolio values and so on

    $ ruby example/account_info   # or cd example; ./account_info

For Financial Advisors, you need to add the managed account you want info for:

    $ ruby example/account_info U123456

*cancel_orders*  - Cancel either all open orders, or specific order(s),  by their (local) ids. Examples:

    $ ruby example/cancel_orders
    $ ruby example/cancel_orders 492 495

*contract_details* - Obtain detailed descriptions for specific Stock, Option, Forex, Futures and Bond contracts.

*contract_sample details* - Define Contract samples provided by java and python API-implementations

*depth_of_market* - Receive a stream of MarketDepth change events for Stock, Forex and Future symbols.

*fa_accounts* - Get info about accounts under management (for Financial Advisors).

*flex_query* - Run a pre-defined Flex query, receive and print Flex report. Example:

    $ ruby example/flex_query 12345 # Flex query id pre-defined in Account Management

*fundamental_data* - Request and print fundamental data report for a specific stock.

*historic_data* - Receive 5 days of 1-hour trade data for Stock, Forex and Future symbols.

*historic_data_cli* - CLI script for historic data downloading. It has many options, for detailed help run:

    $ ruby example/historic_data_cli

*list_orders* - List all open API orders.

*market_data* - Receive a stream of trade events for multiple Forex symbols.

*option_data* - Receive a stream of underlying, price and greeks calculations for multiple Option symbols.

*place_braket_order* - Place a braket order for Stock.

*place_combo_order* - Place an Option combo order (Google butterfly).

*place_order* - Place a simple limit order to buy Stock.

*portfolio_csv* - Exports your IB portfolio in a CSV format. Usage:

    $ ruby example/portfolio_csv [account] > my_portfolio.csv

*real_time_data* - Subscribe to real time data for specific symbol.

*template* - A blank example to start a new script (setting up all the dependencies).

*tick_data* - Subscribe to extended tick types for a single stock symbol.

*time_and_sales* - Print out Time&Sales format for Futures symbols.
