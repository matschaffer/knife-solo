require File.join(File.dirname(__FILE__), 'lib', 'knife-solo', 'info')

Gem::Specification.new do |s|
  s.name    = 'knife-solo'
  s.version = KnifeSolo.version
  s.summary = 'A collection of knife plugins for dealing with chef solo'
  s.description = 'Handles bootstrapping, running chef solo, rsyncing cookbooks etc'

  s.author   = 'Mat Schaffer'
  s.email    = 'mat@schaffer.me'
  s.homepage = 'http://matschaffer.github.io/knife-solo/'

  manifest        = File.readlines("Manifest.txt").map(&:chomp)
  s.files         = manifest
  s.executables   = manifest.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = manifest.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.post_install_message = KnifeSolo.post_install_message

  s.add_development_dependency 'berkshelf', '>= 3.0.0.beta.2'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'ffi', '< 1.9.1' # transitional dependency of berkshelf
  s.add_development_dependency 'fog'
  s.add_development_dependency 'librarian-chef'
  s.add_development_dependency 'minitest', '~> 4.7'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'parallel'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc', '~> 3.12'
  s.add_development_dependency 'coveralls'

  s.add_dependency 'chef',     '>= 10.20'
  s.add_dependency 'net-ssh',  '~> 2.7', '< 3.0'
  s.add_dependency 'erubis',   '~> 2.7.0'
end
