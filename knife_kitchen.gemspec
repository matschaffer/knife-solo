Gem::Specification.new do |s|
  s.name    = 'knife_kitchen'
  s.version = '0.0.1'
  s.summary = 'A collection of knife plugins for dealing with chef solo'
  s.description = 'Handles bootstrapping, running chef solo, rsyncing cookbooks etc'

  s.author   = 'Mat Schaffer'
  s.email    = 'mat@schaffer.me'
  s.homepage = 'https://github.com/matschaffer/knife_kitchen'

  s.add_development_dependency 'mocha'

  s.files = Dir['lib/**/*']

  s.rubyforge_project = 'nowarning'
end
