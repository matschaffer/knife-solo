require 'test_helper'
require 'chef/knife'
require 'chef/knife/cook'
require 'chef/knife/kitchen'

class CookTest < TestCase

  def test_node_config_defaults_to_host_name
    cmd = command("someuser@somehost.domain.com")
    assert_equal "nodes/somehost.domain.com.json", cmd.node_config.to_s
  end

  def test_takes_node_config_as_second_arg
    cmd = command("someuser@somehost.domain.com", "nodes/myhost.json")
    assert_equal "nodes/myhost.json", cmd.node_config
  end

  def test_takes_node_config_from_option
    cmd = command("someuser@somehost.domain.com")
    cmd.config[:chef_node_name] = "mynode"
    assert_equal "nodes/mynode.json", cmd.node_config.to_s
  end

  def test_takes_node_config_as_second_arg_even_with_name_option
    cmd = command("someuser@somehost.domain.com", "nodes/myhost.json")
    cmd.config[:chef_node_name] = "mynode"
    assert_equal "nodes/myhost.json", cmd.node_config
  end

  def test_gets_destination_path_from_chef_config
    Chef::Config.file_cache_path "/tmp/chef-solo"
    assert_equal "/tmp/chef-solo", command.chef_path
  end

  def test_gets_patch_path_from_chef_config
    Chef::Config.cookbook_path ["/tmp/chef-solo/cookbooks"]
    assert_equal "/tmp/chef-solo/cookbooks/chef_solo_patches/libraries", command.patch_path
  end

  def test_check_syntax_raises_error
    Dir.chdir("/tmp/cook_kitchen_test") do
      assert File.exist?("syntax_error.rb")
      assert !check_syntax('syntax_error.rb')
      assert_raises RuntimeError do
        command.check_syntax
      end
    end
  end

  def test_chefignore_is_valid_object
    assert_instance_of Chef::Cookbook::Chefignore, command.chefignore
  end

  def test_check_syntax_ignores_files_in_chefignore
    Dir.chdir("/tmp/cook_kitchen_test") do
      assert File.exist?("syntax_error.rb")
      assert !check_syntax('syntax_error.rb')

      assert_raises RuntimeError do
        command.check_syntax
      end

      File.open("chefignore", 'w') do |f|
        f << "syntax_error.rb"
      end

      command.check_syntax
    end
  end

  def test_rsync_exclude_sources_chefignore
    Dir.chdir("/tmp/cook_kitchen_test") do
      assert File.exist?("syntax_error.rb")
      File.open("chefignore", 'w') do |f|
        f << "syntax_error.rb"
      end
      assert command.rsync_exclude.include?("syntax_error.rb")
    end
  end

  def test_barks_without_atleast_a_hostname
    kitchen(@clean_kitchen).run

    Dir.chdir(@clean_kitchen) do
      suppress_knife_error_output do
        assert_raises Chef::Knife::Cook::WrongCookError do
          command.run
        end
      end
    end
  end

  def setup
    Dir.chdir("/tmp") do
      kitchen("cook_kitchen_test").run
    end
    Dir.chdir("/tmp/cook_kitchen_test") do
      File.open("syntax_error.rb", 'w') do |f|
        f << "this is a blatant ruby syntax error."
      end
    end
    @clean_kitchen = '/tmp/kitchen'
  end

  def teardown
    FileUtils.rm_r("/tmp/cook_kitchen_test")
    FileUtils.rm_rf(@clean_kitchen)
  end

  def command(*args)
    command = Chef::Knife::Cook.new(args)
    command.ui.stubs(:msg)
    command
  end

  def kitchen(*args)
    Chef::Knife::Kitchen.load_deps
    Chef::Knife::Kitchen.new(args)
  end

  def check_syntax(file)
    `ruby -c #{file} >/dev/null 2>&1 && echo 'true'`.strip == 'true'
  end


end
