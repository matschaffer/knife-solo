require 'test_helper'
require 'support/kitchen_helper'

require 'chef/knife/solo_init'

class SoloInitTest < TestCase
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
    cmd = command
    cmd.ui.expects(:err).with(regexp_matches(/You must specify a directory/))
    $stdout.stubs(:puts)
    outside_kitchen do
      assert_exits cmd
    end
  end

  def test_takes_directory_as_arg
    outside_kitchen do
      command("new_kitchen").run
      assert File.exist?("new_kitchen/nodes")
    end
  end

  def test_creates_berksfile
    outside_kitchen do
      command("new_kitchen").run
      assert File.exist?("new_kitchen/Berksfile")
    end
  end

  def test_skips_berksfile_creation_if_given_option
    outside_kitchen do
      command("new_kitchen", "--skip-berkshelf").run
      assert !File.exist?("new_kitchen/Berksfile")
    end
  end

  def command(*args)
    knife_command(Chef::Knife::SoloInit, *args)
  end
end
