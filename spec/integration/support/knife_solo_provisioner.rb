class KnifeSoloProvisioner < Vagrant::Provisioners::Base
  def ssh_info
    env[:vm].ssh.info
  end

  def provision!
    Dir.chdir(ENV['VAGRANT_CWD']) do
      system "knife", "prepare",
        "#{ssh_info[:username]}@#{ssh_info[:host]}",
        "-p", ssh_info[:port].to_s,
        "-i", ssh_info[:private_key_path]
    end
  end
end
