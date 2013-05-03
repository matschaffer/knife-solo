require 'integration_helper'

class Centos6_3Test < IntegrationTest
  def user
    "root"
  end

  def image_id
    "ami-86e15bef"
  end

  def prepare_server
    disable_firewall
    super
  end

  def disable_firewall
    system "ssh #{connection_string} service iptables stop >> #{log_file}"
  end

  include EmptyCook
  include Apache2Cook
  include EncryptedDataBag
end
