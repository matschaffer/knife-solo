require 'support/kitchen_helper'

module ValidationHelper

  module SshCommandTests
    include KitchenHelper

    def test_barks_without_atleast_a_hostname
      cmd = command
      cmd.ui.expects(:fatal).with(regexp_matches(/hostname.*argument/))
      $stdout.stubs(:puts)
      in_kitchen do
        assert_exits cmd
      end
    end
  end

  module ValidationTests
    include SshCommandTests
  end
end
