require 'test_helper'
require 'pathname'
require 'logger'

MiniTest::Parallel.processor_count = 5

class IntegrationTest < TestCase
  def setup
    @log_file = Pathname.new(__FILE__).dirname.join('..', 'log', "#{self.class}-integration.log")
    @log_file.dirname.mkpath
    @logger = Logger.new(log_file)
  end

  attr_accessor :log_file, :logger

  def cleanup_server
    return if ENV['SKIP_DESTROY']
    logger.info "Destroying #{self.class} (#{server.public_ip_address})..."
    server.destroy
  end

  def key_name
    'knife-solo'
  end

  def key_file
    "#{ENV['HOME']}/.ssh/#{key_name}.pem"
  end

  def flavor_id
    'm1.small'
  end

  def compute
    @compute ||= Fog::Compute.new({:provider              => 'AWS',
                                   :aws_access_key_id     => ENV['AWS_ACCESS_KEY'],
                                   :aws_secret_access_key => ENV['AWS_SECRET_KEY']})
  end

  def server
    return @server if @server
    logger.info "Starting server for #{self.class}..."
    @server = compute.servers.create(:image_id  => image_id,
                                     :flavor_id => flavor_id,
                                     :key_name  => key_name)
    @server.wait_for { ready? }
    logger.info "Server reported ready, trying to connect to ssh..."
    @server.wait_for do
      `nc #{public_ip_address} 22 -w 1 -q 0 </dev/null`
      $?.success?
    end
    logger.info "Sleeping 10s to avoid Net::SSH locking up by connecting too early..."
    logger.info "  (if you know a better way, please send me a note at https://github.com/matschaffer/knife-solo)"
    sleep 10
    @server
  end

  module BasicPrepareAndCook
    def setup
      super
      @kitchen = Pathname.new(__FILE__).dirname.join('kitchens', self.class.to_s)
      system "knife kitchen #{@kitchen} >> #{log_file}"
    end

    def teardown
      FileUtils.remove_entry_secure(@kitchen)
      cleanup_server
    end

    def run_subcommand(subcommand)
      verbose = ENV['VERBOSE'] && "-VV"
      system "knife #{subcommand} -i #{key_file} #{user}@#{server.public_ip_address} #{verbose} >> #{log_file}"
    end

    def test_prepare_and_cook
      Dir.chdir(@kitchen) do
        run_subcommand("prepare")
        assert $?.success?
        run_subcommand("cook")
        assert $?.success?
      end
    end
  end
end
