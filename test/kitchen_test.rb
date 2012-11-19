require 'test_helper'
require 'support/kitchen_helper'

require 'chef/knife/kitchen'
require 'knife-solo/knife_solo_error'

class KitchenTest < TestCase
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

  def test_defaults_to_current_directory
    outside_kitchen do
      command.run
      assert File.exist?("solo.rb")
    end
  end

  def test_takes_directory_as_arg
    outside_kitchen do
      command("new_kitchen").run
      assert File.exist?("new_kitchen/nodes")
    end
  end

  def command(*args)
    knife_command(Chef::Knife::Kitchen, *args)
  end
end
