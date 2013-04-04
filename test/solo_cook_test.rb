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
      cmd.expects(:load_librarian).returns(false)
      cmd.ui.expects(:err).with(regexp_matches(/librarian gem/))
      Librarian::Action::Install.any_instance.expects(:run).never
      cmd.run
    end
  end

  def test_wont_complain_if_librarian_gem_missing_but_no_cheffile
    in_kitchen do
      cmd = command("somehost")
      cmd.expects(:load_librarian).never
      cmd.ui.expects(:err).never
      Librarian::Action::Install.any_instance.expects(:run).never
      cmd.run
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

  def test_parses_chef_version_output
    version_string = "\r\nChef: 11.2.0\r\n"
    cmd = command("somehost")
    cmd.stubs(:run_command).returns(OpenStruct.new(:stdout => version_string))
    assert_equal '11.2.0', cmd.chef_version
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
