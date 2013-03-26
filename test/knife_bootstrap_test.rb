require 'test_helper'
require 'support/kitchen_helper'

require 'chef/knife/bootstrap_solo'
require 'chef/knife/solo_bootstrap'

class KnifeBootstrapTest < TestCase
  include KitchenHelper

  def test_includes_solo_options
    assert Chef::Knife::Bootstrap.options.include?(:solo)
  end

  def test_runs_solo_bootstrap_if_specified_as_option
    Chef::Config.knife[:solo] = false
    Chef::Knife::SoloBootstrap.any_instance.expects(:run)
    Chef::Knife::Bootstrap.any_instance.expects(:orig_run).never
    in_kitchen do
      command("somehost", "--solo").run
    end
  end

  def test_runs_solo_bootstrap_if_specified_as_chef_configuration
    Chef::Config.knife[:solo] = true
    Chef::Knife::SoloBootstrap.any_instance.expects(:run)
    Chef::Knife::Bootstrap.any_instance.expects(:orig_run).never
    in_kitchen do
      command("somehost").run
    end
  end

  def test_runs_original_bootstrap_by_default
    Chef::Config.knife[:solo] = false
    Chef::Knife::SoloBootstrap.any_instance.expects(:run).never
    Chef::Knife::Bootstrap.any_instance.expects(:orig_run)
    in_kitchen do
      command("somehost").run
    end
  end

  def test_runs_original_bootstrap_if_specified_as_option
    Chef::Config.knife[:solo] = true
    Chef::Knife::SoloBootstrap.any_instance.expects(:run).never
    Chef::Knife::Bootstrap.any_instance.expects(:orig_run)
    in_kitchen do
      command("somehost", "--no-solo").run
    end
  end

  def test_barks_without_atleast_a_hostname
    cmd = command("--solo")
    cmd.ui.expects(:err)
    in_kitchen do
      assert_exits cmd
    end
  end

  def command(*args)
    knife_command(Chef::Knife::Bootstrap, *args)
  end
end
