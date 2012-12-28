require File.join(File.dirname(__FILE__), 'lib', 'knife-solo', 'info')

Gem::Specification.new do |s|
  s.name    = 'knife-solo'
  s.version = KnifeSolo.version
  s.summary = 'A collection of knife plugins for dealing with chef solo'
  s.description = 'Handles bootstrapping, running chef solo, rsyncing cookbooks etc'

  s.author   = 'Mat Schaffer'
  s.email    = 'mat@schaffer.me'
  s.homepage = 'http://matschaffer.github.com/knife-solo/'

  manifest        = File.readlines("Manifest.txt").map(&:chomp)
  s.files         = manifest
  s.executables   = manifest.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = manifest.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'

  s.add_dependency 'chef',    '>= 0.10.10'
  s.add_dependency 'net-ssh', '>= 2.1.3', '< 2.3.0'
  s.add_dependency 'librarian', '~> 0.0.20'
end
