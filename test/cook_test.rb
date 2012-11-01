require 'test_helper'
require 'support/kitchen_helper'

require 'chef/cookbook/chefignore'
require 'chef/knife'
require 'chef/knife/cook'
require 'knife-solo/knife_solo_error'

class CookTest < TestCase
  include KitchenHelper

  def test_gets_destination_path_from_chef_config
    Chef::Config.file_cache_path "/tmp/chef-solo"
    assert_equal "/tmp/chef-solo", command.chef_path
  end

  def test_gets_patch_path_from_chef_config
    Chef::Config.cookbook_path ["/tmp/chef-solo/cookbooks"]
    assert_equal "/tmp/chef-solo/cookbooks/chef_solo_patches/libraries", command.patch_path
  end

  def test_chefignore_is_valid_object
    assert_instance_of Chef::Cookbook::Chefignore, command.chefignore
  end

  def test_rsync_exclude_sources_chefignore
    in_kitchen do
      file_to_ignore = "dummy.txt"
      File.open(file_to_ignore, 'w') {|f| f.puts "This file should be ignored"}
      File.open("chefignore", 'w') {|f| f.puts file_to_ignore}
      assert command.rsync_exclude.include?(file_to_ignore), "#{file_to_ignore} should have been excluded"
    end
  end

  def test_barks_without_atleast_a_hostname
    in_kitchen do
      assert_raises KnifeSolo::KnifeSoloError do
        command.run
      end
    end
  end

  def test_passes_node_name_to_chef_solo
    assert_chef_solo_option "--node-name=mynode", "-N mynode"
  end

  def test_passes_whyrun_mode_to_chef_solo
    assert_chef_solo_option "--why-run", "-W"
  end

  # Asserts that the chef_solo_option is passed to chef-solo iff cook_option
  # is specified for the cook command
  def assert_chef_solo_option(cook_option, chef_solo_option)
    matcher = regexp_matches(/\s#{Regexp.quote(chef_solo_option)}(\s|$)/)
    in_kitchen do
      cmd = command("somehost", cook_option)
      cmd.expects(:stream_command).with(matcher)
      cmd.cook

      cmd = command("somehost")
      cmd.expects(:stream_command).with(Not(matcher))
      cmd.cook
    end
  end

  def command(*args)
    knife_command(Chef::Knife::Cook, *args)
  end
end
