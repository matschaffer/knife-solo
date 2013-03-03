require 'net/ssh'

module KnifeSolo
  class SshConnection
    attr_reader :user, :host, :options

    def initialize(target, options = {})
      @options = options
      @user, @host = parse_connection_target(target)
    end

    def host
      return @host unless @host.nil?
      @host = 'localhost'
    end

    def user
      return @user unless @user.nil?
      @user = options[:user] || config_file_options[:user] || ENV['USER'] || 'root'
    end

    class ArgumentError < ::ArgumentError; end

    private

    def config_files
      Array(options[:configfile]) + Net::SSH::Config.default_files
    end

    def config_file_options
      Net::SSH::Config.for(host, config_files)
    end

    def parse_connection_target(target)
      if target.nil? || target.empty? || target[0] == '@'
        raise ArgumentError, 'SSH Target must be [user@]hostname'
      end

      parts = target.rpartition('@')
      user = parts.first unless parts.first.empty?
      host = parts.last unless parts.last.empty?
      [ user, host ]
    end
  end
end
