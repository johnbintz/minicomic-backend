#!/usr/bin/ruby

require 'yaml'
require 'time'

THIS_FILE = File.symlink?(__FILE__) ? File.expand_path(File.readlink(__FILE__)) : File.expand_path(__FILE__)

%w(classes modules).each do |which|
  Dir[File.dirname(THIS_FILE) + "/#{which}/*.rb"].each do |file|
    require file
  end
end

if !ARGV[0]
  puts "Usage: #{File.basename(__FILE__)} <path to YAML file>"
  exit 0
end

if !File.exists?(ARGV[0])
  puts "#{ARGV[0]} doesn't exist!"
  exit 1
end

config_loader = ConfigLoader.new
config = config_loader.load(ARGV[0])

file_processor = FileProcessor.new(config)
file_processor.process
