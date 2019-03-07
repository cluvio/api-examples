#!/usr/bin/env ruby
require 'optparse'
require 'json'
require 'httparty'
require 'io/console'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: search-in-reports.rb [options]'

  opts.on('-u', '--user=<user_name>', String, 'Account username/email') do |value|
    options[:user] = value
  end

  opts.on('-p', '--password=[password]', String, 'Account password (optional, will prompt for it if not present)') do |value|
    options[:password] = value
  end

  opts.on('-t', '--search_text=<search text>', String, 'The text to search for') do |value|
    options[:search_text] = value
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

  mandatory = [:user,:search_text]
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
  search_text = options[:search_text]

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

  print 'Loading dashboards...'

  dashboard_list_response = HTTParty.get("#{server_url}/dashboards",
                                     headers: {
                                         'Content-Type'  => 'application/json',
                                         'token' => token
                                     }
  )

  unless dashboard_list_response.success?
    puts ' ERROR'
    puts "Error loading dashboards"
    exit 2
  end
  puts

  all_reports = {}

  dashboards = JSON.parse(dashboard_list_response.body)
  dashboards['data'].each do |dashboard|
    puts "On dashboard #{dashboard['attributes']['name']} (#{dashboard['id']}):"

    dashboard_response = HTTParty.get("#{server_url}/dashboards/#{dashboard['id']}",
                                      headers: {
                                          'Content-Type'  => 'application/json',
                                          'token' => token
                                      }
    )

    unless dashboard_response.success?
      puts ' ERROR'
      puts "Error loading dashboard"
      exit 2
    end

    dashboard_data = JSON.parse(dashboard_response.body)

    unless dashboard_data['included'].nil?
      dashboard_data['included'].select { |item| item['type'] == 'reports' }.each do |report_data|
        if report_data['attributes']['query'].include? search_text
          puts "  https://app.cluvio.com/dashboards/#{dashboard['id']}?reportId=#{report_data['id']}"
        end
      end
    end
  end

rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit 1
rescue HTTParty::Error, StandardError => e
  puts "Error connecting to server #{options[:server]}: #{e.message}"
  puts e.backtrace.join("\n") if options[:verbose]
  exit 3
end
