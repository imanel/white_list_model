require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the white_list_model plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the white_list_model plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'WhiteListModel'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "white_list_model"
    gemspec.summary = "WhiteListModel will escape/whitelist user-input data before saving to database"
    gemspec.description = "WhiteListModel will escape/whitelist user-input data before saving to database"
    gemspec.email = "b.potocki@imanel.org"
    gemspec.homepage = "http://github.com/imanel/white_list_model"
    gemspec.authors = ["Bernard Potocki"]
    gemspec.files.exclude ".gitignore"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end