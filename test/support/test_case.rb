class TestCase < MiniTest::Unit::TestCase
  def default_test
    super unless self.class == TestCase
  end

  def suppress_knife_error_output(knife_command)
    knife_command.ui.stderr.reopen("/dev/null")
  end
end
