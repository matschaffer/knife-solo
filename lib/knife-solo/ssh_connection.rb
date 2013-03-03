require 'net/ssh'

module KnifeSolo
  class SshConnection
    attr_reader :user, :host, :options

    def initialize(target, options = {})
      @options = options
      @user, @host = parse_connection_target(target)

      set_default_user
      set_default_host
    end

    class ArgumentError < ::ArgumentError; end

    private

    def set_default_user
      @user = @options.fetch(:user, '') if @user.empty?
      @user = ENV.fetch('USER', '') if @user.empty?
    end

    def set_default_host
      @host = 'localhost' if @host.empty?
    end

    def parse_connection_target(target)
      if target.nil? || target.empty? || target[0] == '@'
        raise ArgumentError, 'SSH Target must be [user@]hostname'
      end

      parts = target.rpartition('@')
      [ parts.first, parts.last ]
    end
  end
end
