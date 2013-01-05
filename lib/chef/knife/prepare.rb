require 'chef/knife/solo_prepare'
require 'knife-solo/deprecated_command'

class Chef
  class Knife
    class Prepare < SoloPrepare
      include KnifeSolo::DeprecatedCommand
    end
  end
end
