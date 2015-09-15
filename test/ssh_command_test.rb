require 'test_helper'

require 'knife-solo/ssh_command'
require 'knife-solo/tools'
require 'chef/knife'
require 'net/ssh'

class DummySshCommand < Chef::Knife
  include KnifeSolo::SshCommand
end

class SshCommandTest < TestCase

  def setup
    KnifeSolo::Tools.stubs(:cygwin_client?).returns(false)
  end

  def test_separates_user_and_host
    assert_equal "ubuntu", command("ubuntu@10.0.0.1").user
    assert_equal "10.0.0.1", command("ubuntu@10.0.0.1").host
  end

  def test_defaults_to_system_user
    ENV['USER'] = "test"
    assert_equal "test", command("10.0.0.1").user
  end

  def test_takes_user_from_options
    cmd = command("10.0.0.1", "--ssh-user=test")
    cmd.validate_ssh_options!
    assert_equal "test", cmd.user
  end

  def test_takes_user_as_arg
    cmd = command("test@10.0.0.1", "--ssh-user=ignored")
    cmd.validate_ssh_options!
    assert_equal "test", cmd.user
  end

  def test_host_regex_rejects_invalid_hostnames
    %w[@name @@name.com name@ name@@ joe@@example.com joe@name@example.com].each do |invalid|
      cmd = command(invalid)
      refute cmd.first_cli_arg_is_a_hostname?, "#{invalid} should have been rejected"
    end
  end

  def test_host_regex_accpets_valid_hostnames
    %w[name.com name joe@example.com].each do |valid|
      cmd = command(valid)
      assert cmd.first_cli_arg_is_a_hostname?, "#{valid} should have been accepted"
    end
  end

  def test_prompts_for_password_if_not_provided
    cmd = command("10.0.0.1")
    cmd.ui.expects(:ask).returns("testpassword")
    assert_equal "testpassword", cmd.password
  end

  def test_falls_back_to_password_authentication_after_keys
    cmd = command("10.0.0.1", "--ssh-password=test")
    cmd.expects(:try_connection).raises(Net::SSH::AuthenticationFailed)
    cmd.detect_authentication_method
    assert_equal "test", cmd.connection_options[:password]
  end

  def test_try_connection_without_gateway_connects_using_ssh
    cmd = command("10.0.0.1")
    Net::SSH.expects(:start).with(cmd.host, cmd.user, cmd.connection_options)

    cmd.try_connection
  end

  def test_try_connection_with_gateway_connects_using_ssh_gateway
    cmd = command("10.0.0.1", "--ssh-gateway=user@gateway")
    ssh_mock = mock 'ssh_mock'
    Net::SSH::Gateway.expects(:new).with('gateway', 'user').returns(ssh_mock)
    ssh_mock.expects(:ssh).with(cmd.host, cmd.user, cmd.connection_options.select{|o| o != :gateway})

    Net::SSH.expects(:start).never

    cmd.try_connection
  end

  def test_uses_default_keys_if_conncetion_succeeds
    cmd = command("10.0.0.1")
    assert_equal false, cmd.connection_options[:config]
  end

  def test_uses_ssh_config_if_matched
    ssh_config = Pathname.new(__FILE__).dirname.join('support', 'ssh_config')
    cmd = command("10.0.0.1", "--ssh-config-file=#{ssh_config}")

    assert_equal "bob", cmd.connection_options[:user]
    assert_equal "id_rsa_bob", cmd.connection_options[:keys].first
    assert_equal "bob", cmd.user
    assert_equal false, cmd.connection_options[:config]
  end

  def test_handles_port_specification
    cmd = command("10.0.0.1", "-p", "2222")
    assert_equal "2222", cmd.connection_options[:port]
  end

  def test_handle_startup_script
    cmd = command("10.0.0.1", "--startup-script=~/.bashrc")
    assert_equal "source ~/.bashrc && echo $TEST_PROP",  cmd.processed_command("echo $TEST_PROP")
  end

  def test_handle_no_host_key_verify
    cmd = command("10.0.0.1", "--no-host-key-verify")
    assert_equal false,  cmd.connection_options[:paranoid]
    assert_equal "/dev/null",  cmd.connection_options[:user_known_hosts_file]
  end

  def test_handle_forward_agent
    cmd = command("10.0.0.1", "--forward-agent")
    assert_equal true,  cmd.connection_options[:forward_agent]
  end


  def test_handle_ssh_gateway
    gateway = 'test@host.com'
    cmd = command("10.0.0.1", "--ssh-gateway", gateway)
    assert_equal gateway,  cmd.connection_options[:gateway]
  end

  def test_handle_default_host_key_verify_is_paranoid
    cmd = command("10.0.0.1")
    assert_nil(cmd.connection_options[:paranoid]) # Net:SSH default is :paranoid => true
    assert_nil(cmd.connection_options[:user_known_hosts_file])
  end

  def test_builds_cli_ssh_args
    DummySshCommand.any_instance.stubs(:try_connection)

    cmd = command("10.0.0.1")
    assert_equal "#{ENV['USER']}@10.0.0.1", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--ssh-config-file=myconfig")
    cmd.validate_ssh_options!
    assert_equal "usertest@10.0.0.1 -F myconfig", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--ssh-identity=my_rsa")
    cmd.validate_ssh_options!
    assert_equal "usertest@10.0.0.1 -i my_rsa", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--identity-file=my_rsa")
    cmd.validate_ssh_options!
    assert_equal "usertest@10.0.0.1 -i my_rsa", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--ssh-port=222")
    cmd.validate_ssh_options!
    assert_equal "usertest@10.0.0.1 -p 222", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--no-host-key-verify")
    cmd.validate_ssh_options!
    assert_equal "usertest@10.0.0.1 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--forward-agent")
    cmd.validate_ssh_options!
    assert_equal "usertest@10.0.0.1 -o ForwardAgent=yes", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--ssh-gateway=test@host.com")
    cmd.validate_ssh_options!
    assert_equal "usertest@10.0.0.1", cmd.ssh_args

    cmd = command_internal("usertest@10.0.0.1", "--ssh-gateway=test@host.com")
    cmd.validate_ssh_options!
    assert_equal "usertest@10.0.0.1 -o ControlMaster=auto -o ControlPath=#{cmd.ssh_control_path} -o ControlPersist=3600", cmd.ssh_args
  end

  def test_no_control_master_by_default_in_cygwin
    DummySshCommand.any_instance.stubs(:try_connection)
    DummySshCommand.any_instance.stubs(:ssh_control_path).returns('/path')
    KnifeSolo::Tools.stubs(:cygwin_client?).returns(false)
    cmd = command_internal('usertest@10.0.0.1')
    cmd.validate_ssh_options!
    assert_equal 'usertest@10.0.0.1 -o ControlMaster=auto -o ControlPath=/path -o ControlPersist=3600', cmd.ssh_args

    # if knife-solo runs in cygwin, disable ssh ControlMaster by default
    KnifeSolo::Tools.stubs(:cygwin_client?).returns(true)
    cmd = command_internal('usertest@10.0.0.1')
    cmd.validate_ssh_options!
    assert_equal 'usertest@10.0.0.1', cmd.ssh_args

    KnifeSolo::Tools.stubs(:cygwin_client?).returns(true)
    cmd = command_internal('usertest@10.0.0.1', '--ssh-control-master=auto')
    cmd.validate_ssh_options!
    assert_equal 'usertest@10.0.0.1 -o ControlMaster=auto -o ControlPath=/path -o ControlPersist=3600', cmd.ssh_args
  end

  def test_barks_without_atleast_a_hostname
    cmd = command
    cmd.ui.expects(:fatal).with(regexp_matches(/hostname.*argument/))
    $stdout.stubs(:puts)
    assert_exits { cmd.validate_ssh_options! }
  end

  def test_run_with_fallbacks_returns_first_successful_result
    cmds = sequence("cmds")
    cmd = command
    cmd.expects(:run_command).with("first", {}).returns(result(1, "fail")).in_sequence(cmds)
    cmd.expects(:run_command).with("second", {}).returns(result(0, "w00t")).in_sequence(cmds)
    cmd.expects(:run_command).never

    res = cmd.run_with_fallbacks(["first", "second", "third"])
    assert_equal "w00t", res.stdout
    assert res.success?
  end

  def test_run_with_fallbacks_returns_error_if_all_fail
    cmd = command
    cmd.expects(:run_command).twice.returns(result(64, "fail"))

    res = cmd.run_with_fallbacks(["foo", "bar"])
    assert_equal "", res.stdout
    assert_equal 1, res.exit_code
  end

  def test_handle_ssh_keepalive
    cmd = command("usertest@10.0.0.1", "--ssh-keepalive", '--ssh-keepalive-interval=100')
    cmd.validate_ssh_options!
    assert_equal true, cmd.connection_options[:keepalive]
    assert_equal 100, cmd.connection_options[:keepalive_interval]
  end

  def test_handle_no_ssh_keepalive
    cmd = command("usertest@10.0.0.1", "--no-ssh-keepalive")
    assert_equal nil, cmd.connection_options[:keepalive]
  end

  def test_handle_default_ssh_keepalive_is_true
    cmd = command("usertest@10.0.0.1")
    cmd.validate_ssh_options!
    assert_equal true, cmd.connection_options[:keepalive]
    assert_equal 300, cmd.connection_options[:keepalive_interval]
  end

  def test_barks_if_ssh_keepalive_is_zero
    cmd = command("usertest@10.0.0.1", "--ssh-keepalive-interval=0")
    cmd.ui.expects(:fatal).with(regexp_matches(/--ssh-keepalive-interval.*positive number/))
    $stdout.stubs(:puts)
    assert_exits { cmd.validate_ssh_options! }
  end

  def result(code, stdout = "")
    res = KnifeSolo::SshConnection::ExecResult.new(code)
    res.stdout = stdout
    res
  end

  def command(*args)
    args << '--ssh-control-master=no'
    command_internal(*args)
  end

  def command_internal(*args)
    Net::SSH::Config.stubs(:default_files)
    knife_command(DummySshCommand, *args)
  end
end
