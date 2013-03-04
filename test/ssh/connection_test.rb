require 'test_helper'

require 'knife-solo/ssh/connection'

class SshConnectionTest < TestCase
  def test_separates_user_and_host
    assert_equal "ubuntu", connection("ubuntu@10.0.0.1").user
    assert_equal "10.0.0.1", connection("ubuntu@10.0.0.1").host
  end

  def test_defaults_to_system_user
    ENV['USER'] = "test"
    assert_equal "test", connection("10.0.0.1").user
  end

  def test_defaults_to_localhost
    assert_equal "localhost", connection("user@").host
  end

  def test_config_file_overrides_environment
    ssh_config = File.expand_path('../support/ssh_config', __FILE__)
    ENV['USER'] = "test"
    assert_equal "bob", connection("10.0.0.1", :configfile => ssh_config).user
  end

  def test_user_option_overrides_config_file
    ssh_config = Pathname.new(__FILE__).dirname.join('support', 'ssh_config')
    assert_equal "test", connection("10.0.0.1", :user => "test", :configfile => ssh_config).user
  end

  def test_user_in_argument_overrides_user_option
    assert_equal "test", connection("test@10.0.0.1", :user => "ignored").user
  end

  def test_rejects_invalid_argument_strings
    ["", "@", "@name"].each do |invalid|
      assert_raises KnifeSolo::SSH::Connection::ArgumentError do
        connection(invalid)
      end
    end
  end

  def test_uses_password_prompter_option_if_password_is_not_available
    conn = connection("10.0.0.1", :password_prompter => lambda { 'testpassword' })
    assert_equal "testpassword", conn.password
  end

  def test_builds_openssh_argument_string
    conn = connection("10.0.0.1")
    assert_equal "#{ENV['USER']}@10.0.0.1", conn.ssh_args

    conn = connection("usertest@10.0.0.1", :configfile => 'myconfig')
    assert_equal "usertest@10.0.0.1 -F myconfig", conn.ssh_args

    conn = connection("usertest@10.0.0.1", :identity_file => 'my_rsa')
    assert_equal "usertest@10.0.0.1 -i my_rsa", conn.ssh_args

    conn = connection("usertest@10.0.0.1", :port => '222')
    assert_equal "usertest@10.0.0.1 -p 222", conn.ssh_args
  end

  def test_tries_session_connection_only_once_if_key_is_authorized
    conn = connection('10.0.0.1')
    Net::SSH.expects(:start).with{ |h, u, o| h == conn.host && u = conn.user }.returns(:success)
    assert_equal :success, conn.session
  end

  def test_tries_password_on_session_connection_if_key_fails
    conn = connection('10.0.0.1', :password_prompter => lambda { "prompted password" })
    Net::SSH.expects(:start).with{ |h, u, o| h == conn.host && u = conn.user }.raises(Net::SSH::AuthenticationFailed)
    Net::SSH.expects(:start).with{ |h, u, o| o[:password] == "prompted password" }.returns(:success)
    assert_equal :success, conn.session
  end

  def test_execs_commands_on_the_channel
    conn = connection('10.0.0.1')
    session = mock('session', :open_channel => nil, :loop => nil)
    conn.expects(:session).returns(session).times(2)
    conn.run('echo hello world')
  end

  def connection(*args)
    KnifeSolo::SSH::Connection.new(*args)
  end
end
