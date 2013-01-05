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

  def test_will_specify_omnibus_version
    in_kitchen do
      run_command = command(@host, "--omnibus-version", "'0.10.8-3'")
      assert_match "0.10.8-3", run_command.config[:omnibus_version]
    end
  end

  def test_run_raises_if_operating_system_is_not_supported
    in_kitchen do
      run_command = command(@host)
      run_command.stubs(:required_files_present?).returns(true)
      run_command.stubs(:operating_system).returns('MythicalOS')
      assert_raises KnifeSolo::Bootstraps::OperatingSystemNotImplementedError do
        run_command.run
      end
    end
  end

  def test_run_calls_bootstrap
    in_kitchen do
      run_command = command(@host)
      bootstrap_instance = mock('mock OS bootstrap instance')
      run_command.stubs(:required_files_present?).returns(true)
      run_command.stubs(:operating_system).returns('MythicalOS')
      run_command.stubs(:bootstrap).returns(bootstrap_instance)

      bootstrap_instance.expects(:bootstrap!)

      run_command.run
    end
  end

  def command(*args)
    knife_command(Chef::Knife::SoloPrepare, *args)
  end
end
