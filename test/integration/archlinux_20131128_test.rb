require 'integration_helper'

class ArchLinux20131128Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-d1cbebb8"
  end

  include EmptyCook
  include EncryptedDataBag
end
