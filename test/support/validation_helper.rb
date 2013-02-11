require 'support/kitchen_helper'

module ValidationHelper

  module SshCommandTests
    include KitchenHelper

    def test_barks_without_atleast_a_hostname
      cmd = command
      cmd.ui.expects(:err).with(regexp_matches(/hostname.*argument/))
      $stdout.stubs(:puts)
      in_kitchen do
        assert_exits cmd
      end
    end
  end

  module KitchenCommandTests
    include KitchenHelper

    # TODO without solo.rb how do we avoid rsyncing outside the kitchen?
    # def test_barks_outside_of_the_kitchen
    #   cmd = default_command
    #   cmd.ui.expects(:err).with(regexp_matches(/must be run inside .* kitchen/))
    #   outside_kitchen do
    #     assert_exits cmd
    #   end
    # end

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
