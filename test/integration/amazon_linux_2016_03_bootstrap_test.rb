require 'integration_helper'

class AmazonLinux2016_03BootstrapTest < IntegrationTest
  def user
    "ec2-user"
  end

  def image_id
    "ami-4f111125"
  end

  def prepare_server
    # Do nothing as `solo bootstrap` will do everything
  end

  include Apache2Bootstrap
end
