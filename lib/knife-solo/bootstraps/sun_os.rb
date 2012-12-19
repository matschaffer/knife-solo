module KnifeSolo::Bootstraps
  class SunOS < Base
    def bootstrap!
      # FIXME: Doesn't work on https, need to install verisign's CA
      stream_command "curl -L http://opscode.com/chef/install.sh | bash"
    end
  end
end
