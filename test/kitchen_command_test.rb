require 'test_helper'
require 'support/kitchen_helper'

require 'chef/knife'
require 'knife-solo/kitchen_command'

class DummyKitchenCommand < Chef::Knife
  include KnifeSolo::KitchenCommand
end

class KitchenCommandTest < TestCase
  include KitchenHelper

  def test_barks_outside_of_the_kitchen
    outside_kitchen do
      assert_raises KnifeSolo::KitchenCommand::OutOfKitchenError do
        command.run
      end
    end
  end

  def test_runs_when_in_a_kitchen
    in_kitchen do
      command.run
    end
  end

  def command(*args)
    knife_command(DummyKitchenCommand, *args)
  end
end
