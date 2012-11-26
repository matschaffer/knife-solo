require 'test_helper'
require 'support/validation_helper'

require 'chef/knife/solo_clean'

class SoloCleanTest < TestCase
  include ValidationHelper::ValidationTests

  def command(*args)
    knife_command(Chef::Knife::SoloClean, *args)
  end
end
