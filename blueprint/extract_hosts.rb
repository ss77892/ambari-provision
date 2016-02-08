#!/usr/bin/env ruby

require 'json'

USAGE = 'Usage: ./extract_hosts.rb <cluster.json>'

raise USAGE unless ARGV.length == 1

cluster_json_path = ARGV.pop
cluster_json_file = File.read(cluster_json_path)
cluster_json = JSON.parse(cluster_json_file)

begin
  host_groups = cluster_json['host_groups']
  hosts = host_groups.map{ |host_group| host_group['hosts'].map{ |host| host['fqdn'] } }.flatten.uniq
rescue Exception => e
  puts "Failed to parse #{cluster_json_path}: #{e}"
  puts e.backtrace
  exit 1
end

hosts.each do |host|
  puts "#{host}"
end

exit 0
