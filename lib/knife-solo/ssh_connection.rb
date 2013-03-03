require 'net/ssh'

module KnifeSolo
  class SshConnection
    # Custom exception for malformed argument strings
    class ArgumentError < ::ArgumentError; end

    attr_reader :user, :host, :options

    # Creates a new ssh connection.
    # Takes openssh client styled target option as a string '[user@]host' and will select defaults similar to those
    # that openssh client uses.
    #
    # Options:
    #
    #   :user - The user to log in as.
    #   :configfile - The ssh config file to read for options (or uses default location).
    #   :password - The account password to use.
    #   :password_prompter - A callable object that returns the account password.
    #
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

    def password
      return @password unless @password.nil?
      options[:password] || options[:password_prompter].call
    end

    # A string of arguments formatted for use with an openssh client
    def ssh_args
      host_arg = [user, host].compact.join('@')
      config_arg = "-F #{options[:configfile]}" if options[:configfile]
      ident_arg = "-i #{options[:identity_file]}" if options[:identity_file]
      port_arg = "-p #{options[:port]}" if options[:port]

      [host_arg, config_arg, ident_arg, port_arg].compact.join(' ')
    end

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
