## README

This folder contains a simple tool to quickly generate sharing secret for embedding of a dashboard with "Requires Secret" flag.

## Installation

This tool is written in Ruby and uses `JWT` gem to generate the JWT token.
To install the dependencies, you can either use Bundler:

```
bundle install
```

or simply install the `JWT` gem, as this is the only dependency:

```
gem install JWT
```

## Usage

```
Usage: generate-sharing-secret.rb [options]
    -d, -dashboard=<dashboard id>            The id of the dashboard (e.g. wm73-peg8-y0qv)
    -t, --token=<sharing_token>              The sharing token from the sharing link (e.g. 55e5b0cb-7e7b-4380-8254-cd897198a7e2)
    -s, --secret=<secret>                    Account secret (can be found here for your account: https://app.cluvio.com/admin/organization)
    -e, --expiration=<expiration in seconds> The expiration in seconds (defaults to 10 minutes if not provided)
    -f, --filter=<filter_name:filter_values> The values to fix for a filter, separate values by comma and quote string if it contains special characters or space (use multiple times for more filters)
    -v, --verbose                            Print more details in output
```

Example usage, using a sample dashboard and a valid sample secret that works as is. Note that you never want to expose the account secret in this way (e.g. by committing to git) for your account.

```
# Generate sharing secret with basic 10 minute expiration
./generate-sharing-secret.rb -d wm73-peg8-y0qv -t 8956a950-cfa8-48e8-9e34-bdc791dab756 -s d880b5e74cea82a4e8998ae0e8775176fb440a4569eb097505f7e08e555b17b5aad78b5fa1f47acd1fbfbd876631dfdd

# Generate sharing secret with 1 hour expiration
./generate-sharing-secret.rb -d wm73-peg8-y0qv -t 8956a950-cfa8-48e8-9e34-bdc791dab756 -s d880b5e74cea82a4e8998ae0e8775176fb440a4569eb097505f7e08e555b17b5aad78b5fa1f47acd1fbfbd876631dfdd -e 3600

# Generate sharing secret with basic 10 minute expiration and fix aggregation to year and countries to Czech Republic and Slovakia
./generate-sharing-secret.rb -d wm73-peg8-y0qv -t 8956a950-cfa8-48e8-9e34-bdc791dab756 -s d880b5e74cea82a4e8998ae0e8775176fb440a4569eb097505f7e08e555b17b5aad78b5fa1f47acd1fbfbd876631dfdd -f aggregation:year -f "countries:Czech Republic,Slovakia"
```
