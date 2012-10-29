require 'test_helper'
require 'support/kitchen_helper'

require 'chef/knife/solo_kitchen'
require 'knife-solo/knife_solo_error'

class SoloKitchenTest < TestCase
  include KitchenHelper

  def test_produces_folders
    in_kitchen do
      assert File.exist?("nodes")
    end
  end

  def test_produces_gitkeep_in_folders
    in_kitchen do
      assert File.exist?("nodes/.gitkeep")
    end
  end

  def test_barks_without_directory_arg
    assert_raises KnifeSolo::KnifeSoloError do
      command.run
    end
  end

  def test_takes_directory_as_arg
    outside_kitchen do
      command("new_kitchen").run
      assert File.exist?("new_kitchen/nodes")
    end
  end

  def command(*args)
    knife_command(Chef::Knife::SoloKitchen, *args)
  end
end
