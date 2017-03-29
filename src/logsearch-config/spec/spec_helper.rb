# $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'helpers/filters_helper'
require 'helpers/app_helper'
require 'helpers/platform_helper'

RSpec.configure do |config|
  config.extend Helpers::FilterHelper
  config.include Helpers::FilterHelper

  config.extend Helpers::AppHelper
  config.include Helpers::AppHelper

  config.extend Helpers::PlatformHelper
  config.include Helpers::PlatformHelper
end
