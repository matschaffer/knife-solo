require 'test_helper'
require 'support/validation_helper'

require 'chef/knife/solo_clean'

class SoloCleanTest < TestCase
  include ValidationHelper::ValidationTests

  def test_removes_provision_path
    cmd = command('somehost', '--provisioning-path=/foo/bar')
    cmd.expects(:run_command).with('rm -rf /foo/bar').returns(SuccessfulResult.new)
    cmd.run
  end

  def test_removes_provision_path_with_custom_command
    cmd = command('somehost', '--clean-up-command=echo')
    cmd.expects(:run_command).with('echo ~/chef-solo').returns(SuccessfulResult.new)
    cmd.run
  end

  def command(*args)
    knife_command(Chef::Knife::SoloClean, *args)
  end
end
