require 'integration_helper'

class Ubuntu12_04Test < IntegrationTest
  def user
    "ubuntu"
  end

  def image_id
    "ami-098f5760"
  end

  def prepare_command
    "prepare"
  end

  include EmptyCook
  include Apache2Cook
  include EncryptedDataBag
end
