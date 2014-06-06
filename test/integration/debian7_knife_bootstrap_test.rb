require 'integration_helper'

class Debian7KnifeBootstrapTest < IntegrationTest
  def user
    "admin"
  end

  def image_id
    # PVM instance store
    # From https://wiki.debian.org/Cloud/AmazonEC2Image/Wheezy
    "ami-848a6eec"
  end

  def prepare_server
    # Do nothing as `knife bootstrap --solo` will do everything
  end

  def default_apache_message
    /It works!/
  end

  include KnifeBootstrap
end
