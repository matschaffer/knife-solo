require 'test_helper'
require 'knife-solo/tools'

class ToolsTest < TestCase
  include KnifeSolo::Tools

  def test_raises_exception_if_error
    assert_raises CommandFailedError, /funky/ do
      system! "funkynonexistingcommand"
    end
  end
end
