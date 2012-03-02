require 'integration_helper'

class Gentoo2011Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-ae49b7c7"
  end

  # `emerge chef` takes a very long time (~ 50 minutes) on an m1.small
  # Uncoment this if you need to verify Gentoo operation

  # include IntegrationTest::BasicPrepareAndCook
end
