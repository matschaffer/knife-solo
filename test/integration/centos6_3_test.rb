require 'integration_helper'

class Centos6_3Test < IntegrationTest
  disable_firewall

  def user
    "root"
  end

  def image_id
    "ami-86e15bef"
  end

  include EmptyCook
  include Apache2Cook
  include EncryptedDataBag
end
