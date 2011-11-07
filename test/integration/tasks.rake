KEY_FILE = "#{ENV['HOME']}/.ssh/knife-solo.pem"

class ServerIntegrationTest
  attr_reader :name, :image_id, :user

  def initialize(name, image_id, user)
    @name = name
    @image_id = image_id
    @user = user
  end

  def compute
    @compute ||= Fog::Compute.new({:provider => 'AWS',
                                   :aws_access_key_id => ENV['AWS_ACCESS_KEY'],
                                   :aws_secret_access_key => ENV['AWS_SECRET_KEY'],
                                  })
  end

  def flavor_id
    'm1.small'
  end

  def key_name
    'knife-solo'
  end

  def server_options
    { :image_id => image_id, :flavor_id => flavor_id, :key_name => key_name }
  end

  def server
    @server ||= compute.servers.create(server_options)
  end

  def run
        puts "Starting test run for #{name}..."
        server.wait_for { ready? }
        puts "Server reported ready, trying to connect to ssh..."
        server.wait_for {
          `nc #{server.public_ip_address} 22 -w 1 -q 0 </dev/null`
          $?.success?
        }
        puts "Sleeping 10s to avoid Net::SSH locking up by connecting too early..."
        puts "  (if you know a better way, please send me a note at https://github.com/matschaffer/knife-solo)"
        sleep 10
        prepare
        cook
  end

  def prepare
    system "knife prepare -i #{KEY_FILE} #{user}@#{server.public_ip_address}"
  end

  def cook
    system "knife cook -i #{KEY_FILE} #{user}@#{server.public_ip_address}"
  end

  def cleanup
    puts "Destroying #{name}"
    server.destroy
  end
end

namespace :test do
  KITCHEN = "test/integration/kitchen"
  TESTS = [
    ServerIntegrationTest.new('Ubuntu 10.04', 'ami-6936fb00', 'ubuntu')
  ]

  file KITCHEN do
    system "knife kitchen #{KITCHEN}"
  end

  namespace :integration do
    task :preflight do
      message = StringIO.new
      message.puts " - AWS_ACCESS_KEY environment variable must be set to your AWS access key" unless ENV['AWS_ACCESS_KEY']
      message.puts " - AWS_SECRET_KEY environment variable must be set to your AWS secret key" unless ENV['AWS_SECRET_KEY']
      message.puts " - Create an EC2 keypair called knife-solo and place the private key at #{KEY_FILE}" unless File.exist?(KEY_FILE)
      raise message.string unless message.string.empty?
      File.new(KEY_FILE).chmod(0600)
    end
  end

  desc "Run integration tests (requires EC2)"
  task :integration => ['integration:preflight', 'test/integration/kitchen'] do
    require 'bundler'
    Bundler.require(:test)
    require 'socket'

    begin
      Dir.chdir(KITCHEN) do
        TESTS.each(&:run)
      end
    ensure
      TESTS.each(&:cleanup)
    end
  end
end
