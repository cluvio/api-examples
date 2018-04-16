## README

This folder contains a simple tool that uses the Cluvio REST API to update all reports of a specified dashboard and change them to use the specified datasource. 

## Installation

This tool is written in Ruby and uses `httparty` gem to make the HTTP calls.
To install the dependencies, you can either use Bundler:

```
bundle install
```

or simply install the `httparty` gem, as this is the only dependency:

```
gem install httparty
```

## Usage

```
Usage: move-dashboard-to-datasource.rb [options]
    -u, --user=<user_name>           Account username/email
    -p, --password=[password]        Account password (optional, will prompt for it if not present)
        --dashboard=<dashboard_id>   Dashboard id
        --datasource=<datasource_id> Datasource id
    -s, --server=[server_host]       Cluvio server host
    -v, --verbose                    Run verbosely
```

Basic usage:
```
$ ./move-dashboard-to-datasource.rb --user=user@example.com --datasource=ky2e-xg6n-wgvn --dashboard=8qxn-y9mk-p5vd
Password: ...
Checking datasource... OK
Checking dashboard... OK
```
