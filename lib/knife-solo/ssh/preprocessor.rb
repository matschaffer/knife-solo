module KnifeSolo
  module SSH
    class Preprocessor < Struct.new(:connection, :analyzer)
      attr_accessor :prefix

      def run(command)
        command = command.gsub(/\bsudo\b/, '').lstrip unless analyzer.sudo?
        command = prefix + command if prefix
        connection.run(command)
      end
    end
  end
end
