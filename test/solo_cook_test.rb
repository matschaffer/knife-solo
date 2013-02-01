require 'test_helper'
require 'support/kitchen_helper'
require 'support/validation_helper'

require 'chef/cookbook/chefignore'
require 'chef/knife/solo_cook'
require 'librarian/action/install'

class SuccessfulResult
  def success?
    true
  end
end

class SoloCookTest < TestCase
  include KitchenHelper
  include ValidationHelper::ValidationTests

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
      assert command.rsync_excludes.include?(file_to_ignore), "#{file_to_ignore} should have been excluded"
    end
  end

  def test_does_not_run_librarian_if_no_cheffile
    in_kitchen do
      Librarian::Action::Install.any_instance.expects(:run).never
      command.librarian_install
    end
  end

  def test_runs_librarian_if_cheffile_found
    in_kitchen do
      File.open("Cheffile", 'w') {}
      Librarian::Action::Install.any_instance.expects(:run)
      command.librarian_install
    end
  end

  def test_passes_node_name_to_chef_solo
    assert_chef_solo_option "--node-name=mynode", "-N mynode"
  end

  def test_passes_whyrun_mode_to_chef_solo
    assert_chef_solo_option "--why-run", "-W"
  end

  def test_no_librarian_option
    solo_cook = command("somehost", "--no-librarian")
    solo_cook.expects(:librarian_install).never
    solo_cook.stubs(:validate!)
    Chef::Config.stubs(:from_file)
    solo_cook.stubs(:check_chef_version)
    solo_cook.stubs(:generate_node_config)
    solo_cook.stubs(:rsync_kitchen)
    solo_cook.stubs(:add_patches)
    solo_cook.stubs(:cook)
    solo_cook.run
  end

  # Asserts that the chef_solo_option is passed to chef-solo iff cook_option
  # is specified for the cook command
  def assert_chef_solo_option(cook_option, chef_solo_option)
    matcher = regexp_matches(/\s#{Regexp.quote(chef_solo_option)}(\s|$)/)
    in_kitchen do
      cmd = command("somehost", cook_option)
      cmd.expects(:stream_command).with(matcher).returns(SuccessfulResult.new)
      cmd.cook

      cmd = command("somehost")
      cmd.expects(:stream_command).with(Not(matcher)).returns(SuccessfulResult.new)
      cmd.cook
    end
  end

  def command(*args)
    knife_command(Chef::Knife::SoloCook, *args)
  end
end
