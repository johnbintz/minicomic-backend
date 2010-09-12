require 'rubygems'
require 'test/unit'
require 'mocha'
require 'fakefs/safe'

begin
  require 'minicomic-backend'
rescue LoadError
  $LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  require 'minicomic-backend'
end
