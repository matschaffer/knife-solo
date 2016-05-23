require 'integration_helper'

class Centos7Test < IntegrationTest
  # disable_firewall

  def flavor_id
    "m3.medium"
  end

  def user
    "centos"
  end

  def image_id
    "ami-6d1c2007"
  end

  include EmptyCook
  include Apache2Cook
  include EncryptedDataBag
end
