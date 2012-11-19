require 'tmpdir'

require 'chef/knife/kitchen'

module KitchenHelper

  def in_kitchen
    outside_kitchen do
      knife_command(Chef::Knife::Kitchen).run
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
