require 'test_helper'
require 'chef/knife'
require 'chef/knife/cook'
require 'chef/knife/kitchen'

class CookTest < TestCase

  def test_takes_config_as_second_arg
    cmd = command("host", "nodes/myhost.json")
    assert_equal "nodes/myhost.json", cmd.node_config
  end

  def test_defaults_to_host_name
    cmd = command("host")
    assert_equal "nodes/host.json", cmd.node_config.to_s
  end

  def test_gets_destination_path_from_chef_config
    Chef::Config.file_cache_path "/tmp/chef-solo"
    assert_equal "/tmp/chef-solo", command.chef_path
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

  def setup
    Dir.chdir("/tmp") do
      kitchen("cook_kitchen_test").run
    end
    Dir.chdir("/tmp/cook_kitchen_test") do
      File.open("syntax_error.rb", 'w') do |f|
        f << "this is a blatant ruby syntax error."
      end
    end
  end

  def teardown
    FileUtils.rm_r("/tmp/cook_kitchen_test")
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
