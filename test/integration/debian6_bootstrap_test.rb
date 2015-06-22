require 'integration_helper'


class Debian6BootstrapTest < IntegrationTest
  def user
    "admin"
  end

  def image_id
    # PVM 64-bit
    # From https://wiki.debian.org/Cloud/AmazonEC2Image/Squeeze
    "ami-5e12dc36"
  end

  def prepare_server
    # Do nothing as `solo bootstrap` will do everything
  end

  include Apache2Bootstrap
end
