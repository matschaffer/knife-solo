# Tries to bootstrap with apache2 cookbook and
# verifies the "It Works!" page is present.

require $base_dir.join('integration', 'cases', 'apache2_cook')

module Apache2Bootstrap
  include Apache2Cook

  def write_berksfile
    File.open('Berksfile', 'w') do |f|
      f.puts 'source "https://supermarket.chef.io"'
      f.puts "cookbook 'apache2'"
    end
  end

  def test_apache2
    write_berksfile
    assert_subcommand "bootstrap --run-list=recipe[apache2]"
    assert_match default_apache_message, http_response
  end
end
