require 'integration_helper'

class OmniOSr151004Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-4e2c9727"
  end

  include EmptyCook
  include EncryptedDataBag
end
