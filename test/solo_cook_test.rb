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
      File.open("Cheffile", 'w') {}
      Librarian::Action::Install.any_instance.expects(:run)
      command("somehost").run
    end
  end

  def test_does_not_run_librarian_if_denied_by_option
    in_kitchen do
      File.open("Cheffile", 'w') {}
      Librarian::Action::Install.any_instance.expects(:run).never
      command("somehost", "--no-librarian").run
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

  def test_uses_cookbook_path_from_solo_rb_if_available
    in_kitchen do
      cmd = command("somehost")
      write_file('solo.rb', <<-RUBY)
        knife[:solo_path] = "./custom"
        cookbook_path ["./custom/path"]
      RUBY
      assert_equal "./custom/path", cmd.cookbook_path
    end
  end

  def test_reads_chef_root_path_from_knife_config_or_defaults_to_home
    in_kitchen do
      cmd = command("somehost")
      assert_equal './chef-solo', cmd.chef_path
      Chef::Config.knife[:solo_path] = "/tmp/custom-chef-solo"
      assert_equal "/tmp/custom-chef-solo", cmd.chef_path
    end
  end

  def test_errors_if_user_has_solo_rb_and_no_solo_path
    in_kitchen do
      cmd = command("somehost")
      Chef::Config.knife[:solo_path] = nil
      write_file('solo.rb', <<-RUBY)
        cookbook_path ["custom/path"]
      RUBY
      assert_raises KnifeSolo::BadConfigError do
        cmd.run
      end
    end
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

  def write_file(file, contents)
    FileUtils.mkpath(File.dirname(file))
    File.open(file, 'w') { |f| f.print contents }
  end

  def command(*args)
    cmd = knife_command(Chef::Knife::SoloCook, *args)
    cmd.stubs(:check_chef_version)
    cmd.stubs(:add_patches)
    cmd.stubs(:rsync)
    cmd.stubs(:stream_command).returns(SuccessfulResult.new)
    cmd
  end
end
