# Normally this gets loaded by the knife application
# but we'll require it here so we can test commands directly without getting constant missing errors.
# See https://github.com/chef/chef/pull/4153 for updates
require 'chef/mixin/shell_out'

class TestCase < MiniTest::Unit::TestCase
  def default_test
    super unless self.class == TestCase
  end

  def write_file(file, contents)
    FileUtils.mkpath(File.dirname(file))
    File.open(file, 'w') { |f| f.print contents }
  end

  def knife_command(cmd_class, *args)
    cmd_class.load_deps
    command = cmd_class.new(args)
    command.ui.stubs(:msg)
    command.ui.stubs(:warn)
    Chef::Config[:verbosity] = 0
    command.config[:config_file] = "#{File.dirname(__FILE__)}/knife.rb"
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
