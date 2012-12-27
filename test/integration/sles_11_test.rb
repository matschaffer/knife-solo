require 'integration_helper'

class Sles11_Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-ca32efa3"
  end

  include EmptyCook
  include EncryptedDataBag
end
