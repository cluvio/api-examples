## README

This folder contains a simple tool that uses the Cluvio REST API to search for reports that contain a specific text in their query. 

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
Usage: search-in-reports.rb [options]
    -u, --user=<user_name>           Account username/email
    -p, --password=[password]        Account password (optional, will prompt for it if not present)
    -t, --search_text=<search text>  The text to search for
    -s, --server=[server_host]       Cluvio server host (optional, only needed when used with Cluvio private cloud instances)
    -v, --verbose                    Run verbosely
```

Basic usage:
```
./search-in-reports.rb -u user@example.com -t airports
Password: 
Loading dashboards...
On dashboard Sample Ticket Sales (wxky-ozze-60lo):
On dashboard Sample Flights & Airports (805p-qqqz-pg7r):
  https://app.cluvio.com/dashboards/805p-qqqz-pg7r?reportId=1n07-lk2o-3zq8
  https://app.cluvio.com/dashboards/805p-qqqz-pg7r?reportId=nve7-j56d-xm01
  https://app.cluvio.com/dashboards/805p-qqqz-pg7r?reportId=3xp7-ej9p-8zvl
  https://app.cluvio.com/dashboards/805p-qqqz-pg7r?reportId=61p7-1gwj-37ok
  https://app.cluvio.com/dashboards/805p-qqqz-pg7r?reportId=j1rm-olgk-qmyw
On dashboard My First Dashboard (vrep-xll0-p1z2):
```
