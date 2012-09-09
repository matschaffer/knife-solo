require 'test_helper'

require 'chef/knife/prepare'

class PrepareTest < TestCase
  def setup
    @host = 'somehost@somedomain.com'
  end

  def test_generates_a_node_config
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")

      cmd = command(@host)
      cmd.generate_node_config

      assert cmd.node_config.exist?
    end
  end

  def test_wont_overwrite_node_config
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")

      cmd = command(@host)

      File.open(cmd.node_config, "w") do |f|
        f << "testdata"
      end

      cmd.generate_node_config

      assert_match "testdata", cmd.node_config.read
    end
  end

  def test_will_specify_omnibus_version
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")
      run_command = command(@host, "--omnibus-version", "'0.10.8-3'")
      assert_match "0.10.8-3", run_command.config[:omnibus_version]
    end
  end

  def test_run_raises_if_operating_system_is_not_supported
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")
      run_command = command(@host)
      run_command.stubs(:required_files_present?).returns(true)
      run_command.stubs(:operating_system).returns('MythicalOS')
      assert_raises KnifeSolo::Bootstraps::OperatingSystemNotImplementedError do
        run_command.run
      end
    end
  end

  def test_run_calls_bootstrap
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")
      run_command = command(@host)
      bootstrap_instance = mock('mock OS bootstrap instance')
      run_command.stubs(:required_files_present?).returns(true)
      run_command.stubs(:operating_system).returns('MythicalOS')
      run_command.stubs(:bootstrap).returns(bootstrap_instance)

      bootstrap_instance.expects(:bootstrap!)

      run_command.run
    end
  end

  def test_barks_without_atleast_a_hostname
    @kitchen = '/tmp/nodes'
    Chef::Knife::Kitchen.new([@kitchen]).run

    Dir.chdir(@kitchen) do
      assert_raises Chef::Knife::Prepare::WrongPrepareError do
        suppress_knife_error_output do
          command.run
        end
      end
    end
  end

  def test_host_regex_rejects_invalid_hostnames
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")
      clean_room = Class.new(Object) do
        include KnifeSolo::KitchenCommand
      end
      kitchen_command = clean_room.new
      %w[@name @@name.com name@@ joe@@example.com].each do |invalid|
        kitchen_command.instance_variable_set(:@name_args, [invalid])
        refute kitchen_command.first_cli_arg_is_a_hostname?, "#{invalid} should have been rejected"
      end
    end
  end

  def test_host_regex_accpets_valid_hostnames
    Dir.chdir("/tmp") do
      FileUtils.mkdir("nodes")
      clean_room = Class.new(Object) do
        include KnifeSolo::KitchenCommand
      end
      kitchen_command = clean_room.new
      %w[name.com name joe@example.com].each do |valid|
        kitchen_command.instance_variable_set(:@name_args, [valid])
        assert kitchen_command.first_cli_arg_is_a_hostname?, "#{valid} should have been accepted"
      end
    end
  end

  def teardown
    FileUtils.rm_r("/tmp/nodes")
  end

  def command(*args)
    Chef::Knife::Prepare.load_deps
    command = Chef::Knife::Prepare.new(args)
    command.ui.stubs(:msg)
    command.ui.stubs(:error)
    command
  end
end
