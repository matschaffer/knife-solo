require 'integration_helper'

class Ubuntu12_04Test < IntegrationTest
  def user
    "ubuntu"
  end

  def image_id
    "ami-098f5760"
  end

  def prepare_server
    return if server.tags["knife_solo_prepared"]
    assert_subcommand "prepare --omnibus-version '0.10.10-1'"
    runner.tag_as_prepared(server)
  end

  include EmptyCook
  include Apache2Cook
end
