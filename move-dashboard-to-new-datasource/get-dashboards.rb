#!/usr/bin/env ruby
require 'optparse'
require 'json'
require 'httparty'
require 'io/console'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: get-datasources.rb [options]'

  opts.on('-u', '--user=<user_name>', String, 'Account username/email') do |value|
    options[:user] = value
  end

  opts.on('-p', '--password=[password]', String, 'Account password (optional, will prompt for it if not present)') do |value|
    options[:password] = value
  end

  opts.on('-s', '--server=[server_host]', String, 'Cluvio server host (optional, only needed when used with Cluvio private cloud instances)') do |value|
    options[:server] = value
  end

  opts.on('-v', '--verbose', 'Run verbosely') do
    options[:verbose] = true
  end
end

begin
  optparse.parse!

  mandatory = [:user]
  missing = mandatory.select{ |param| options[param].nil? }
  unless missing.empty?
    raise OptionParser::MissingArgument.new(missing.join(', '))
  end

  password = options[:password]
  if password.nil? || password.empty?
    print 'Password: '
    password = STDIN.noecho(&:gets).chomp
    puts password
  end

  server_url = options[:server] || 'https://api.cluvio.com'

  res = HTTParty.post("#{server_url}/users/sign_in",
                      body: {
                          user: {
                              email: options[:user],
                              password: password
                          }
                      }.to_json,
                      headers: {
                          'Content-Type'  => 'application/json',
                      }
  )

  unless res.success?
    puts 'Login failed'
    puts res.code
    exit 2
  end

  token = JSON.parse(res.body)['token']
 
  puts 'Getting dashboards...'

  dashboard_response = HTTParty.get("#{server_url}/dashboards",
                                     headers: {
                                         'Content-Type'  => 'application/json',
                                         'token' => token
                                     }
  )

  unless dashboard_response.success?
    puts ' ERROR'
    puts "Dashboards"
    exit 2
  end

  dashboards = JSON.parse(dashboard_response.body)['data']

  dashboards.each do |d|
    dashboard_name = d['attributes']['name']
    dashboard_id = d['id']
    puts "#{dashboard_id}: #{dashboard_name}"
  end

rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit 1
rescue JSON::ParserError, TypeError => e
  puts "Error parsing json body from response"
  puts e
  exit 1
rescue HTTParty::Error, StandardError => e
  puts "Error connecting to server #{options[:server]}: #{e.message}"
  puts e.backtrace.join("\n") if options[:verbose]
  exit 3
end
