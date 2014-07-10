require 'test_helper'
require 'support/kitchen_helper'

require 'chef/knife/solo_init'
require 'fileutils'
require 'knife-solo/berkshelf'
require 'knife-solo/librarian'

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

  def test_bootstraps_berkshelf_if_berksfile_found
    outside_kitchen do
      FileUtils.touch "Berksfile"
      KnifeSolo::Berkshelf.any_instance.expects(:bootstrap)
      command(".").run
    end
  end

  def test_wont_bootstrap_berkshelf_if_cheffile_found
    outside_kitchen do
      FileUtils.touch "Cheffile"
      KnifeSolo::Berkshelf.any_instance.expects(:bootstrap).never
      command(".").run
      refute File.exist?("Berksfile")
    end
  end

  def test_wont_create_berksfile_by_default
    outside_kitchen do
      command("new_kitchen").run
      refute File.exist?("new_kitchen/Berksfile")
    end
  end

  def test_creates_berksfile_if_requested
    outside_kitchen do
      cmd = command("new_kitchen", "--berkshelf")
      KnifeSolo::Berkshelf.expects(:load_gem).never
      cmd.run
      assert File.exist?("new_kitchen/Berksfile")
    end
  end

  def test_wont_overwrite_berksfile
    outside_kitchen do
      File.open("Berksfile", "w") do |f|
        f << "testdata"
      end
      command(".", "--berkshelf").run
      assert_equal "testdata", IO.read("Berksfile")
    end
  end

  def test_wont_create_berksfile_if_denied
    outside_kitchen do
      cmd = command("new_kitchen", "--no-berkshelf")
      KnifeSolo::Berkshelf.expects(:load_gem).never
      cmd.run
      refute File.exist?("new_kitchen/Berksfile")
    end
  end

  def test_wont_create_berksfile_if_librarian_requested
    outside_kitchen do
      cmd = command("new_kitchen", "--librarian")
      KnifeSolo::Berkshelf.expects(:load_gem).never
      cmd.run
      refute File.exist?("new_kitchen/Berksfile")
    end
  end

  def test_creates_berksfile_if_gem_installed
    outside_kitchen do
      cmd = command(".")
      KnifeSolo::Berkshelf.expects(:load_gem).returns(true)
      cmd.run
      assert File.exist?("Berksfile")
    end
  end

  def test_wont_create_berksfile_if_gem_missing
    outside_kitchen do
      cmd = command(".")
      KnifeSolo::Berkshelf.expects(:load_gem).raises(LoadError)
      cmd.run
      refute File.exist?("Berksfile")
    end
  end

  def test_bootstraps_librarian_if_cheffile_found
    outside_kitchen do
      FileUtils.touch "Cheffile"
      KnifeSolo::Librarian.any_instance.expects(:bootstrap)
      command(".").run
    end
  end

  def test_wont_bootstrap_librarian_if_berksfile_found
    outside_kitchen do
      FileUtils.touch "Berksfile"
      KnifeSolo::Librarian.any_instance.expects(:bootstrap).never
      command(".").run
      refute File.exist?("Cheffile")
    end
  end

  def test_wont_create_cheffile_by_default
    outside_kitchen do
      command(".").run
      refute File.exist?("Cheffile")
    end
  end

  def test_creates_cheffile_if_requested
    outside_kitchen do
      cmd = command(".", "--librarian")
      KnifeSolo::Librarian.expects(:load_gem).never
      cmd.run
      assert File.exist?("Cheffile")
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

  def test_wont_create_cheffile_if_denied
    outside_kitchen do
      cmd = command("new_kitchen", "--no-librarian")
      KnifeSolo::Librarian.expects(:load_gem).never
      cmd.run
      refute File.exist?("new_kitchen/Cheffile")
    end
  end

  def test_wont_create_cheffile_if_berkshelf_requested
    outside_kitchen do
      cmd = command(".", "--berkshelf")
      KnifeSolo::Librarian.expects(:load_gem).never
      cmd.run
      refute File.exist?("Cheffile")
    end
  end

  def test_creates_cheffile_if_gem_installed
    outside_kitchen do
      cmd = command(".")
      KnifeSolo::Librarian.expects(:load_gem).returns(true)
      cmd.run
      assert File.exist?("Cheffile")
    end
  end

  def test_wont_create_cheffile_if_gem_missing
    outside_kitchen do
      cmd = command(".")
      KnifeSolo::Librarian.expects(:load_gem).raises(LoadError)
      cmd.run
      refute File.exist?("Cheffile")
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
    KnifeSolo::Berkshelf.stubs(:load_gem).raises(LoadError)
    KnifeSolo::Librarian.stubs(:load_gem).raises(LoadError)
    knife_command(Chef::Knife::SoloInit, *args)
  end
end
