require 'json'

module VagrantHelper
  def vagrant_cwd
    File.expand_path("../..", __FILE__)
  end

  def vagrant(command, vm)
    system "vagrant", command, vm
  end

  def config
    File.expand_path("../#{subject}.json", __FILE__)
  end

  def provision(config)
    File.open(config, 'w+') do |f|
      f.print(config.to_json)
    end
    vagrant "provision", subject
  end
end

RSpec.configure do |c|
  c.include VagrantHelper

  c.before(:all) do
    Dir.chdir(vagrant_cwd)
    system "librarian-chef install"
    vagrant "up", subject
  end

  c.after(:all) do
    vagrant "halt", subject
  end
end
