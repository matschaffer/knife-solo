require 'yaml'
require 'fog'

# A custom runner that serves as a common point for EC2 control
class EC2Runner < MiniTest::Unit
  include Loggable

  def initialize
    super
    create_key_pair
  end

  def skip_destroy?
    ENV['SKIP_DESTROY']
  end

  def user
    ENV['USER']
  end

  # Gets a server for the given tests
  # See http://bit.ly/MJRpfQ for information on what filters can be specified.
  def get_server(test)
    server = compute.servers.all("tag-key"             => "name",
                                 "tag-value"           => test.server_name,
                                 "instance-state-name" => "running").first
    if server
      logger.info "Reusing active server tagged #{test.server_name}"
    else
      logger.info "Starting server for #{test.class}..."
      server = compute.servers.create(:tags => {
                                        :name => test.server_name,
                                        :knife_solo_integration_user => ENV['USER']
                                      },
                                      :image_id => test.image_id,
                                      :flavor_id => test.flavor_id,
                                      :key_name => key_name)
    end
    server.wait_for { ready? }
    logger.info "#{test.class} server (#{server.dns_name}) reported ready, trying to connect to ssh..."
    server.wait_for do
      `nc #{public_ip_address} 22 -w 1 -q 0 </dev/null`
      $?.success?
    end
    logger.info "Sleeping 10s to avoid Net::SSH locking up by connecting too early..."
    logger.info "  (if you know a better way, please send me a note at https://github.com/matschaffer/knife-solo)"
    # These may have better ways:
    # http://rubydoc.info/gems/fog/Fog/Compute/AWS/Server:setup
    # http://rubydoc.info/gems/knife-ec2/Chef/Knife/Ec2ServerCreate:tcp_test_ssh
    sleep 10
    server
  end

  # Adds a knife_solo_prepared tag to the server so we can know not to re-prepare it
  def tag_as_prepared(server)
    compute.tags.create(resource_id: server.identity,
                        key:         :knife_solo_prepared,
                        value:       true)
  end

  # Cleans up all the servers tagged as knife solo servers for this user.
  # Specify SKIP_DESTROY environment variable to skip this step and leave servers
  # running for inspection or reuse.
  def run_ec2_cleanup
    servers = compute.servers.all("tag-key"             => "knife_solo_integration_user",
                                  "tag-value"           => user,
                                  "instance-state-name" => "running")
    if skip_destroy?
      puts "\nSKIP_DESTROY specified, leaving #{servers.size} instances running"
    else
      puts <<-TXT.gsub(/^\s*/, '')
          ===
          About to terminate the following instances. Please cancel (Control-C)
          NOW if you want to leave them running. Use SKIP_DESTROY=true to
          skip this step.
      TXT
      servers.each do |server|
        puts "  * #{server.id}"
      end
      sleep 20
      servers.each do |server|
        logger.info "Destroying #{server.public_ip_address}..."
        server.destroy
      end
    end
  end

  # Attempts to create the keypair used for integration testing
  # unless the key file is already present locally.
  def create_key_pair
    return if key_file.exist?
    begin
      key = compute.key_pairs.create(:name => key_name)
      key.write(key_file)
    rescue Fog::Compute::AWS::Error => e
      raise "Unable to create KeyPair 'knife-solo', please create the keypair and save it to #{key_file}"
    end
  end

  def key_name
    config['aws']['key_name']
  end

  def key_file
    $base_dir.join('support', "#{key_name}.pem")
  end

  def config_file
    $base_dir.join('support', 'config.yml')
  end

  def config
    @config ||= YAML.load_file(config_file)
  end

  # Provides a Fog compute resource associated with the
  # AWS account credentials provided in test/support/config.yml
  def compute
    @compute ||= Fog::Compute.new({:provider              => 'AWS',
                                   :aws_access_key_id     => config['aws']['access_key'],
                                   :aws_secret_access_key => config['aws']['secret']})
  end
end
