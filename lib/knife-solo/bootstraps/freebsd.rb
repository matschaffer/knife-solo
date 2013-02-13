module KnifeSolo::Bootstraps
  class FreeBSD < Base
    def issue
      run_command("uname -sr").stdout.strip
    end

    def gem_packages
      ['chef']
    end

    def prepare_make_conf
      ui.msg "Preparing make.conf"
      run_command <<-EOF
        echo 'RUBY_DEFAULT_VER=1.9' >> /etc/make.conf
      EOF
    end

    def freebsd_port_install
      ui.msg "Updating ports tree..."

      if Dir["/usr/ports/*"].empty?
        run_command("portsnap fetch extract")
      else
        run_command("portsnap update")
      end

      prepare_make_conf

      ui.msg "Installing required ports..."
      packages = %w(net/rsync ftp/curl lang/ruby19 devel/ruby-gems
                    converters/ruby-iconv devel/rubygem-rake
                    shells/bash)

      packages.each do |p|
        ui.msg "Installing #{p}..."
        result = run_command <<-SH
          cd /usr/ports/#{p} && make -DBATCH -DFORCE_PKG_REGISTER install clean
        SH
        raise "Couldn't install #{p} from ports." unless result.success?
      end

      ui.msg "...done installing ports."

      gem_install # chef
    end

    def distro
      return @distro if @distro
      case issue
      when %r{FreeBSD 9\.[01]}
        {:type => 'freebsd_port'}
      else
        raise "#{issue} not supported"
      end
    end
  end
end
