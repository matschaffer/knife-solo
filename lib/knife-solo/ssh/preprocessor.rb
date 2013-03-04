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
          custom_prompt = 'knife-solo sudo password: '
          connection.sudo_prompt = custom_prompt
          command.gsub(/\bsudo\b/, "sudo -p '#{custom_prompt}'")
        else
          command.gsub(/\bsudo\b/, '').lstrip
        end
      end
    end
  end
end
