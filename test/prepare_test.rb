require 'test_helper'

require 'chef/knife/kitchen'
require 'chef/knife/prepare'
require 'knife-solo/knife_solo_error'

class PrepareTest < TestCase
  def setup
    @host = 'someuser@somehost.domain.com'
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
      assert_raises KnifeSolo::KnifeSoloError do
        command.run
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
