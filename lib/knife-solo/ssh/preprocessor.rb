module KnifeSolo
  module SSH
    class Preprocessor < Struct.new(:connection, :analyzer)
      attr_accessor :prefix

      def run(command)
        command = process_sudo(command)
        command = prefix + command if prefix
        connection.run(command)
      end

      private

      def process_sudo(command)
        if analyzer.sudo?
          connection.sudo_prompt = 'knife-solo sudo password: '
          command.gsub(/\bsudo\b/, "sudo -p '#{connection.sudo_prompt}'")
        else
          command.gsub(/\bsudo\b/, '').lstrip
        end
      end
    end
  end
end
