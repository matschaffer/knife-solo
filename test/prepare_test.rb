require 'test_helper'

require 'chef/knife/prepare'

class PrepareTest < TestCase
  def test_generates_a_node_config
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")

      cmd = command("somehost")
      cmd.generate_node_config

      assert cmd.node_config.exist?
    end
  end

  def test_wont_overwrite_node_config
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")

      cmd = command("somehost")

      File.open(cmd.node_config, "w") do |f|
        f << "testdata"
      end

      cmd.generate_node_config

      assert_match "testdata", cmd.node_config.read
    end
  end

  def test_run_raises_if_operating_system_is_not_supported
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")
      run_command = command("somehost")
      run_command.stubs(:required_files_present?).returns(true)
      run_command.stubs(:operating_system).returns('MythicalOS')
      assert_raise KnifeSolo::Bootstraps::OperatingSystemNotImplementedError do
        run_command.run
      end
    end
  end

  def test_run_calls_bootstrap
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")
      run_command = command("somehost")
      bootstrap_instance = mock('mock OS bootstrap instance')
      run_command.stubs(:required_files_present?).returns(true)
      run_command.stubs(:operating_system).returns('MythicalOS')
      run_command.stubs(:bootstrap).returns(bootstrap_instance)

      bootstrap_instance.expects(:bootstrap!)

      run_command.run
    end
  end

  def teardown
    FileUtils.rm_r("/tmp/nodes")
  end

  def command(*args)
    Chef::Knife::Prepare.load_deps
    Chef::Knife::Prepare.new(args)
  end
end
