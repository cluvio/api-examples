#!/usr/bin/env ruby
require 'optparse'
require 'json'
require 'httparty'
require 'io/console'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: duplicate.rb [options]'

  opts.on('-u', '--user=<user_name>', String, 'Account username/email') do |value|
    options[:user] = value
  end

  opts.on('-p', '--password=[password]', String, 'Account password (optional, will prompt for it if not present)') do |value|
    options[:password] = value
  end

  opts.on('-d', '--dashboards=<dashboards_id>', String, 'Source dashboards ids, separated by commas') do |value|
    options[:dashboards] = value
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

  mandatory = [:user, :dashboards]
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
  dashboards_ids = options[:dashboards]

  customers = {"valres" => "Valres Fund Management SA",
		"cronos" => "Cronos Finance",
		"dominice" => "Dominicé"}

  datasources = {"valres" => "0d96-xz2x-8g1e",
		"cronos" => "6pz0-wr2q-rgdn",
		"dominice" => "5e4y-qp7q-kl9m"}

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

  puts "I will duplicate dashboards '#{dashboards_ids}' for customers #{customers.keys}. Do you want to proceed ?"
  print '[Y/n]: '
  prompt = STDIN.gets.chomp
  if prompt == 'n' || prompt == 'N'
    puts 'Exiting, no changes have been made'
    exit 0
  end

  # loop over standard dashboards
  dashboards_ids.split(',').each do |dashboard_id|
    
    puts 'Checking dashboard...'
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

    # loop over customers to duplicate dashboard
    customers.each do |customer_id, customer_name|
      puts "Duplicate dashboard #{dashboard_id} for #{customer_id} ..."

      new_dashboard_response = HTTParty.post("#{server_url}/dashboards/#{dashboard_id}/duplicate",
                                     headers: {
                                         'Content-Type'  => 'application/json',
                                         'token' => token
                                     }
      ) 

      dashboard = JSON.parse(new_dashboard_response.body)

      # patch with new name
      name_upd = dashboard['data']['attributes']['name'].gsub "Standard", customer_name
      dashboard['data']['attributes']['name'] = name_upd
      duplicated_dashboard_id = dashboard['data']['id']

      patched_dashboard_response = HTTParty.patch("#{server_url}/dashboards/#{duplicated_dashboard_id}",
				     body: {
					data: dashboard['data']
				     }.to_json,
                                     headers: {
                                         'Content-Type'  => 'application/json',
                                         'token' => token
                                     }
      )
  
      datasource_id = datasources[customer_id]
      dashboard_name = dashboard['data']['attributes']['name']
      num_reports = dashboard['data']['relationships']['reports']['data'].length
      puts " OK, name: #{dashboard_name}"
      if num_reports == 0
        puts 'The dashboard contains no reports, I\'ve got nothing to do'
        exit 0
      end

      dashboard['data']['relationships']['reports']['data'].each do |report|
        puts "Updating report #{report['id']}..."

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
                                                        id: duplicated_dashboard_id,
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

        query_upd = report_json['data']['attributes']['query'].gsub "filter_standard", "filter_#{customer_id}"
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

      update_response = HTTParty.post("#{server_url}/dashboards/#{dashboard_id}/refresh",
                                      headers: {
                                          'Content-Type'  => 'application/json',
                                          'token' => token
                                      }
				)
    end
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
