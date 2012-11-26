require 'support/kitchen_helper'
require 'knife-solo/knife_solo_error'
require 'knife-solo/kitchen_command'

module ValidationHelper

  module SshCommandTests
    include KitchenHelper

    def test_barks_without_atleast_a_hostname
      in_kitchen do
        assert_raises KnifeSolo::KnifeSoloError do
          command.run
        end
      end
    end
  end

  module KitchenCommandTests
    include KitchenHelper

    def test_barks_outside_of_the_kitchen
      outside_kitchen do
        assert_raises KnifeSolo::KitchenCommand::OutOfKitchenError do
          default_command.run
        end
      end
    end

    # Returns a Knife instance that shoud run without other validation errors.
    def default_command
      command("somehost")
    end
  end

  module ValidationTests
    include SshCommandTests
    include KitchenCommandTests
  end
end
