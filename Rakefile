require 'rubygems/package_task'
require 'rake/testtask'

load File.dirname(__FILE__) + '/test/integration/tasks.rake'

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