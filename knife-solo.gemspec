# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knife-solo/info'

Gem::Specification.new do |gem|
  gem.name        = 'knife-solo'
  gem.version     = KnifeSolo.version
  gem.author      = ['Mat Schaffer']
  gem.email       = ['mat@schaffer.me']
  gem.summary     = 'A collection of knife plugins for dealing with chef solo'
  gem.description = 'Handles bootstrapping, running chef solo, rsyncing cookbooks etc'
  gem.homepage    = 'https://github.com/matschaffer/knife-solo'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'librarian'

  gem.add_development_dependency 'rspec', '~> 2.11'
  gem.add_development_dependency 'vagrant', '~> 1.0'

  gem.add_dependency 'net-ssh', '~> 2.2'
  gem.add_dependency 'chef',    '>= 0.10.10'
  gem.add_dependency 'json'

  gem.files         = Dir['**/*'].select{|f| File.file?(f)}
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
