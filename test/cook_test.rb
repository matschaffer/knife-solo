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

  def test_barks_without_atleast_a_hostname
    in_kitchen do
      assert_raises KnifeSolo::KnifeSoloError do
        command.run
      end
    end
  end

  def command(*args)
    knife_command(Chef::Knife::Cook, *args)
  end
end
