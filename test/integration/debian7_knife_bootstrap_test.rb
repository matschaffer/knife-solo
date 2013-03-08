require 'integration_helper'

class Debian7KnifeBootstrapTest < IntegrationTest
  def user
    "admin"
  end

  def image_id
    "ami-0c8b1d65"
  end

  def prepare_server
    # Do nothing as `knife bootstrap --solo` will do everything
  end

  def default_apache_message
    /It works!/
  end

  include KnifeBootstrap
end
