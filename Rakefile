require 'bundler/gem_tasks'
require 'rake/testtask'

namespace :test do
  Rake::TestTask.new(:integration) do |t|
    t.libs << "test"
    t.test_files = FileList['test/integration/*_test.rb']
  end

  Rake::TestTask.new(:units) do |t|
    t.libs << "test"
    t.test_files = FileList['test/*_test.rb']
  end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec
