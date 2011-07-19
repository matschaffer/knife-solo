require 'rubygems/package_task'
require './virtualbox_ext'

spec = Gem::Specification.load(Dir['*.gemspec'].first)
gem = Gem::PackageTask.new(spec)
gem.define

desc "Push gem to rubygems.org"
task :push => :gem do
  sh "gem push #{gem.package_dir}/#{gem.gem_file}"
end

desc "Install the gem"
task :install => :gem do
  sh "gem install #{gem.package_dir}/#{gem.gem_file}"
end

login_options = ["--ssh-user=ubuntu", "--identity-file=#{ENV['HOME']}/.ssh/id_rsa.pub"]
hosts = {
  :test => { :name => "KnifeTest" }
}

VirtualBox.define_rake_tasks(
  :hosts => hosts,
  :image => "#{ENV['HOME']}/Desktop/Not Backed Up/OS/VBox Images/Ubuntu64Base.ova"
)

desc 'Prepares the VMs for chef'
task :prepare => 'virtualbox:start' do
  hosts.each do |type, host|
    sh "knife", "prepare", "ubuntu@" + host[:vm].ip_address, "--password=ubuntu"
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
