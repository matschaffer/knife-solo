class KnifeSoloProvisioner < Vagrant::Provisioners::Base
  def ssh_info
    env[:vm].ssh.info
  end

  def connection_arguments
    [ "#{ssh_info[:username]}@#{ssh_info[:host]}",
      "-p", ssh_info[:port].to_s,
      "-i", ssh_info[:private_key_path] ]
  end

  def knife(command)
    arguments = ["knife", command] + connection_arguments
    system *arguments
  end

  def kitchen
    File.expand_path("../..", __FILE__)
  end

  def provision!
    Dir.chdir(kitchen) do
      knife "prepare"
      knife "cook"
    end
  end
end
