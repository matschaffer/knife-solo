require 'integration_helper'

class Ubuntu14_04BootstrapTest < IntegrationTest
  def user
    "ubuntu"
  end

  def image_id
    "ami-c43491ac"
  end

  def prepare_server
    # Do nothing as `solo bootstrap` will do everything
  end

  include Apache2Bootstrap
end
