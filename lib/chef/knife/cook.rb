require 'chef/knife'
require 'chef/config'

require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'

class Chef
  class Knife
    # Approach ported from spatula (https://github.com/trotter/spatula)
    # Copyright 2009, Trotter Cashion
    class Cook < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand

      def run
        super
        rsync_kitchen
        # TODO (mat): syntax check cookbooks and json
        # TODO (mat): set log level based on -V
        stream_command <<-BASH
          sudo chef-solo -c #{chef_path}/solo.rb \
                         -j #{chef_path}/#{node_config}
        BASH
      end

      def node_config
        @name_args[1] || "nodes/#{host}.json"
      end

      def chef_path
        Chef::Config.from_file('solo.rb')
        Chef::Config.file_cache_path
      end

      def rsync_kitchen
        system %Q{rsync -rlP --rsh="ssh #{ssh_args}" --delete --exclude '.*' ./ :#{chef_path}}
      end
    end
  end
end
