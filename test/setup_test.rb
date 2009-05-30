# set up test environment
RAILS_ENV = 'test'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'test/unit'
 
# load test schema
load(File.dirname(__FILE__) + "/schema.rb")
 
# load test models
require File.join(File.dirname(__FILE__), 'models/white_list_all')
require File.join(File.dirname(__FILE__), 'models/white_list_except')
require File.join(File.dirname(__FILE__), 'models/white_list_none')
require File.join(File.dirname(__FILE__), 'models/white_list_only')
