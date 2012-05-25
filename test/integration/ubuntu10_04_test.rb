require 'integration_helper'

class Ubuntu10_04Test < IntegrationTest
  def user
    "ubuntu"
  end

  def image_id
    "ami-6936fb00"
  end

  include EmptyCook
  include Apache2Cook
end
