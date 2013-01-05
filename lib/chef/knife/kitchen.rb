require 'chef/knife/solo_init'
require 'knife-solo/deprecated_command'

class Chef
  class Knife
    class Kitchen < SoloInit
      include KnifeSolo::DeprecatedCommand
    end
  end
end
