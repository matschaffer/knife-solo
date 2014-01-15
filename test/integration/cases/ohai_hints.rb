# Tries to bootstrap with --hint option and
# verifies ohai hints get written properly.

module OhaiHints
  def prepare_hints(hints)
    hints.map { |name, data|
      if data.nil?
        "--hint #{name}"
      else
        File.open("#{name}.json", "wb") { |f| f.write(data) }
        "--hint #{name}=#{name}.json"
      end
    }.join(' ')
  end

  def check_hints(hints)
    hints.each do |name, data|
      actual = `ssh #{connection_string} cat /etc/chef/ohai/hints/#{name}.json`
      assert_match actual.strip, data.nil? ? '{}' : data
    end
  end

  def test_ohai_hints
    hints = {
      'test_hint_1' => '{"foo":"bar"}',
      'test_hint_2' => nil
    }

    hint_opts = prepare_hints(hints)
    assert_subcommand "bootstrap #{hint_opts}" 
    check_hints(hints)
  end
end
