require 'test_helper'
require 'support/kitchen_helper'

require 'chef/knife'
require 'knife-solo/kitchen_command'

class DummyKitchenCommand < Chef::Knife
  include KnifeSolo::KitchenCommand
end

class KitchenCommandTest < TestCase
  include KitchenHelper

  # TODO without solo.rb how do we avoid rsyncing outside the kitchen?
  # def test_barks_outside_of_the_kitchen
  #   cmd = command
  #   cmd.ui.expects(:err).with(regexp_matches(/must be run inside .* kitchen/))
  #   outside_kitchen do
  #     assert_exits { cmd.validate_kitchen! }
  #   end
  # end

  def test_runs_when_in_a_kitchen
    in_kitchen do
      command.validate_kitchen!
    end
  end

  def command(*args)
    knife_command(DummyKitchenCommand, *args)
  end
end
