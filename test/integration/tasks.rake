def prepare(server)
  system "knife prepare "
end

def cook(server)
end

namespace :test do
  AMIS = {
    'Ubuntu 10.04' => { :user => 'ubuntu',
                        :image_id => 'ami-6936fb00' }
  }

  desc "Run integration tests (requires EC2)"
  task :integration do
    require 'bundler'
    Bundler.require(:test)

    compute = Fog::Compute.new({:provider => 'AWS',
                                :aws_access_key_id => ENV['AWS_ACCESS_KEY'],
                                :aws_secret_access_key => ENV['AWS_SECRET_KEY']
                               })
    servers = []
    begin
      AMIS.each do |type, info|
        server = compute.servers.create(info[:image_id] => image_id,
                                        :flavor_id => 'm1.small')
        servers << server
      end
    ensure
      servers.map do |server|
        puts "Destroying #{server}"
        server.destroy
      end
    end

  end
end