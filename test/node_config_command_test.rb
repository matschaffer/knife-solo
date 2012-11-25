require 'test_helper'
require 'support/kitchen_helper'

require 'chef/knife'
require 'knife-solo/node_config_command'

class DummyNodeConfigCommand < Chef::Knife
  include KnifeSolo::NodeConfigCommand

  # This is normally declared in KnifeSolo::SshCommand
  def host
    @name_args.first
  end
end

class NodeConfigCommandTest < TestCase
  include KitchenHelper

  def setup
    @host = "defaulthost"
  end

  def test_node_config_defaults_to_host_name
    cmd = command(@host)
    assert_equal "nodes/#{@host}.json", cmd.node_config.to_s
  end

  def test_takes_node_config_as_second_arg
    cmd = command(@host, "nodes/myhost.json")
    assert_equal "nodes/myhost.json", cmd.node_config.to_s
  end

  def test_takes_node_config_from_option
    cmd = command(@host, "--node-name=mynode")
    assert_equal "nodes/mynode.json", cmd.node_config.to_s
  end

  def test_takes_node_config_as_second_arg_even_with_name_option
    cmd = command(@host, "nodes/myhost.json", "--node-name=mynode")
    assert_equal "nodes/myhost.json", cmd.node_config.to_s
  end

  def test_generates_a_node_config
    in_kitchen do
      cmd = command(@host)
      cmd.generate_node_config
      assert cmd.node_config.exist?
    end
  end

  def test_wont_overwrite_node_config
    in_kitchen do
      cmd = command(@host)
      File.open(cmd.node_config, "w") do |f|
        f << "testdata"
      end
      cmd.generate_node_config
      assert_match "testdata", cmd.node_config.read
    end
  end

  def test_generates_a_node_config_from_name_option
    in_kitchen do
      cmd = command(@host, "--node-name=mynode")
      cmd.generate_node_config
      assert cmd.node_config.exist?
    end
  end

  def command(*args)
    knife_command(DummyNodeConfigCommand, *args)
  end
end
