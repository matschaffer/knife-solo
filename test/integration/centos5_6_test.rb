require 'integration_helper'

class Centos5_6Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-3fe42456"
  end

  def default_apache_message
    /Apache 2 Test Page/
  end

  include EmptyCook
  include Apache2Cook
end
