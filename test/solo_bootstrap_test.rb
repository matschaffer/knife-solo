require 'test_helper'
require 'support/kitchen_helper'

require 'chef/knife/solo_bootstrap'
require 'chef/knife/solo_cook'
require 'chef/knife/solo_prepare'
require 'knife-solo/knife_solo_error'

class SoloBootstrapTest < TestCase
  include KitchenHelper

  def test_includes_all_prepare_options
    bootstrap_options = Chef::Knife::SoloBootstrap.options
    Chef::Knife::SoloPrepare.new.options.keys.each do |opt_key|
      assert bootstrap_options.include?(opt_key), "Should support option :#{opt_key}"
    end
  end

  def test_runs_prepare_and_cook
    Chef::Knife::SoloPrepare.any_instance.expects(:run)
    Chef::Knife::SoloCook.any_instance.expects(:run)

    in_kitchen do
      command("somehost").run
    end
  end

  def test_barks_without_atleast_a_hostname
    in_kitchen do
      assert_raises KnifeSolo::KnifeSoloError do
        command.run
      end
    end
  end

  def test_barks_outside_of_the_kitchen
    outside_kitchen do
      assert_raises KnifeSolo::KitchenCommand::OutOfKitchenError do
        command("somehost").run
      end
    end
  end

  def command(*args)
    knife_command(Chef::Knife::SoloBootstrap, *args)
  end
end
