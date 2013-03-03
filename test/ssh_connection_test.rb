require 'test_helper'

require 'knife-solo/ssh_connection'

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
      assert_raises KnifeSolo::SshConnection::ArgumentError do
        connection(invalid)
      end
    end
  end

  def connection(*args)
    KnifeSolo::SshConnection.new(*args)
  end
end
