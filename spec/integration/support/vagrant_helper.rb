module VagrantHelper
  def vagrant_cwd
    File.expand_path("../..", __FILE__)
  end

  def env
    {'VAGRANT_CWD' => vagrant_cwd }
  end

  def vagrant(command, vm)
    system env, "vagrant", command, vm
  end
end

RSpec.configure do |c|
  c.include VagrantHelper

  c.before(:all) do
    vagrant "up", subject
  end

  c.after(:all) do
    vagrant "halt", subject
  end
end
