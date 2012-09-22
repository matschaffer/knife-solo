require 'json'
require 'fileutils'

module VagrantHelper
  def vagrant_cwd
    File.expand_path("../..", __FILE__)
  end

  def vagrant(command, vm)
    log_file = [ "#{subject}.vagrant.log", "a" ]
    env = { "PRE_VAGRANT_GEM_PATH" => ENV["GEM_PATH"] }
    system env, "vagrant", command, vm, out: log_file, err: log_file
    $?.success?
  end

  def config_file
    File.expand_path("../../#{subject}.json", __FILE__)
  end

  def write_config(config)
    File.open(config_file, 'w') do |f|
      f.print(config.to_json)
    end
  end

  def provision(config)
    write_config config
    vagrant "provision", subject
  end
end

RSpec.configure do |c|
  c.include VagrantHelper

  c.before(:all) do
    Dir.chdir(vagrant_cwd)
    system "librarian-chef install"
    write_config run_list: []
    vagrant "up", subject
  end

  c.after(:all) do
    vagrant "halt", subject
    Dir['*.json'].each do |node_json|
      FileUtils.rm node_json
    end
  end
end
