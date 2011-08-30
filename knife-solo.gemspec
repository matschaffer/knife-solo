require File.join(File.dirname(__FILE__), 'lib', 'knife-solo', 'info')

Gem::Specification.new do |s|
  s.name    = 'knife-solo'
  s.version = KnifeSolo.version
  s.summary = 'A collection of knife plugins for dealing with chef solo'
  s.description = 'Handles bootstrapping, running chef solo, rsyncing cookbooks etc'

  s.author   = 'Mat Schaffer'
  s.email    = 'mat@schaffer.me'
  s.homepage = 'https://github.com/matschaffer/knife-solo'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'virtualbox'

  s.add_dependency 'chef',    '~> 0.10.0'
  s.add_dependency 'net-ssh', '~> 2.1.3'

  s.files = Dir['lib/**/*']

  s.rubyforge_project = 'nowarning'
end
