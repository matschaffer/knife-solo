require 'integration_helper'

class OmniOSr151014Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-79ee1b14"
  end

  include EmptyCook
  include EncryptedDataBag
end
