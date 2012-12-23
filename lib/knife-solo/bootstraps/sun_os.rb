module KnifeSolo::Bootstraps
  class SunOS < Base
    def bootstrap!
      stream_command "sudo pkg install network/rsync web/ca-bundle"
      stream_command "sudo bash -c 'echo ca_certificate=/etc/cacert.pem >> /etc/wgetrc'"
      omnibus_install
    end
  end
end
