begin
  require 'rake'
rescue LoadError
  require 'rubygems'
  gem 'rake', '~> 0.8.3.1'
  require 'rake'
end

require 'pathname'

BASE_PATH = Pathname.new(__FILE__).dirname
LIB_PATH = BASE_PATH + 'lib'
PKG_PATH = BASE_PATH + 'pkg'
DOC_PATH = BASE_PATH + 'rdoc'

$LOAD_PATH.unshift LIB_PATH.to_s
require 'ib-ruby/version'

NAME = 'ib-ruby'
CLASS_NAME = IB

# Load rakefile tasks
Dir['tasks/*.rake'].sort.each { |file| load file }

# Project-specific tasks
