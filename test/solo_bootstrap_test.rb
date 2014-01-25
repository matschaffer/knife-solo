require 'test_helper'
require 'support/kitchen_helper'
require 'support/validation_helper'

require 'chef/knife/solo_bootstrap'
require 'chef/knife/solo_cook'
require 'chef/knife/solo_prepare'

class SoloBootstrapTest < TestCase
  include KitchenHelper
  include ValidationHelper::ValidationTests

  def test_includes_all_prepare_options
    bootstrap_options = Chef::Knife::SoloBootstrap.options
    Chef::Knife::SoloPrepare.new.options.keys.each do |opt_key|
      assert bootstrap_options.include?(opt_key), "Should support option :#{opt_key}"
    end
  end

  def test_includes_clean_up_cook_option
    assert Chef::Knife::SoloBootstrap.options.include?(:clean_up), "Should support option :clean_up"
  end

  def test_runs_prepare_and_cook
    Chef::Knife::SoloPrepare.any_instance.expects(:run)
    Chef::Knife::SoloCook.any_instance.expects(:run)

    in_kitchen do
      command("somehost").run
    end
  end

  def command(*args)
    knife_command(Chef::Knife::SoloBootstrap, *args)
  end
end
