#!/usr/bin/ruby

require 'yaml'
begin
  require 'home_run'
rescue LoadError
  STDERR.puts "Install home_run for faster date handling"
end

require 'time'

begin
  require 'minicomic-backend'
rescue LoadError
  $LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  require 'minicomic-backend'
end

require 'minicomic-backend/config_loader'
require 'minicomic-backend/file_processor'

if !ARGV[0]
  STDERR.puts "Usage: #{File.basename(__FILE__)} <path to YAML file>"
  exit 0
end

if !File.exists?(ARGV[0])
  STDERR.puts "#{ARGV[0]} doesn't exist!"
  exit 1
end

config_loader = ConfigLoader.new
config = config_loader.load(ARGV[0])

file_processor = FileProcessor.new(config)
file_processor.process!
