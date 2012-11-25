class TestCase < MiniTest::Unit::TestCase
  def default_test
    super unless self.class == TestCase
  end

  def knife_command(cmd_class, *args)
    cmd_class.load_deps
    command = cmd_class.new(args)
    command.ui.stubs(:msg)
    command.ui.stubs(:err)
    command
  end
end
