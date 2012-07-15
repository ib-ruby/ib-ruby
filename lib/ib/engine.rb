module IB
  class Engine < ::Rails::Engine
    isolate_namespace IB

    #paths["app"]                 # => ["app"]
    #paths["app/controllers"]     # => ["app/controllers"]
    #paths["app/helpers"]         # => ["app/helpers"]
    paths["app/models"] = "lib/models"
    #paths["app/views"]           # => ["app/views"]
    #paths["lib"]                 # => ["lib"]
    #paths["lib/tasks"]           # => ["lib/tasks"]
    #paths["config"]              # => ["config"]
    #paths["config/initializers"] # => ["config/initializers"]
    #paths["config/locales"]      # => ["config/locales"]
    #paths["config/routes"]       # => ["config/routes.rb"]

    config.generators do |gen|
      gen.integration_tool :rspec
      gen.test_framework :rspec
      gen.helper_specs false
      # gen.view_specs false
    end

    config.to_prepare do
    end

    initializer "ib.active_record" do |app|
      ActiveSupport.on_load :active_record do
        require 'ib/db'
        require 'ib/requires'
      end
    end

  end
end
