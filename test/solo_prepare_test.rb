require 'test_helper'
require 'support/kitchen_helper'
require 'support/validation_helper'

require 'chef/knife/solo_prepare'

class SoloPrepareTest < TestCase
  include KitchenHelper
  include ValidationHelper::ValidationTests

  def setup
    @host = 'someuser@somehost.domain.com'
  end

  def test_uses_local_chef_version_by_default
    Chef::Config[:knife][:bootstrap_version] = nil
    assert_equal Chef::VERSION, command.chef_version
  end

  def test_uses_chef_version_from_knife_config
    Chef::Config[:knife][:bootstrap_version] = "10.12.2"
    assert_equal "10.12.2", command.chef_version
  end

  def test_uses_chef_version_from_command_line_option
    Chef::Config[:knife][:bootstrap_version] = "10.16.2"
    assert_equal "0.4.2", command("--bootstrap-version", "0.4.2").chef_version
  end

  def test_chef_version_returns_nil_if_empty
    Chef::Config[:knife][:bootstrap_version] = "10.12.2"
    assert_nil command("--bootstrap-version", "").chef_version
  end

  def test_run_raises_if_operating_system_is_not_supported
    in_kitchen do
      run_command = command(@host)
      run_command.stubs(:operating_system).returns('MythicalOS')
      assert_raises KnifeSolo::Bootstraps::OperatingSystemNotImplementedError do
        run_command.run
      end
    end
  end

  def test_run_calls_bootstrap
    in_kitchen do
      bootstrap_instance = mock('mock OS bootstrap instance')
      bootstrap_instance.expects(:bootstrap!)

      run_command = command(@host)
      run_command.stubs(:bootstrap).returns(bootstrap_instance)
      run_command.run
    end
  end

  def command(*args)
    knife_command(Chef::Knife::SoloPrepare, *args)
  end
end
