require 'integration_helper'

class Sles11_Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-e0a35789"
  end

  include IntegrationTest::BasicPrepareAndCook
end
