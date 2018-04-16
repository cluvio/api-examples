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
Checking datasource... OK, name: Redshift
Checking dashboard... OK, name: Sample Flights & Airports
The dashboard contains 10 reports. Do you want to proceed and update these to use the 'Redshift' datasource?
[Y/n]:
Updating report evrp-70n3-zly3... DONE
Updating report k1x5-my1n-mo42... DONE
Updating report kgov-mxov-m6qd... DONE
Updating report dvjq-m82q-m3r2... DONE
Updating report d6qp-m3jx-zj3y... DONE
Updating report 6wpx-z2ey-z2vl... DONE
Updating report qw1x-7wyl-zrd5... DONE
Updating report q694-zrww-m8jo... DONE
Updating report p3ow-mg5x-zk48... DONE
Updating report p4ex-z9w8-m8nd... DONE
```
