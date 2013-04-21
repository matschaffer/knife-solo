module KnifeSolo
  module DeprecatedCommand

    def self.included(other)
      other.class_eval do
        def self.deprecated
          "`knife #{common_name}` is deprecated! Please use:\n  #{superclass.banner}"
        end

        banner deprecated
        self.options = superclass.options
      end
    end

    def run
      ui.warn self.class.deprecated
      super
    end
  end
end
