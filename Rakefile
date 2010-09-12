desc "Run Test::Unit Cases"
task :test do
  system("testrb test/*_test.rb")
end

#namespace :test do
#  desc "Run RCov analysis"
#  task :rcov do
#    system(%{rcov -x '.rvm' -x '/test/data/' test/*_test.rb})
#  end
#end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "minicomic-backend"
    s.executables = "minicomic-backend"
    s.summary = "Generate Web- and print-ready collections of comics from SVG files"
    s.email = "john@coswellproductions.com"
    s.homepage = "http://github.com/johnbintz/minicomic-backend"
    s.description = "Generate Web- and print-ready collections of comics from SVG files"
    s.authors = ["John Bintz"]
    s.files =  FileList["{bin,lib,test}/**/*"]
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler"
end
