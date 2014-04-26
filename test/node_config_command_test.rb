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

      assert_config_contains({"run_list" => []}, cmd)
    end
  end

  def test_wont_overwrite_node_config
    in_kitchen do
      cmd = command(@host, "--run-list=role[myrole]")
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

  def test_generates_a_node_config_with_specified_run_list
    in_kitchen do
      cmd = command(@host, "--run-list=role[base],recipe[foo]")
      cmd.generate_node_config

      assert_config_contains({"run_list" => ["role[base]","recipe[foo]"]}, cmd)
    end
  end

  def test_generates_a_node_config_with_specified_attributes
    in_kitchen do
      foo_json = '"foo":{"bar":[1,2],"baz":"x"}'
      cmd = command(@host, "--json-attributes={#{foo_json}}")
      cmd.generate_node_config

      expected_hash = {
        "foo" => {"bar" => [1,2], "baz" => "x"},
        "run_list" => []
      }

      assert_config_contains expected_hash, cmd
    end
  end

  def test_generates_a_node_config_with_specified_json_attributes
    in_kitchen do
      foo_json     = '"foo":99'
      ignored_json = '"bar":"ignored"'

      cmd = command(@host)
      cmd.config[:json_attributes]       = JSON.parse("{#{foo_json}}")
      cmd.config[:first_boot_attributes] = JSON.parse("{#{ignored_json}}")
      cmd.generate_node_config

      expected_hash = {
        "foo" => 99,
        "run_list" => []
      }

      assert_config_contains expected_hash, cmd
    end
  end

  def test_generates_a_node_config_with_specified_first_boot_attributes
    in_kitchen do
      cmd = command(@host)
      cmd.config[:first_boot_attributes] = {"foo"=>nil}
      cmd.generate_node_config

      expected_hash = {
        "foo" => nil,
        "run_list" => []
      }

      assert_config_contains expected_hash, cmd
    end
  end

  def test_generates_a_node_config_with_specified_run_list_and_attributes
    in_kitchen do
      foo_json = '"foo":"bar"'
      run_list = 'recipe[baz]'
      cmd = command(@host, "--run-list=#{run_list}", "--json-attributes={#{foo_json}}")
      cmd.generate_node_config

      expected_hash = {
        "foo" => "bar",
        "run_list" => [run_list]
      }

      assert_config_contains expected_hash, cmd

    end
  end

  def test_generates_a_node_config_with_the_ip_address
    in_kitchen do
      cmd = command(@host)
      cmd.generate_node_config

      expected_hash = {
        "automatic" => { "ipaddress" => @host }
      }

      assert_config_contains expected_hash, cmd

    end
  end



  def test_creates_the_nodes_directory_if_needed
    outside_kitchen do
      cmd = command(@host, "--node-name=mynode")
      cmd.generate_node_config
      assert cmd.node_config.exist?
    end
  end

  private

  def command(*args)
    knife_command(DummyNodeConfigCommand, *args)
  end

  def assert_config_contains expected_hash, cmd
    config = JSON.parse(cmd.node_config.read)
    expected_hash.each do |k, v|
      assert_equal v, config[k]
    end
  end

end
