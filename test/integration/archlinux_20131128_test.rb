require 'integration_helper'

class ArchLinux20131128Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-d1cbebb8"
  end

  # this install method takes over 15m on an m1.small
  # Uncomment this if you need to verify Arch operation

  # include EmptyCook
  # include EncryptedDataBag
end
