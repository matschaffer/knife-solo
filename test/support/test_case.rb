class TestCase < MiniTest::Unit::TestCase
  def default_test
    super unless self.class == TestCase
  end

  def knife_command(cmd_class, *args)
    cmd_class.load_deps
    command = cmd_class.new(args)
    command.ui.stubs(:msg)
    command.ui.stubs(:err)
    Chef::Config[:verbosity] = 0
    command.configure_chef
    command
  end

  # Assert that the specified command or block raises SystemExit
  def assert_exits(command = nil)
    assert_raises SystemExit do
      if command
        command.run
      else
        yield
      end
    end
  end
end
