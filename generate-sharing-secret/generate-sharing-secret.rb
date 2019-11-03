#!/usr/bin/env ruby
require 'optparse'
require 'JWT'
require 'io/console'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: generate-sharing-secret.rb [options]'

  opts.on('-d', '--dashboard=<dashboard id>', String, 'The id of the dashboard (e.g. wm73-peg8-y0qv)') do |value|
    options[:dashboard_id] = value
  end

  opts.on('-t', '--token=<sharing_token>', String, 'The sharing token from the sharing link (e.g. 55e5b0cb-7e7b-4380-8254-cd897198a7e2)') do |value|
    options[:sharing_token] = value
  end

  opts.on('-s', '--secret=<secret>', String, 'Account secret (can be found here: https://app.cluvio.com/admin/organization)') do |value|
    options[:secret] = value
  end

  opts.on('-e', '--expiration=<expiration in seconds>', String, 'The expiration in seconds (defaults to 10 minutes if not provided)') do |value|
    raise "Expiration must be greater than 0: #{value}" unless value.to_i > 0
    options[:expiration] = value.to_i
  end

  opts.on('-f', '--filter=<filter_name:filter_values>', String, 'The values to fix for a filter') do |value|
    options[:filters] = [] if options[:filters].nil?
    pos = value.index(':')

    raise "Invalid value for filter: #{value}" if pos.nil?
    filter_name = value[0...pos]
    filter_value = value[pos+1..-1]
    if filter_name != 'aggregation' && filter_name != 'timerange'
      options[:filters] << {
        filter_name: filter_name,
        filter_values: filter_value.split(',')
      }
    else
      options[:filters] << {
        filter_name: filter_name,
        filter_values: filter_value
      }
    end
  end

  opts.on('-v', '--verbose', 'Run verbosely') do
    options[:verbose] = true
  end
end

begin
  optparse.parse!

  mandatory = [:dashboard_id,:sharing_token,:secret]
  missing = mandatory.select{ |param| options[param].nil? }
  unless missing.empty?
    raise OptionParser::MissingArgument.new(missing.join(', '))
  end

  secret = options[:secret]
  dashboard_id = options[:dashboard_id]
  sharing_token = options[:sharing_token]
  expiration = options[:expiration] || 10*60

  hash = {
    sharing_token: sharing_token,
    exp: (Time.now + expiration).to_i
  }

  unless options[:filters].nil?
    hash[:fixed_parameters] = {}
    options[:filters].each do |filter|
      hash[:fixed_parameters][filter[:filter_name]] = filter[:filter_values]
    end
  end
  sharing_secret = JWT.encode(hash, secret)
  puts "URL: https://dashboards.cluvio.com/dashboards/#{dashboard_id}/shared?sharingToken=#{sharing_token}&sharingSecret=#{sharing_secret}"
  puts "Sharing secret: #{sharing_secret}" if options[:verbose]
  puts "Decoded secret: #{JWT.decode(sharing_secret, secret)}" if options[:verbose]
  puts "Expires on: #{Time.now + expiration}" if options[:verbose]
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit 1
rescue => e
  puts e.message
  puts optparse
  exit 1
end
