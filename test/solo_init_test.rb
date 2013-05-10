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
      command("new_kitchen", "--no-berkshelf").run
      assert !File.exist?("new_kitchen/Berksfile")
    end
  end

  def test_wont_create_cheffile_by_default
    in_kitchen do
      refute File.exist?("Cheffile")
    end
  end

  def test_creates_cheffile_if_specified
    outside_kitchen do
      command("foo", "--librarian").run
      assert File.exist?("foo/Cheffile")
    end
  end

  def test_wont_overwrite_cheffile
    outside_kitchen do
      File.open("Cheffile", "w") do |f|
        f << "testdata"
      end
      command(".", "--librarian").run
      assert_equal "testdata", IO.read("Cheffile")
    end
  end

  def test_gitignores_cookbooks_directory
    outside_kitchen do
      command("bar").run
      assert_equal "/cookbooks/", IO.read("bar/.gitignore").chomp
    end
  end

  def test_wont_create_gitignore_if_denied
    outside_kitchen do
      command(".", "--no-git").run
      refute File.exist?(".gitignore")
    end
  end

  def command(*args)
    knife_command(Chef::Knife::SoloInit, *args)
  end
end
