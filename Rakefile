require 'rubygems/package_task'
require 'rake/testtask'

load File.dirname(__FILE__) + '/test/integration/tasks.rake'

require './virtualbox_ext'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
end
task :default => :test

spec = Gem::Specification.load(Dir['*.gemspec'].first)
gem = Gem::PackageTask.new(spec)
gem_file = File.basename(gem.gem_spec.cache_file)
gem_path = File.join(gem.package_dir, gem_file)
gem.define

desc "Push gem to rubygems.org"
task :push => :gem do
  sh "gem push #{gem_path}"
end

desc "Install the gem"
task :install => :gem do
  sh "gem install #{gem_path}"
end

login_options = ["--ssh-user=ubuntu", "--identity-file=#{ENV['HOME']}/.ssh/id_rsa.pub"]
hosts = {
  :test => { :name => "KnifeTest" }
}

VirtualBox.define_rake_tasks(
  :hosts => hosts,
  :image => "#{ENV['HOME']}/Desktop/Not Backed Up/OS/VBox Images/Ubuntu64Base.ova"
)

task :start => 'virtualbox:start'
task :stop => 'virtualbox:stop'
task :info => 'virtualbox:info'

desc 'Prepares the VMs for chef'
task :prepare => 'virtualbox:start' do
  hosts.each do |type, host|
    sh "knife", "prepare", "ubuntu@" + host[:vm].ip_address, "--ssh-password=ubuntu"
  end
end

desc 'Cooks the VMs'
task :cook => hosts.keys.map { |type| "cook:#{type}" }

namespace :cook do
  hosts.each do |type, host|
    desc "Cooks the #{type}"
    task type => :start do
      Dir.chdir 'chef' do
        sh "spatula", "cook", host[:vm].ip_address, "vm#{type}", *login_options
      end
    end
  end
end
