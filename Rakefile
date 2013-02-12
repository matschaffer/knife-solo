require 'bundler/gem_tasks'
require 'rake/testtask'
require File.join(File.dirname(__FILE__), 'lib', 'knife-solo', 'info')

MANIFEST_IGNORES = %w[
    .travis.yml
    .gitignore
    Gemfile
    Gemfile.lock
    Manifest.txt
    README.md
    knife-solo.gemspec
    script/newb
    script/test
  ]


namespace :manifest do
  desc 'Checks for outstanding changes to the manifest'
  task :verify => :update do
    changes = `git status --porcelain Manifest.txt`
    raise "Manifest has not been updated" unless changes.empty?
  end

  desc 'Updates Manifest.txt with a list of files from git'
  task :update do
    git_files = `git ls-files`.split("\n")

    File.open('Manifest.txt', 'w') do |f|
      f.puts((git_files - MANIFEST_IGNORES).join("\n"))
    end
  end
end

desc 'Alias to manifest:update'
task :manifest => 'manifest:update'

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
      sh "git commit --allow-empty -m 'Update index for v#{KnifeSolo.version} from README.rdoc rev #{rev}' index.html"
      sh "git push origin gh-pages"
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

  desc 'Run both unit and integration tests'
  task :all => [:units, :integration]
end

desc 'Alias for test:units'
task :test => 'test:units'

task :default => :test
task :default => 'manifest:verify'

task :release => :manifest
task :release => 'gh-pages' unless KnifeSolo.prerelease?
