# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License see README.txt for more details 

# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'ib-ruby'

task :default => 'spec:run'

PROJ.name = 'ib-ruby'
PROJ.authors = 'Wes Devauld'
PROJ.email = 'wes@devauld.ca'
PROJ.url = 'http://github.com/wdevauld/ib-ruby/tree/master'
PROJ.version = IbRuby::VERSION

PROJ.spec.opts << '--color'

# EOF
