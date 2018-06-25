#!/usr/bin/env ruby
require 'optparse'
require 'json'
require 'httparty'
require 'io/console'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: migrate.rb [options]'

  opts.on('-u', '--user=<user_name>', String, 'Account username/email') do |value|
    options[:user] = value
  end

  opts.on('-p', '--password=[password]', String, 'Account password (optional, will prompt for it if not present)') do |value|
    options[:password] = value
  end

  opts.on('-d', '--dashboard=<dashboard_id>', String, 'Dashboard id') do |value|
    options[:dashboard] = value
  end

  opts.on('--datasource=<datasource_id>', String, 'Datasource id') do |value|
    options[:datasource] = value
  end

  opts.on('--from=<from_value>', String, 'From Filter value') do |value|
    options[:from_value] = value
  end

  opts.on('--to=<to_value>', String, 'To Filter value') do |value|
    options[:to_value] = value
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

  mandatory = [:user, :dashboard, :datasource, :from_value, :to_value]
  missing = mandatory.select{ |param| options[param].nil? }
  unless missing.empty?
    raise OptionParser::MissingArgument.new(missing.join(', '))
  end

  password = options[:password]
  if password.nil? || password.empty?
    print 'Password: '
    password = STDIN.noecho(&:gets).chomp
  end

  server_url = options[:server] || 'https://api.cluvio.com'
  dashboard_id = options[:dashboard]
  datasource_id = options[:datasource]
  from_value = options[:from_value]
  to_value = options[:to_value]

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

  print 'Checking datasource...'

  datasource_response = HTTParty.get("#{server_url}/datasources/#{datasource_id}",
                         headers: {
                             'Content-Type'  => 'application/json',
                             'token' => token
                         }
  )

  unless datasource_response.success?
    puts ' ERROR'
    puts "Datasource #{datasource_id} not found"
    exit 2
  end

  datasource = JSON.parse(datasource_response.body)
  datasource_name = datasource['data']['attributes']['name']

  puts " OK, name: #{datasource_name}"
 
  print 'Checking dashboard...'

  dashboard_response = HTTParty.get("#{server_url}/dashboards/#{dashboard_id}",
                                     headers: {
                                         'Content-Type'  => 'application/json',
                                         'token' => token
                                     }
  )

  unless dashboard_response.success?
    puts ' ERROR'
    puts "Dashboard #{dashboard_id} not found"
    exit 2
  end

  dashboard = JSON.parse(dashboard_response.body)
  

  dashboard_name = dashboard['data']['attributes']['name']
  num_reports = dashboard['data']['relationships']['reports']['data'].length
  puts " OK, name: #{dashboard_name}"
  if num_reports == 0
    puts 'The dashboard contains no reports, I\'ve got nothing to do'
    exit 0
  end
  puts "The dashboard contains #{num_reports} report#{num_reports > 1 ? 's' : ''}. Do you want to proceed using the '#{datasource_name}' datasource and replacing filter 'filter_#{from_value}' by 'filter_#{to_value}'?"
  print '[Y/n]: '
  prompt = STDIN.gets.chomp
  if prompt == 'n' || prompt == 'N'
    puts 'Exiting, no changes have been made'
    exit 0
  end

  dashboard['data']['relationships']['reports']['data'].each do |report|
    print "Updating report #{report['id']}..."

    # update datasource
    update_response = HTTParty.put("#{server_url}/reports/#{report['id']}",
                                      body: {
                                        data: {
                                            relationships: {
                                                datasource: {
                                                    data: {
                                                        id: datasource_id,
                                                        type: 'datasources'
                                                    }

                                                },
                                                dashboard: {
                                                    data: {
                                                        id: dashboard_id,
                                                        type: 'dashboards'
                                                    }

                                                }
                                            }
                                        }
                                      }.to_json,
                                      headers: {
                                          'Content-Type'  => 'application/json',
                                          'token' => token
                                      }
    )

    # update filters
    report_response = HTTParty.get("#{server_url}/reports/#{report['id']}",
                                     headers: {
                                         'Content-Type'  => 'application/json',
                                         'token' => token
                                     }
    )

    unless report_response.success?
      puts ' ERROR'
      puts "Report #{report['id']} not found"
      exit 2
    end

    report_json = JSON.parse(report_response.body)

    query_upd = report_json['data']['attributes']['query'].gsub "filter_#{from_value}", "filter_#{to_value}"
    report_json['data']['attributes']['query'] = query_upd
    update_response = HTTParty.patch("#{server_url}/reports/#{report['id']}",
                                      body: {
                                        data: report_json['data']
                                      }.to_json,
                                      headers: {
                                          'Content-Type'  => 'application/json',
                                          'token' => token
                                      }
    )

    unless update_response.success?
      puts ' ERROR'
      puts update_response
      exit 4
    end
    puts ' DONE'
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
