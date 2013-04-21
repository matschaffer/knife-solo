require 'test_helper'

require 'chef/knife'
require 'knife-solo/deprecated_command'

class DummyNewCommand < Chef::Knife
  banner "knife dummy_new_command"

  option :foo,
    :long        => '--foo',
    :description => 'Foo option'

  def run
    # calls #new_run so we can be sure this gets called
    new_run
  end

  def new_run
    # dummy
  end
end

class DummyDeprecatedCommand < DummyNewCommand
  include KnifeSolo::DeprecatedCommand
end

class DeprecatedCommandTest < TestCase
  def test_help_warns_about_deprecation
    $stdout.expects(:puts).with(regexp_matches(/deprecated!/))
    assert_exits { command("--help") }
  end

  def test_warns_about_deprecation
    cmd = command
    cmd.ui.expects(:err).with(regexp_matches(/deprecated!/))
    cmd.run
  end

  def test_runs_new_command
    cmd = command
    cmd.ui.stubs(:err)
    cmd.expects(:new_run)
    cmd.run
  end

  def test_includes_options_from_new_command
    assert DummyDeprecatedCommand.options.include?(:foo)
  end

  def test_loads_dependencies_from_new_command
    DummyNewCommand.expects(:load_deps)
    DummyDeprecatedCommand.load_deps
  end

  def command(*args)
    DummyDeprecatedCommand.load_deps
    DummyDeprecatedCommand.new(args)
  end
end
