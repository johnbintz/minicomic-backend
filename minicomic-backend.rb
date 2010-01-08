#!/usr/bin/ruby

require 'yaml'
require 'time'

Dir[File.dirname(__FILE__) + "/classes/*.rb"].each do |file|
  require file
end

any_rebuilt = false
any_rsync = false

if !ARGV[0]
  puts "Usage: #{File.basename(__FILE__)} <path to YAML file>"
  exit 0
end

if !File.exists?(ARGV[0])
  puts "#{ARGV[0]} doesn't exist!"
  exit 1
end

if global['use_git']
  system("git add .")
  system("git commit -a")
end
