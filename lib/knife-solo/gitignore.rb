module KnifeSolo
  class Gitignore
    include Enumerable

    attr_accessor :ignore_file

    def initialize(dir)
      @ignore_file = File.join(dir, '.gitignore')
    end

    def each
      if File.exist? ignore_file
        File.new(ignore_file).each do |line|
          yield line.chomp
        end
      end
    end

    def add(*new_entries)
      new_entries = (entries + new_entries.flatten).uniq
      File.open(ignore_file, 'w') do |f|
        f.puts new_entries
      end
    end
  end
end
