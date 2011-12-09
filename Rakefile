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

desc "Alias for test:units"
task :test => ['test:units']
task :default => :test
