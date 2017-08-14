require 'test_helper'
require 'support/validation_helper'

require 'chef/knife/solo_clean'

class SoloCleanTest < TestCase
  include ValidationHelper::ValidationTests

  def test_removes_provision_path
    cmd = command('somehost', '--provisioning-path=/foo/bar')
    cmd.expects(:run_command).with('sudo rm -rf /foo/bar').returns(SuccessfulResult.new)
    cmd.run
  end

  def test_removes_with_custom_sudo
    cmd = command('somehost', '--sudo-command=/usr/some/sudo')
    cmd.expects(:run_command).with('/usr/some/sudo rm -rf ~/chef-solo').returns(SuccessfulResult.new)
    cmd.run
  end

  def command(*args)
    knife_command(Chef::Knife::SoloClean, *args)
  end
end
