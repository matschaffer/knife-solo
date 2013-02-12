require 'test_helper'
require 'knife-solo/config'

class KnifeSoloConfigTest < TestCase
  def setup
    super
    @config = KnifeSolo::Config.new
  end

  def teardown
    super
    FileUtils.rm_f 'solo.rb'
  end

  def test_uses_cookbook_path_from_solo_rb_if_available
    write_file('solo.rb', <<-RUBY)
      knife[:solo_path] = "./custom"
      cookbook_path ["./custom/path"]
    RUBY
    assert_equal "./custom/path", @config.cookbook_path
  end

  def test_reads_chef_root_path_from_knife_config_or_defaults_to_home
    assert_equal './chef-solo', @config.chef_path
    Chef::Config.knife[:solo_path] = "/tmp/custom-chef-solo"
    assert_equal "/tmp/custom-chef-solo", @config.chef_path
  end

  def test_fails_validation_if_user_has_solo_rb_and_no_solo_path
    Chef::Config.knife[:solo_path] = nil
    write_file('solo.rb', <<-RUBY)
        cookbook_path ["custom/path"]
    RUBY
    assert_raises KnifeSolo::Config::Error do
      @config.validate!
    end
  end
end
