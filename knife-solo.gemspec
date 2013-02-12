require File.join(File.dirname(__FILE__), 'lib', 'knife-solo', 'info')

chef_version = ['>= 10.12']
unless ENV['CHEF_VERSION'].to_s.empty?
  chef_version = Gem::Requirement.new(ENV['CHEF_VERSION'])
end

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

   s.post_install_message = KnifeSolo.post_install_message

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'fog'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'parallel'

  s.add_dependency 'chef',     chef_version
  s.add_dependency 'net-ssh',  '>= 2.2.2', '< 3.0'
  s.add_dependency 'librarian', '~> 0.0.20'
end
