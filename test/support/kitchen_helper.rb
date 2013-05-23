require 'tmpdir'

require 'chef/knife/solo_init'

module KitchenHelper

  def in_kitchen
    outside_kitchen do
      knife_command(Chef::Knife::SoloInit, ".", "--no-berkshelf", "--no-librarian").run
      yield
    end
  end

  def outside_kitchen
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield
      end
    end
  end

end
