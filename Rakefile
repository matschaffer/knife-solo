require 'bundler/gem_tasks'
require 'rake/testtask'

desc 'Updates Manifest.txt with a list of files from git'
task :manifest do
  git_files = `git ls-files`.split("\n")
  ignored = %w(.gitignore Gemfile Gemfile.lock Manifest.txt knife-solo.gemspec script/newb script/test)

  File.open('Manifest.txt', 'w') do |f|
    f.puts (git_files - ignored).join("\n")
  end
end

task :release => :manifest

# Returns the parsed RDoc for a single file as HTML
# Somewhat gnarly, but does the job.
def parsed_rdoc file
  options = RDoc::Options.new
  options.template_dir = options.template_dir_for 'darkfish'

  rdoc = RDoc::RDoc.current = RDoc::RDoc.new
  rdoc.options = options
  rdoc.generator = RDoc::Generator::Darkfish.new(options)
  parsed = rdoc.parse_files([file])
  parsed.first.description
end

desc 'Renerates gh-pages from project'
task 'gh-pages' do
  require 'tmpdir'
  gem 'rdoc'; require 'rdoc/rdoc'

  Dir.mktmpdir do |clone|
    sh "git clone -b gh-pages git@github.com:matschaffer/knife-solo.git #{clone}"
    File.open(clone + "/index.html", 'w') do |f|
      f.puts '---'
      f.puts 'layout: default'
      f.puts '---'
      f.puts parsed_rdoc("README.rdoc")
    end
    rev = `git rev-parse HEAD`[0..7]
    Dir.chdir(clone) do
      sh "git commit -m 'Updated index from README.rdoc rev #{rev}' index.html"
      sh "git push origin master"
    end
  end
end

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

