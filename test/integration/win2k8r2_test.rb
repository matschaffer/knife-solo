require 'integration_helper'

class Win2k8R2Test < IntegrationTest
  def user
    "Administrator"
  end

  def image_id
    # Originally "ami-e2ed3f8b"
    "ami-26dc014f"
  end

  def flavor_id
    "t1.micro"
  end

  # Might need security group sg-5e688f36 ("windows")

  include IntegrationTest::BasicPrepareAndCook
end
