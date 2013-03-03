module KnifeSolo
  module SSH
    class ExecResult
      attr_accessor :stdout, :stderr, :output, :exit_code

      def initialize
        @stdout = ""
        @stderr = ""
        @output = ""
      end

      def success?
        exit_code == 0
      end
    end
  end
end

