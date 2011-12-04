require 'chef/knife'
require 'knife-solo/ssh_command'
require 'knife-solo/kitchen_command'
require 'knife-solo/bootstraps'

class Chef
  class Knife
    # Approach ported from littlechef (https://github.com/tobami/littlechef)
    # Copyright 2010, 2011, Miquel Torres <tobami@googlemail.com>
    class Prepare < Knife
      include KnifeSolo::SshCommand
      include KnifeSolo::KitchenCommand

      banner "knife prepare [user@]hostname (options)"

      def run
        super
        bootstrap.bootstrap!
        generate_node_config
      end

      def bootstrap
        KnifeSolo::Bootstraps.class_for_operating_system(operating_system()).new(self)
      end

      def generate_node_config
        File.open(node_config, 'w') do |f|
          f.print <<-JSON.gsub(/^\s+/, '')
            { "run_list": [] }
          JSON
        end unless node_config.exist?
      end

      def operating_system
        @operating_system ||= begin
                                run_command('uname -s').stdout.strip
                              rescue
                                ""
                              end
      end

    end
  end
end
