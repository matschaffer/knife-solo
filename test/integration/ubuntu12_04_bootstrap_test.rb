require 'integration_helper'

class Ubuntu12_04BootstrapTest < IntegrationTest
  def user
    "ubuntu"
  end

  def image_id
    "ami-9a873ff3"
  end

  def prepare_server
    # Do nothing as `solo bootstrap` will do everything
  end

  include Apache2Bootstrap
end
