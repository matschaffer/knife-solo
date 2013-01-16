require 'integration_helper'

class Debian7BootstrapTest < IntegrationTest
  def user
    "admin"
  end

  def image_id
    "ami-4d20a724"
  end

  def prepare_server
    # Do nothing as `solo bootstrap` will do everything
  end

  include Apache2Bootstrap
end
