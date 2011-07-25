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

      banner "knife prepare [user@]hostname [json] (options)"

      def run
        super

        check_syntax

        rsync_kitchen

        logging_arg = "-l debug" if config[:verbosity] > 0
        stream_command <<-BASH
          sudo chef-solo -c #{chef_path}/solo.rb \
                         -j #{chef_path}/#{node_config} \
                         #{logging_arg}
        BASH
      end

      def check_syntax
        Dir["**/*.rb"].each do |recipe|
          ok = system "ruby -c #{recipe} >/dev/null 2>&1"
          raise "Syntax error in #{recipe}" if not ok
        end

        Dir["**/*.json"].each do |json|
          begin
            require 'json'
            # parse without instantiating Chef classes
            JSON.parse File.read(json), :create_additions => false
          rescue => error
            raise "Syntax error in #{json}: #{error.message}"
          end
        end
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
