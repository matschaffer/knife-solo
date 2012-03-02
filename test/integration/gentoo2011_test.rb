require 'integration_helper'

class Gentoo2011Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-ae49b7c7"
  end

  include IntegrationTest::BasicPrepareAndCook
end
