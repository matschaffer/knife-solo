require 'test_helper'
require 'knife-solo/tools'

class ToolsTest < TestCase
  include KnifeSolo::Tools

  def test_raises_exception_if_error
    # Cannot mock Kernel.system with mocha
    self.expects(:system).with('mycommand').returns(false)
    assert_raises CommandFailedError, /mycommand/ do
      system! "mycommand"
    end
  end

  def test_does_not_raise_if_system_successful
    self.expects(:system).with('mycommand').returns(true)
    system! 'mycommand'
  end

end
