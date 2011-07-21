require 'test_helper'
require 'chef/knife'
require 'chef/knife/prepare'

class PrepareTest < TestCase
  def test_separates_user_and_host
    assert_equal "ubuntu", prepare("ubuntu@10.0.0.1").user
    assert_equal "10.0.0.1", prepare("ubuntu@10.0.0.1").host
  end

  def test_defaults_to_system_user
    ENV['USER'] = "test"
    assert_equal "test", prepare("10.0.0.1").user
  end

  def test_prompts_for_password_if_not_provided
    prep = prepare("10.0.0.1")
    prep.ui.expects(:ask).returns("testpassword")
    assert_equal "testpassword", prep.password
  end

  def test_falls_back_to_password_authentication_after_keys
    prep = prepare("10.0.0.1", "--ssh-password=test")
    prep.expects(:try_connection).raises(Net::SSH::AuthenticationFailed)
    assert_equal "test", prep.authentication_method[:password]
  end

  def test_uses_default_keys_if_conncetion_succeeds
    prep = prepare("10.0.0.1")
    prep.expects(:try_connection)
    assert_equal({}, prep.authentication_method)
  end

  def test_uses_ssh_config_if_matched
    ssh_config = Pathname.new(__FILE__).dirname.join('support', 'ssh_config')
    prep = prepare("10.0.0.1", "--ssh-config-file=#{ssh_config}")
    prep.expects(:try_connection)

    assert_equal "bob", prep.authentication_method[:user]
    assert_equal "id_rsa_bob", prep.authentication_method[:keys].first
    assert_equal "bob", prep.user
  end

  def prepare(*args)
    Chef::Knife::Prepare.load_deps
    Chef::Knife::Prepare.new(args)
  end
end
