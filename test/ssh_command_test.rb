require 'test_helper'

require 'knife-solo/ssh_command'
require 'chef/knife'

class DummySshCommand < Chef::Knife
  include KnifeSolo::SshCommand
end

class SshCommandTest < TestCase
  def test_separates_user_and_host
    assert_equal "ubuntu", command("ubuntu@10.0.0.1").user
    assert_equal "10.0.0.1", command("ubuntu@10.0.0.1").host
  end

  def test_defaults_to_system_user
    ENV['USER'] = "test"
    assert_equal "test", command("10.0.0.1").user
  end

  def test_prompts_for_password_if_not_provided
    cmd = command("10.0.0.1")
    cmd.ui.expects(:ask).returns("testpassword")
    assert_equal "testpassword", cmd.password
  end

  def test_falls_back_to_password_authentication_after_keys
    cmd = command("10.0.0.1", "--ssh-password=test")
    cmd.expects(:try_connection).raises(Net::SSH::AuthenticationFailed)
    assert_equal "test", cmd.authentication_method[:password]
  end

  def test_uses_default_keys_if_conncetion_succeeds
    cmd = command("10.0.0.1")
    cmd.expects(:try_connection)
    assert_equal({}, cmd.authentication_method)
  end

  def test_uses_ssh_config_if_matched
    ssh_config = Pathname.new(__FILE__).dirname.join('support', 'ssh_config')
    cmd = command("10.0.0.1", "--ssh-config-file=#{ssh_config}")
    cmd.expects(:try_connection)

    assert_equal "bob", cmd.authentication_method[:user]
    assert_equal "id_rsa_bob", cmd.authentication_method[:keys].first
    assert_equal "bob", cmd.user
  end

  def test_handles_port_specification
    #TODO (mat): allow port specification on cli
  end

  def test_builds_cli_ssh_args
    cmd = command("10.0.0.1")
    assert_equal "#{ENV['USER']}@10.0.0.1", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--ssh-config-file=myconfig")
    assert_equal "usertest@10.0.0.1 -F myconfig", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--ssh-password=pwtest")
    assert_equal "usertest@10.0.0.1 -P pwtest", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--ssh-identity=my_rsa")
    assert_equal "usertest@10.0.0.1 -i my_rsa", cmd.ssh_args

    cmd = command("usertest@10.0.0.1", "--ssh-port=222")
    assert_equal "usertest@10.0.0.1 -p 222", cmd.ssh_args
  end

  def command(*args)
    DummySshCommand.load_deps
    DummySshCommand.new(args)
  end

end
