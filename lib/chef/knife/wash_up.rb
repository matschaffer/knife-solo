require 'chef/knife/solo_clean'
require 'knife-solo/deprecated_command'

class Chef
  class Knife
    class WashUp < SoloClean
      include KnifeSolo::DeprecatedCommand
    end
  end
end
