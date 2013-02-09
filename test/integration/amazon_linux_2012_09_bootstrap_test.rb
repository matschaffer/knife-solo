require 'integration_helper'

class AmazonLinux2012_09BootstrapTest < IntegrationTest
  def user
    "ec2-user"
  end

  def image_id
    "ami-1624987f"
  end

  def prepare_server
    # Do nothing as `solo bootstrap` will do everything
  end

  include Apache2Bootstrap
end
