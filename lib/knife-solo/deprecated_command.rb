module KnifeSolo
  module DeprecatedCommand

    def self.included(other)
      other.class_eval do
        def self.deprecated
          "`knife #{common_name}` is deprecated! Please use:\n  #{superclass.banner}"
        end

        banner deprecated
        self.options = superclass.options

        def self.load_deps
          superclass.load_deps
        end
      end
    end

    def run
      ui.warn self.class.deprecated
      super
    end
  end
end
