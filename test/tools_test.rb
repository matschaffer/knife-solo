require 'test_helper'
require 'support/kitchen_helper'

require 'chef/config'
require 'knife-solo/tools'

class DummyToolsCommand < Chef::Knife
  include KnifeSolo::Tools

  option :foo,
    :long => '--foo FOO'

  option :boo,
    :long => '--[no-]boo'
end

class ToolsTest < TestCase
  include KitchenHelper

  def setup
    Chef::Config[:knife][:foo] = nil
    Chef::Config[:knife][:boo] = nil
  end

  def test_config_value_defaults_to_nil
    assert_nil command.config_value(:foo)
    assert_nil command.config_value(:boo)
  end

  def test_config_value_returns_the_default
    assert_equal 'bar', command.config_value(:foo, 'bar')

    assert_equal true,  command.config_value(:boo, true)
    assert_equal false, command.config_value(:boo, false)
  end

  def test_config_value_uses_cli_option
    assert_equal 'bar', command('--foo=bar').config_value(:foo)
    assert_equal 'bar', command('--foo=bar').config_value(:foo, 'baz')

    assert_equal true, command('--boo').config_value(:boo)
    assert_equal true, command('--boo').config_value(:boo, false)
    assert_equal false, command('--no-boo').config_value(:boo)
    assert_equal false, command('--no-boo').config_value(:boo, true)
  end

  def test_config_value_uses_configuration
    Chef::Config[:knife][:foo] = 'bar'
    assert_equal 'bar', command.config_value(:foo)
    assert_equal 'bar', command.config_value(:foo, 'baz')

    Chef::Config[:knife][:boo] = true
    assert_equal true, command.config_value(:boo)
    assert_equal true, command.config_value(:boo, false)

    Chef::Config[:knife][:boo] = false
    assert_equal false, command.config_value(:boo)
    assert_equal false, command.config_value(:boo, true)
  end

  def test_config_value_prefers_cli_option
    Chef::Config[:knife][:foo] = 'foo'
    assert_equal 'bar', command('--foo=bar').config_value(:foo)
    assert_equal 'bar', command('--foo=bar').config_value(:foo, 'baz')

    Chef::Config[:knife][:boo] = true
    assert_equal true, command('--boo').config_value(:boo)
    assert_equal true, command('--boo').config_value(:boo, false)
    assert_equal false, command('--no-boo').config_value(:boo)
    assert_equal false, command('--no-boo').config_value(:boo, true)

    Chef::Config[:knife][:boo] = false
    assert_equal true, command('--boo').config_value(:boo)
    assert_equal true, command('--boo').config_value(:boo, false)
    assert_equal false, command('--no-boo').config_value(:boo)
    assert_equal false, command('--no-boo').config_value(:boo, true)
  end

  def command(*args)
    knife_command(DummyToolsCommand, *args)
  end
end
