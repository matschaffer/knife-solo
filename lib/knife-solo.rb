require 'knife-solo/info'

module KnifeSolo
  def self.resource(name)
    Pathname.new(__FILE__).dirname.join('knife-solo/resources', name)
  end
end
