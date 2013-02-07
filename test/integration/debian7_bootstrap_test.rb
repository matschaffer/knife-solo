require 'integration_helper'

class Debian7BootstrapTest < IntegrationTest
  def user
    "admin"
  end

  def image_id
    "ami-0c8b1d65"
  end

  def prepare_server
    # Do nothing as `solo bootstrap` will do everything
  end

  def default_apache_message
    /It works!/
  end

  include Apache2Bootstrap
end
