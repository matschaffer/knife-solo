module KnifeSolo
  module NodeConfigCommand

    def self.load_deps
      require 'pathname'
    end

    def self.included(other)
      other.class_eval do
        # Lazy load our dependencies if the including class did not call
        # Knife#deps yet. See KnifeSolo::SshCommand for more information.
        deps { KnifeSolo::NodeConfigCommand.load_deps } unless @dependency_loader

        option :chef_node_name,
          :short       => '-N NAME',
          :long        => '--node-name NAME',
          :description => 'The Chef node name for your new node'

        option :run_list,
          :short       => '-r RUN_LIST',
          :long        => '--run-list RUN_LIST',
          :description => 'Comma separated list of roles/recipes to put to node config (if it does not exist)',
          :proc        => lambda { |o| o.split(/[\s,]+/) },
          :default     => []

        option :json_attributes,
          :short       => '-j JSON_ATTRIBS',
          :long        => '--json-attributes',
          :description => 'A JSON string to be added to node config (if it does not exist)',
          :proc        => lambda { |o| JSON.parse(o) },
          :default     => nil
      end
    end

    def nodes_path
      'nodes'
    end

    def node_config
      Pathname.new(@name_args[1] || "#{nodes_path}/#{node_name}.json")
    end

    def node_name
      # host method must be defined by the including class
      config[:chef_node_name] || host
    end

    def generate_node_config
      if node_config.exist?
        Chef::Log.debug "Node config '#{node_config}' already exists"
      else
        ui.msg "Generating node config '#{node_config}'..."
        File.open(node_config, 'w') do |f|
          attributes = config[:json_attributes] || config[:first_boot_attributes] || {}
          run_list = { :run_list => config[:run_list] || [] }
          f.print attributes.merge(run_list).to_json
        end
      end
    end

  end
end
