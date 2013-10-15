require 'integration_helper'

class Ubuntu12_04Test < IntegrationTest
  def user
    "ubuntu"
  end

  def image_id
    "ami-9a873ff3"
  end

  include EmptyCook
  include Apache2Cook
  include EncryptedDataBag
  include CachePathUsage
  include Environment
end
