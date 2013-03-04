module KnifeSolo
  module SSH
    class Analyzer < Struct.new(:connection)
      def sudo?
        return @sudo unless @sudo.nil?
        @sudo = connection.run('sudo -V').success?
      end

      def windows?
        return @windows unless @windows.nil?
        @windows = connection.run('ver').success?
      end
    end
  end
end
