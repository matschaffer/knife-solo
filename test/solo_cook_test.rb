require 'test_helper'
require 'support/kitchen_helper'
require 'support/validation_helper'

require 'berkshelf'
require 'chef/cookbook/chefignore'
require 'chef/knife/solo_cook'
require 'fileutils'
require 'knife-solo/berkshelf'
require 'knife-solo/librarian'
require 'librarian/action/install'

class SuccessfulResult
  def success?
    true
  end
end

class SoloCookTest < TestCase
  include KitchenHelper
  include ValidationHelper::ValidationTests

  def test_chefignore_is_valid_object
    assert_instance_of Chef::Cookbook::Chefignore, command.chefignore
  end

  def test_rsync_exclude_sources_chefignore
    in_kitchen do
      file_to_ignore = "dummy.txt"
      File.open(file_to_ignore, 'w') {|f| f.puts "This file should be ignored"}
      File.open("chefignore", 'w') {|f| f.puts file_to_ignore}
      assert command.rsync_excludes.include?(file_to_ignore), "#{file_to_ignore} should have been excluded"
    end
  end

  def test_expanded_config_paths_returns_empty_array_for_nil
    Chef::Config[:foo] = nil
    assert_equal [], command.expanded_config_paths(:foo)
  end

  def test_expanded_config_paths_returns_pathnames
    Chef::Config[:foo] = ["foo"]
    assert_instance_of Pathname, command.expanded_config_paths(:foo).first
  end

  def test_expanded_config_paths_expands_paths
    Chef::Config[:foo] = ["foo", "/absolute/path"]
    paths = command.expanded_config_paths(:foo)
    assert_equal File.join(Dir.pwd, "foo"), paths[0].to_s
    assert_equal "/absolute/path", paths[1].to_s
  end

  def test_patch_cookbooks_paths_exists
    path = command.patch_cookbooks_path
    refute_nil path, "patch_cookbooks_path should not be nil"
    assert Dir.exist?(path), "patch_cookbooks_path is not a directory"
  end

  def test_cookbook_paths_expands_paths
    cmd = command
    Chef::Config.cookbook_path = ["mycookbooks", "/some/other/path"]
    assert_equal File.join(Dir.pwd, "mycookbooks"), cmd.cookbook_paths[0].to_s
    assert_equal "/some/other/path", cmd.cookbook_paths[1].to_s
  end

  def test_add_cookbook_path_prepends_the_path
    cmd = command
    Chef::Config.cookbook_path = ["mycookbooks", "/some/other/path"]
    cmd.add_cookbook_path "/new/path"
    assert_equal "/new/path", cmd.cookbook_paths[0].to_s
    assert_equal File.join(Dir.pwd, "mycookbooks"), cmd.cookbook_paths[1].to_s
    assert_equal "/some/other/path", cmd.cookbook_paths[2].to_s
  end

  def test_sets_proxy_settings
    Chef::Config[:http_proxy] = "http://proxy:3128"
    Chef::Config[:no_proxy] = nil
    conf = command.proxy_settings
    assert_equal({ :http_proxy => "http://proxy:3128" }, conf)
  end

  def test_adds_patch_cookboks_with_lowest_precedence
   in_kitchen do
      cmd = command("somehost")
      cmd.run
      #note: cookbook_paths are in order of precedence (low->high)
      assert_equal cmd.patch_cookbooks_path, cmd.cookbook_paths[0]
    end 
  end

  def test_does_not_run_berkshelf_if_no_berkfile
    in_kitchen do
      Berkshelf::Berksfile.any_instance.expects(:vendor).never
      command("somehost").run
    end
  end

  def test_runs_berkshelf_if_berkfile_found
    in_kitchen do
      FileUtils.touch "Berksfile"
      Berkshelf::Berksfile.any_instance.expects(:vendor)
      command("somehost").run
    end
  end

  def test_does_not_run_berkshelf_if_denied_by_option
    in_kitchen do
      FileUtils.touch "Berksfile"
      Berkshelf::Berksfile.any_instance.expects(:vendor).never
      command("somehost", "--no-berkshelf").run
    end
  end

  def test_complains_if_berkshelf_gem_missing
    in_kitchen do
      FileUtils.touch "Berksfile"
      cmd = command("somehost")
      cmd.ui.expects(:err).with(regexp_matches(/berkshelf gem/))
      KnifeSolo::Berkshelf.expects(:load_gem).returns(false)
      Berkshelf::Berksfile.any_instance.expects(:vendor).never
      cmd.run
    end
  end

  def test_wont_complain_if_berkshelf_gem_missing_but_no_berkfile
    in_kitchen do
      cmd = command("somehost")
      cmd.ui.expects(:err).never
      KnifeSolo::Berkshelf.expects(:load_gem).never
      Berkshelf::Berksfile.any_instance.expects(:vendor).never
      cmd.run
    end
  end

  def test_adds_berkshelf_path_to_cookbooks
    in_kitchen do
      FileUtils.touch "Berksfile"
      KnifeSolo::Berkshelf.any_instance.stubs(:berkshelf_path).returns("berkshelf/path")
      Berkshelf::Berksfile.any_instance.stubs(:vendor)
      cmd = command("somehost")
      cmd.run
      assert_equal File.join(Dir.pwd, "berkshelf/path"), cmd.cookbook_paths[1].to_s
    end
  end

  def test_does_not_run_librarian_if_no_cheffile
    in_kitchen do
      Librarian::Action::Install.any_instance.expects(:run).never
      command("somehost").run
    end
  end

  def test_runs_librarian_if_cheffile_found
    in_kitchen do
      FileUtils.touch "Cheffile"
      Librarian::Action::Install.any_instance.expects(:run)
      command("somehost").run
    end
  end

  def test_does_not_run_librarian_if_denied_by_option
    in_kitchen do
      FileUtils.touch "Cheffile"
      Librarian::Action::Install.any_instance.expects(:run).never
      command("somehost", "--no-librarian").run
    end
  end

  def test_complains_if_librarian_gem_missing
    in_kitchen do
      FileUtils.touch "Cheffile"
      cmd = command("somehost")
      cmd.ui.expects(:err).with(regexp_matches(/librarian-chef gem/))
      KnifeSolo::Librarian.expects(:load_gem).returns(false)
      Librarian::Action::Install.any_instance.expects(:run).never
      cmd.run
    end
  end

  def test_wont_complain_if_librarian_gem_missing_but_no_cheffile
    in_kitchen do
      cmd = command("somehost")
      cmd.ui.expects(:err).never
      KnifeSolo::Librarian.expects(:load_gem).never
      Librarian::Action::Install.any_instance.expects(:run).never
      cmd.run
    end
  end

  def test_adds_librarian_path_to_cookbooks
    ENV['LIBRARIAN_CHEF_PATH'] = "librarian/path"
    in_kitchen do
      FileUtils.touch "Cheffile"
      Librarian::Action::Install.any_instance.stubs(:run)
      cmd = command("somehost")
      cmd.run
      assert_equal File.join(Dir.pwd, "librarian/path"), cmd.cookbook_paths[1].to_s
    end
  end

  def test_validates_chef_version
    in_kitchen do
      cmd = command("somehost")
      cmd.expects(:check_chef_version)
      cmd.run
    end
  end

  def test_does_not_validate_chef_version_if_denied_by_option
    in_kitchen do
      cmd = command("somehost", "--no-chef-check")
      cmd.expects(:check_chef_version).never
      cmd.run
    end
  end

  def test_accept_valid_chef_version
    in_kitchen do
      cmd = command("somehost")
      cmd.unstub(:check_chef_version)
      cmd.stubs(:chef_version).returns("11.2.0")
      cmd.run
    end
  end

  def test_barks_if_chef_not_found
    in_kitchen do
      cmd = command("somehost")
      cmd.unstub(:check_chef_version)
      cmd.stubs(:chef_version).returns("")
      assert_raises RuntimeError do
        cmd.run
      end
    end
  end

  def test_barks_if_chef_too_old
    in_kitchen do
      cmd = command("somehost")
      cmd.unstub(:check_chef_version)
      cmd.stubs(:chef_version).returns("0.8.0")
      assert_raises RuntimeError do
        cmd.run
      end
    end
  end

  def test_does_not_cook_if_sync_only_specified
    in_kitchen do
      cmd = command("somehost", "--sync-only")
      cmd.expects(:cook).never
      cmd.run
    end
  end

  def test_does_not_sync_if_no_sync_specified
    in_kitchen do
      cmd = command("somehost", "--no-sync")
      cmd.expects(:sync_kitchen).never
      cmd.run
    end
  end

  def test_passes_node_name_to_chef_solo
    assert_chef_solo_option "--node-name=mynode", "-N mynode"
  end

  def test_passes_whyrun_mode_to_chef_solo
    assert_chef_solo_option "--why-run", "-W"
  end

  def test_passes_override_runlist_to_chef_solo
    assert_chef_solo_option "--override-runlist=sandbox::default", "-o sandbox::default"
  end

  # Asserts that the chef_solo_option is passed to chef-solo iff cook_option
  # is specified for the cook command
  def assert_chef_solo_option(cook_option, chef_solo_option)
    matcher = regexp_matches(/\s#{Regexp.quote(chef_solo_option)}(\s|$)/)
    in_kitchen do
      cmd = command("somehost", cook_option)
      cmd.expects(:stream_command).with(matcher).returns(SuccessfulResult.new)
      cmd.run

      cmd = command("somehost")
      cmd.expects(:stream_command).with(Not(matcher)).returns(SuccessfulResult.new)
      cmd.run
    end
  end

  def command(*args)
    cmd = knife_command(Chef::Knife::SoloCook, *args)
    cmd.stubs(:check_chef_version)
    cmd.stubs(:run_portable_mkdir_p)
    cmd.stubs(:rsync)
    cmd.stubs(:stream_command).returns(SuccessfulResult.new)
    cmd
  end
end
