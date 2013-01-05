require 'chef/knife/solo_cook'
require 'knife-solo/deprecated_command'

class Chef
  class Knife
    class Cook < SoloCook
      include KnifeSolo::DeprecatedCommand
    end
  end
end
