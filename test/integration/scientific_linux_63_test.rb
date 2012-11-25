require 'integration_helper'

class ScientificLinux63Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-313b8e58"
  end

  include EmptyCook
  #include Apache2Cook
  include EncryptedDataBag
end
