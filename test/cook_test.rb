require 'test_helper'
require 'chef/knife'
require 'chef/knife/cook'

class CookTest < TestCase
  def test_takes_config_as_second_arg
    cmd = command("host", "nodes/myhost.json")
    assert_equal "nodes/myhost.json", cmd.node_config
  end

  def test_defaults_to_host_name
    cmd = command("host")
    assert_equal "nodes/host.json", cmd.node_config
  end

  def test_gets_destination_path_from_chef_config
    # See from_file method in mixlib/config.rb if expectation fails
    IO.expects(:read).returns <<-CONFIG
      file_cache_path "/tmp/chef-solo"
    CONFIG
    assert_equal "/tmp/chef-solo", command.chef_path
  end

  def command(*args)
    Chef::Knife::Cook.new(args)
  end
end
