require 'test_helper'
require 'knife-solo/tools'

class ToolsTest < TestCase
  include KnifeSolo::Tools

  def test_raises_exception_if_error
    assert_raises CommandFailedError, /funky/ do
      system! "funkynonexistingcommand"
    end
  end

  def test_does_not_raise_if_system_successful
    # Cannot mock Kernel.system with mocha
    self.expects(:system).with('mycommand').returns(true)
    system! 'mycommand'
  end

end
