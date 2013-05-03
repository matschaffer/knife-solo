require 'integration_helper'

class Centos5_8Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-100e8a79"
  end

  include EmptyCook
  include Apache2Cook
  include EncryptedDataBag
end
