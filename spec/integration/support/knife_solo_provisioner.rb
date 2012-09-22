class KnifeSoloProvisioner < Vagrant::Provisioners::Base
  class Config < Vagrant::Config::Base
    attr_accessor :node_config
    attr_accessor :options
    attr_accessor :knife_env

    attr_writer :knife_path
    def knife_path
      @knife_path || 'knife'
    end
  end

  def self.config_class
    Config
  end

  def ssh_info
    env[:vm].ssh.info
  end

  def connection_arguments
    [ "#{ssh_info[:username]}@#{ssh_info[:host]}",
      "-p", ssh_info[:port].to_s,
      "-i", ssh_info[:private_key_path] ]
  end

  def knife(*args)
    arguments = [config.knife_path, args.shift] + connection_arguments + args
    arguments.unshift(config.knife_env) if config.knife_env
    system(*arguments)
    raise "Failed knife command: #{arguments.join(' ')}" unless $?.success?
  end

  def vm
    env[:vm]
  end

  def install_chef
    knife "prepare", config.options
    vm.env.local_data["prepared"] ||= {}
    vm.env.local_data["prepared"][vm.name] = vm.uuid
    vm.env.local_data.commit
  end

  def prepared?
    vm.env.local_data["prepared"] && vm.env.local_data["prepared"][vm.name.to_s] == vm.uuid
  end

  def provision!
    install_chef unless prepared?
    knife "cook", config.node_config, "--skip-syntax-check", config.options
  end
end
