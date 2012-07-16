module Ib
  class ApplicationController <
    defined?(::ApplicationController) ? ::ApplicationController :  ActionController::Base
  end
end
